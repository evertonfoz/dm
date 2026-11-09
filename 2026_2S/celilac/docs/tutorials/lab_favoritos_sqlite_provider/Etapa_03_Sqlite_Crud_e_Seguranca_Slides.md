# Etapa 3 — Persistência Relacional com SQLite (`sqflite`), Tabela v1 e CRUD Seguro
## Do Armazenamento Volátil em Memória ao Banco de Dados Relacional no Disco

> **Instrução para o Gamma:** Cada seção separada por `---` corresponde a um slide. O foco está na progressão **Problema → Dor Arquitetural → Fundamentação → Como Resolver**, utilizando diagramas visuais, tabelas comparativas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 3: Persistência Relacional com SQLite (`sqflite`), Tabela v1 e CRUD Seguro
**Como persistir coleções no disco do dispositivo com alta performance e imunidade a SQL Injection**

- **Contexto:** Laboratório Sequencial CeliLac (Etapa 3 de 7)
- **Foco da aula:**
  1. Sentir a dor da perda de dados ao fechar o app e o gargalo do `SharedPreferences` para listas
  2. Compreender a arquitetura do SQLite embutido e o ciclo de vida da conexão (`??=`)
  3. Modelar a tabela `v1` como um *snapshot* offline completo
  4. Implementar CRUD seguro com `ConflictAlgorithm.replace` e `whereArgs` (Anti-SQL Injection)
  5. Plugar o repositório SQLite comprovando o Princípio da Inversão de Dependência (DIP)

---

## Slide 2 — O Cenário de Produto: Fechou o App, Cadê os Favoritos?

### O que acontece após a Etapa 2?

Na Etapa 2, criamos o contrato abstrato `FavoritesRepository` e o fluxo assíncrono com feedback de tela e tratamento de erro.

Porém, o aplicativo ainda utiliza o `MemoryFavoritesRepository`:
- Você abre a lista e favorita 5 restaurantes incríveis sem glúten.
- O usuário atende uma ligação, o celular entra em modo de economia ou o app é fechado.
- Ao reabrir o app: **A ABA DE FAVORITOS ESTÁ TOTALMENTE VAZIA!**

> **A Missão:** Precisamos persistir esses dados no disco local do aparelho, de forma definitiva, rápida e segura.

---

## Slide 3 — A Tentativa Ingênua: Por que Não Usar `SharedPreferences`?

### A tentação do desenvolvedor iniciante:

"Já usamos `SharedPreferences` no onboarding e no perfil alimentar. Por que não salvar uma lista de favoritos convertida em JSON?"

```text
CENÁRIO: Salvar o 50º favorito com SharedPreferences
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Ler uma String gigante com 49 JSONs do arquivo XML/plist do disco        │
│ 2. Fazer jsonDecode() criando 49 Maps na memória RAM                        │
│ 3. Converter Maps em 49 objetos Dart                                        │
│ 4. Adicionar o 50º favorito na List                                         │
│ 5. Fazer jsonEncode() da lista inteira gerando outra String gigantesca      │
│ 6. Regravar o arquivo monobloco inteiro no disco do celular!                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### O Custo do SharedPreferences para Coleções:
- **I/O Excessivo:** Ler e regravar 50 itens para alterar apenas um.
- **Sem Ordenação:** Impossível ordenar por data ou filtrar no disco; obriga a carregar tudo na RAM.
- **Risco de Corrupção:** Se a bateria acabar durante a regravação, perde-se a lista inteira!

---

## Slide 4 — Comparativo Técnico: Onde Cada Ferramenta Brilha?

### Critérios de decisão arquitetural para armazenamento local:

| Requisito | `SharedPreferences` | **SQLite (`sqflite`)** | Nuvem (API / Firebase) |
|---|---|---|---|
| **Formato de Dados** | Chave-Valor simples | **Tabelas Relacionais (Linhas/Colunas)** | Documentos / JSON Remoto |
| **Volume Ideal** | Flags e configurações (< 100 KB) | **Coleções estruturadas (MBs)** | Dados compartilhados multiusuário |
| **Custo de Escrita** | Regrava o arquivo todo | **Insere/Deleta apenas 1 linha ($O(1)$)** | Latência de rede + tráfego de dados |
| **Ordenação / Filtro** | Apenas na memória RAM | **No motor em C (`ORDER BY`, `WHERE`)** | No servidor / banco remoto |
| **Disponibilidade** | 100% Offline | **100% Offline e Instantâneo** | Requer conexão com a internet |

> **Conclusão:** Para coleções dinâmicas que precisam ser ordenadas, consultadas e editadas item a item, o **SQLite é a escolha padrão da indústria**.

---

## Slide 5 — Decisão de Modelagem: O que Salvar no Banco?

### Duas abordagens possíveis:

```text
OPÇÃO A: Salvar apenas o ID do estabelecimento
Tabela: [ id | saved_at ]
❌ PROBLEMA: Ao abrir o app sem internet (modo avião), a aba Favoritos só tem IDs!
   Não tem como desenhar o cartão (nome, foto, bairro, nota). O app fica quebrado offline.

OPÇÃO B (Nossa Escolha): Salvar um Instantâneo (Snapshot) do Cartão
Tabela: [ id | name | category | neighborhood | rating | saved_at ]
✅ VANTAGEM: Funciona 100% offline! O usuário visualiza seus locais salvos instantaneamente,
   mesmo dentro do metrô ou sem sinal de celular.
```

---

## Slide 6 — Anatomia do SQLite e Ciclo de Vida da Conexão

### Como o Flutter conversa com o SQLite?

O SQLite é uma biblioteca em linguagem C embutida diretamente no Android e no iOS. Ele armazena o banco inteiro em um único arquivo `.db` na pasta privada do app.

```text
FLUXO DE ABERTURA PREGUIÇOSA (LAZY INITIALIZATION):

  FavoritesRepository.loadAll()
                │
                ▼
      _db (Getter assíncrono)
                │
     ┌──────────┴──────────┐
  Existe?               Não existe?
     │                     │
  Retorna               Abre conexão única:
  _database             _database = await openDatabase(...)
     │                     │
     └──────────┬──────────┘
                ▼
      Executa consulta SQL
```

```dart
// Abertura única e preguiçosa com o operador ??=
Database? _database;
Future<Database> get _db async => _database ??= await _openDatabase();
```

---

## Slide 7 — A Tabela `favorites` (Versão 1 do Esquema)

### Criando a tabela no callback `onCreate`:

```sql
CREATE TABLE favorites (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  neighborhood TEXT NOT NULL,
  rating REAL NOT NULL,
  saved_at INTEGER NOT NULL
)
```

### Por que cada tipo foi escolhido?
- **`id TEXT PRIMARY KEY`:** Identificador único universal (impede registros duplicados).
- **`saved_at INTEGER NOT NULL`:** Timestamp em milissegundos (`DateTime.now().millisecondsSinceEpoch`). Permite ordenação cronológica decrescente ultra-rápida!
- **`rating REAL NOT NULL`:** Ponto flutuante no SQLite para a nota do estabelecimento.

---

## Slide 8 — Operações CRUD: O `INSERT` Idempotente

### Como evitar erros se o usuário tocar no coração repetidas vezes?

Se tentarmos inserir uma chave primária já existente com `db.insert()`, o SQLite lança uma exceção `DatabaseException(UNIQUE constraint failed)`.

```dart
// ✅ Inserção idempotente com ConflictAlgorithm.replace
await db.insert(
  'favorites',
  {
    'id': establishment.id,
    'name': establishment.name,
    'category': establishment.category,
    'neighborhood': establishment.neighborhood,
    'rating': establishment.rating,
    'saved_at': DateTime.now().millisecondsSinceEpoch,
  },
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```

- **`ConflictAlgorithm.replace`:** Se o registro já existir, substitui a linha atualizando os dados e o timestamp de salvamento, sem falhar!

---

## Slide 9 — Operações CRUD: `SELECT` com Ordenação no Motor

### Delegando o trabalho pesado para o motor em C:

Em vez de trazer tudo desordenado e chamar `.sort()` no Dart, o banco já entrega a lista pronta:

```dart
// ✅ Consulta relacional com ordenação cronológica decrescente
final rows = await db.query(
  'favorites',
  orderBy: 'saved_at DESC', // Mais recentes primeiro!
);

return rows.map((row) => Establishment(
  id: row['id'] as String,
  name: row['name'] as String,
  category: row['category'] as String,
  neighborhood: row['neighborhood'] as String,
  rating: (row['rating'] as num).toDouble(),
)).toList();
```

> **Performance:** O SQLite utiliza índices na chave primária e algoritmos de ordenação em C nativo, gastando zero ciclos extras de CPU do Flutter.

---

## Slide 10 — A Ameaça Real: Injeção de SQL (*SQL Injection*)

### Como desenvolvedores novatos abrem brechas críticas:

```dart
// ❌ PÉSSIMA PRÁTICA: Concatenação direta de strings no SQL
await db.rawDelete('DELETE FROM favorites WHERE id = ' + id);
```

### O que acontece se o restaurante se chamar "D'Angelo Bistrô"?
- O apóstrofo quebra a sintaxe do SQL: `'DELETE FROM favorites WHERE id = D'Angelo'`
- O app quebra com erro de sintaxe SQL fatal!

### E em cenários com entrada do usuário?
- Se o ID contiver `1 OR 1=1`, o comando executado torna-se:
  `DELETE FROM favorites WHERE id = 1 OR 1=1;`
- **Resultado:** TODA A TABELA DE FAVORITOS É APAGADA!

---

## Slide 11 — A Solução: Parâmetros `?` e `whereArgs`

### Imunidade total a SQL Injection e quebra de apóstrofos:

```dart
// ✅ OPERAÇÃO BLINDADA: Parâmetros posicionais
await db.delete(
  'favorites',
  where: 'id = ?',
  whereArgs: [id],
);
```

```text
COMO O MOTOR PROCESSA:
1. O comando SQL 'DELETE FROM favorites WHERE id = ?' é pré-compilado na árvore de execução.
2. O argumento [id] é enviado em um canal de dados separado como valor literal puro.
3. Não importa se o id contém aspas, apóstrofos ou comandos SQL: ele NUNCA é interpretado como instrução!
```

- **Regra de Ouro:** Nunca concatene strings em comandos SQL. Use sempre `whereArgs`!

---

## Slide 12 — A Força da Inversão de Dependência (DIP)

### Como trocamos a memória pelo banco de dados no aplicativo?

Graças ao contrato `FavoritesRepository` criado na Etapa 2, basta alterar **uma única linha** na injeção de dependência (`lab_app.dart`):

```dart
// lib/app/lab_app.dart
ChangeNotifierProvider(
  create: (_) => FavoritesController(
    // 🔄 Trocamos MemoryFavoritesRepository por SqliteFavoritesRepository:
    repository: SqliteFavoritesRepository(),
  )..load(),
  child: const MaterialApp(...),
)
```

```text
O QUE PRECISOU SER ALTERADO NAS OUTRAS CAMADAS?
- FavoritesController: ZERO LINHAS ALTERADAS
- HomePage:            ZERO LINHAS ALTERADAS
- FavoritesPage:       ZERO LINHAS ALTERADAS
- EstablishmentCard:   ZERO LINHAS ALTERADAS
```

> **Arquitetura Limpa na Prática:** A interface gráfica desconhece completamente que o SQLite existe!

---

## Slide 13 — Roteiro de Verificação da Persistência

### Como validar com os alunos em sala:

1. **Teste do Hot Restart / Fechar o App:**
   - Abra o app no emulador/celular e favorite 3 estabelecimentos.
   - Abra a aba de Favoritos e verifique a ordem (o último clicado aparece no topo).
   - Feche o aplicativo completamente no gerenciador de tarefas do Android/iOS.
   - Abra o app novamente.
   - **Resultado:** Os favoritos continuam intactos e carregados com perfeição!

2. **Inspecionando o arquivo `.db` no computador:**
   ```bash
   # No Android: inspecione via Device File Explorer do Android Studio
   /data/data/com.example.celilac/databases/celilac_favorites.db
   ```

---

## Slide 14 — Mapeamento com o Projeto CeliLac

### Onde essa infraestrutura vive no aplicativo real?

| Laboratório Sequencial | Projeto CeliLac Real | Responsabilidade |
|---|---|---|
| `favorites_repository.dart` | `features/favorites/domain/repositories/favorites_repository.dart` | Contrato puro da persistência. |
| `sqlite_favorites_repository.dart` | `features/favorites/data/sqlite_favorites_repository.dart` | Implementação com `sqflite`, abertura e CRUD. |
| `lab_app.dart` | `app/celilac_app.dart` | Injeção no topo com `ChangeNotifierProvider`. |

---

## Slide 15 — Resumo e Próximos Degraus

### O que conquistamos na Etapa 3:
- ✅ Eliminação da perda de dados com banco SQLite relacional no disco.
- ✅ *Snapshot* offline permitindo leitura rápida sem conexão à internet.
- ✅ Ordenação `ORDER BY saved_at DESC` no motor nativo em C.
- ✅ Blindagem contra *SQL Injection* e erros de sintaxe com `whereArgs`.

### O Que Falta Resolver? (A Ponte para a Etapa 4):
> "Nesta tabela v1, usamos apenas `String` e `double`. Mas o estabelecimento do CeliLac tem `enum` de categorias, conjunto de opções alimentares `Set<DietaryOption>` e data rica `DateTime`! Como traduzir tipos complexos do Dart para os tipos limitados do SQLite?"
>
> ➡️ **Próxima Aula: Etapa 4 — Tradução de Tipos Ricos Dart ↔ SQLite!**

