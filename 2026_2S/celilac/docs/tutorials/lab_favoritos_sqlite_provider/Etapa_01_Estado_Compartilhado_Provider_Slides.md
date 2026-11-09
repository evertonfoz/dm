# Etapa 1 — Estado Compartilhado em Memória com `ChangeNotifier` e `Provider`
## Do Estado Local Isolado à Sincronização Reativa entre Múltiplas Telas

> **Instrução para o Gamma:** Cada seção separada por `---` corresponde a um slide. O foco está na progressão **Problema → Dor Arquitetural → Fundamentação → Como Resolver**, utilizando diagramas visuais, tabelas comparativas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 1: Estado Compartilhado em Memória com `ChangeNotifier` e `Provider`
**Como sincronizar múltiplas telas e abas em tempo real sem acoplar construtores**

- **Contexto:** Laboratório Sequencial CeliLac (Etapa 1 de 7)
- **Foco da aula:**
  1. Sentir a dor do estado local isolado (`StatefulWidget`)
  2. Fundamentar o Padrão *Observer* (`ChangeNotifier` e `notifyListeners`)
  3. Combinar `List` (ordem) + `Set` (busca em $O(1)$)
  4. Injetar e consumir estado na árvore com `ChangeNotifierProvider`, `watch` e `read`

---

## Slide 2 — O Problema de Produto: Um Único Fato em 3 Lugares Diferentes

### O que o usuário espera ao favoritar um estabelecimento?

Imagine que o usuário encontrou o **Café Aconchego** e tocou no coração para salvá-lo. Essa única decisão precisa aparecer simultaneamente em **3 lugares distintos do app**:

1. **Na Aba Início (`HomePage`):** o coração do cartão na listagem precisa ficar preenchido.
2. **Na Tela de Detalhes (`EstablishmentDetailsPage`):** ao abrir o cartão em uma nova rota, o coração lá no topo (`AppBar`) já deve estar preenchido — e se for desmarcado lá dentro, o cartão da lista precisa saber imediatamente.
3. **Na Aba Favoritos (`FavoritesPage`):** o estabelecimento deve aparecer instantaneamente no topo da lista de lugares salvos.

---

## Slide 3 — A Tentativa Ingênua (E a Dor Provocada ao Vivo)

### O que acontece quando tentamos resolver com `StatefulWidget` local?

A primeira intuição de quem aprendeu `StatefulWidget` é colocar um booleano dentro do cartão e outro dentro da tela de detalhes:

```dart
class _EstablishmentCardState extends State<EstablishmentCard> {
  bool _isFavorite = false; // 🔒 Preso dentro deste cartão!
  // ...
}
```

### Os 3 cliques que quebram o aplicativo na prática:
- **Clique 1:** Você favorita o **Café Aconchego** no cartão da Home (coração fica vermelho).
- **Clique 2:** Você abre a **Tela de Detalhes** do mesmo Café → **o coração na AppBar está vazio!** As duas telas estão mentindo uma para a outra.
- **Clique 3:** Você abre a **Aba Favoritos** → **ela está cega!** Não tem de onde ler quais cartões foram marcados na outra aba.

---

## Slide 4 — Diagnóstico da Dor: Violação da Fonte Única da Verdade

### Por que as telas ficaram dessincronizadas?

Porque violamos o princípio de **Fonte Única da Verdade (*Single Source of Truth* — SSOT)**: criamos variáveis mutáveis separadas para representar o mesmo fato do mundo real.

```text
❌ COM ESTADO LOCAL DUPLICADO (Memória Fragmentada):
┌────────────────────────────┐     ┌───────────────────────────────────┐
│ _EstablishmentCardState    │     │ _EstablishmentDetailsPageState    │
│ bool _isFavorite = true    │ ⚡  │ bool _isFavorite = false          │
└────────────────────────────┘     └───────────────────────────────────┘
(Inconsistência inevitável: cada tela tem a sua própria "verdade")

✅ COM FONTE ÚNICA DA VERDADE (Estado Centralizado):
               ┌─────────────────────────────────┐
               │      FavoritesController        │
               │   (Guarda os favoritos reais)   │
               └───────┬─────────┬─────────┬─────┘
                       ▼         ▼         ▼
                    HomePage  Detalhes  FavoritesPage
               (Todas as telas leem e alteram o mesmo lugar)
```

---

## Slide 5 — As Opções: Como Compartilhar essa Fonte Única?

### Se o estado não pode morar no cartão, para onde ele vai?

| Abordagem | Como funciona | Qual é a dor / limite? |
|---|---|---|
| **Opção A: Estado Local (`StatefulWidget` em cada tela)** | Cada widget controla seu próprio `bool _isFavorite`. | **Não sincroniza** entre telas nem abastece a aba de Favoritos. |
| **Opção B: Subir o estado e repassar por construtores (*Prop Drilling*)** | Guarda a lista no `AppShell` e passa `favorites` e `onToggle` por todos os construtores até o cartão e a rota de detalhes. | **Polui componentes intermediários** que não usam o dado e cria forte acoplamento estrutural. |
| **Opção C: Controlador Reativo + Injeção na Árvore (`ChangeNotifier` + `Provider`)** | Um controlador central notifica ouvintes; qualquer tela acessa direto pelo `BuildContext`. | **Nossa escolha:** zero *prop drilling*, baixo acoplamento e atualização automática. |

---

## Slide 6 — Então o `StatefulWidget` Morreu? (Efêmero vs. Compartilhado)

### Nem todo estado deve ir para o `Provider`!

A engenharia do Flutter divide o estado da interface ($\text{UI} = f(\text{Estado})$) em duas categorias:

| Categoria | Definição | Exemplo no nosso projeto | Ferramenta certa |
|---|---|---|---|
| **Estado Efêmero (Local)** | Interessa a **um único widget** e nenhuma outra tela precisa saber dele. | Qual aba está selecionada (`int _selectedIndex = 0`) na barra inferior do `AppShell`. | **`StatefulWidget` + `setState`** (continua sendo a melhor escolha!). |
| **Estado Compartilhado (*App State*)** | Precisa ser lido ou modificado por **múltiplas telas ou abas** distantes. | Coleção de estabelecimentos favoritos. | **`ChangeNotifier` + `Provider`**. |

> **Detalhe importante no `AppShell`:** usamos `IndexedStack(index: _selectedIndex, ...)` para manter a `HomePage` e a `FavoritesPage` **vivas ao mesmo tempo na memória**, preservando a posição de rolagem ao trocar de aba.

---

## Slide 7 — Organizando a Casa: Arquitetura *Feature-First* em Camadas

### Antes de escrever a solução, onde cada arquivo deve morar?

Em vez de misturar tudo em `main.dart`, separamos o projeto por **funcionalidade (*features*)** e em **3 camadas internas**:

```text
lib/
├── app/                         ← Casca global (LabApp e AppShell)
└── features/
    ├── establishments/
    │   ├── domain/entities/     ← Regras e entidades puras (Establishment)
    │   ├── data/                ← Fonte de dados (sample_establishments)
    │   └── presentation/        ← Widgets (Card, Button) e Pages (Details)
    ├── home/presentation/       ← Aba 0 (HomePage)
    └── favorites/presentation/  ← Controlador (FavoritesController) e Aba 1
```

- **`domain/`:** puro Dart (não importa `flutter/material.dart`).
- **`data/`:** de onde os dados vêm (hoje memória; na Etapa 3, SQLite).
- **`presentation/`:** o que o usuário vê e interage.

---

## Slide 8 — A Fundamentação da Solução: O Padrão *Observer* (GoF)

### Como avisar 3 telas ao mesmo tempo sem que o controlador conheça nenhuma delas?

Usamos o clássico **Padrão de Projeto Comportamental *Observer*** (*Gang of Four*, 1994), que estabelece uma relação **1 para N (`1:N`)** desacoplada:

```text
┌────────────────────────────────────┐           ┌──────────────────────────────────┐
│      Subject (Observable)          │           │      Observers (Listeners)       │
│      FavoritesController           │           │  HomePage, Details, FavoritesPage│
├────────────────────────────────────┤           ├──────────────────────────────────┤
│ - _listeners: List<VoidCallback>   │──────────►│ Quando avisados, marcam seu      │
│ + addListener(callback)            │  notifica │ próprio Element como "dirty"     │
│ + removeListener(callback)         │   1 : N   │ para reconstruir no próximo      │
│ + notifyListeners()                │           │ frame da tela!                   │
└────────────────────────────────────┘           └──────────────────────────────────┘
```

- **O segredo do desacoplamento:** O `FavoritesController` não importa `HomePage` nem `FavoritesPage`. Ele apenas dispara um "sinal de rádio" (`notifyListeners()`), e quem estiver sintonizado se atualiza sozinho!

---

## Slide 9 — Por Dentro do Flutter: `ChangeNotifier`, `notifyListeners()` e `dispose()`

### O que acontece nos bastidores do SDK do Flutter?

Quando fazemos `class FavoritesController extends ChangeNotifier`:

1. **`Listenable` e `ChangeNotifier`:** o controlador herda uma lista interna de funções (`VoidCallback`) onde os widgets interessados se inscrevem.
2. **O que `notifyListeners()` faz de verdade?**
   - Percorre a lista de inscritos e chama internamente `element.markNeedsBuild()`.
   - **Não reconstrói na mesma linha!** Ele apenas marca o widget como *"sujo" (`dirty`)* para que o Flutter reconstrua tudo de uma só vez no próximo *frame* de vídeo (60 Hz / 120 Hz).
3. **Por que existe o `dispose()`?**
   - Limpa a lista de inscritos quando o controlador sai de uso, evitando **vazamento de memória (*memory leak*)** por referências presas a widgets que já morreram.

---

## Slide 10 — O Problema de Estrutura de Dados no Controlador: `List` vs. `Set`

### A Dor: Precisamos de Ordem na Aba Favoritos, mas de Velocidade nos Cartões!

A interface faz **duas perguntas opostas** ao `FavoritesController`:

| Pergunta da UI | Onde acontece | Se usássemos só `List` | Como resolvemos (`List` + `Set`) |
|---|---|---|---|
| *"Quais são todos os favoritos, do mais recente ao mais antigo?"* | 1 vez na `FavoritesPage` | Mantém a ordem posicional | **`List<Establishment> _favorites`** (novo item entra no índice `0`) |
| *"O estabelecimento de `id` `'1'` é favorito?"* (`isFavorite(id)`) | **Em cada cartão visível** a cada `build` da `HomePage` | Busca linear **$O(N)$** varrendo item a item ($O(M \times N)$ na tela!) | **`Set<String> _favoriteIds`** (Tabela *Hash* responde em tempo constante **$O(1)$**!) |

```dart
class FavoritesController extends ChangeNotifier {
  List<Establishment> _favorites = const []; // Preserva a ordem (mais recente no topo)
  Set<String> _favoriteIds = const {};       // Responde isFavorite(id) em O(1)

  List<Establishment> get favorites => _favorites; // Protegida por List.unmodifiable
  bool isFavorite(String id) => _favoriteIds.contains(id);
```

> **Por que usar `List.unmodifiable` ao atualizar `_favorites`?** Para impedir que uma tela externa faça `controller.favorites.clear()` sem atualizar o `Set` e sem chamar `notifyListeners()`!

---

## Slide 11 — Como Entregar o Controlador na Árvore? O Papel do `Provider`

### Como as telas encontram o `FavoritesController` sem *Prop Drilling*?

- No Flutter, o `BuildContext context` de cada widget é o próprio **`Element`** daquele widget na árvore ativa.
- O `ChangeNotifierProvider` coloca o controlador em um `InheritedWidget` no topo da árvore, permitindo que qualquer descendente o localize em **tempo constante $O(1)$**:

```dart
return ChangeNotifierProvider<FavoritesController>(
  create: (_) => FavoritesController(),
  child: MaterialApp(
    home: const AppShell(),
  ),
);
```

**O que ganhamos com essas 4 linhas?**
1. **Criação sob demanda (*Lazy*):** só instancia quando a primeira tela pedir.
2. **Descarte automático:** chama `controller.dispose()` sozinho quando sai da árvore (o `LabApp` continua sendo um simples `StatelessWidget`).

---

## Slide 12 — A Armadilha do `Navigator.push`: Onde Posicionar o Provider?

### "Por que o `ChangeNotifierProvider` precisa ficar ACIMA do `MaterialApp`?"

Veja o que acontece na árvore real do Flutter quando o usuário toca em um cartão e fazemos `Navigator.push`:

```text
LabApp
 └── ChangeNotifierProvider<FavoritesController>   ← ✅ Ancestral de TUDO!
      └── MaterialApp
           └── Navigator (gerencia a pilha de telas)
                ├── Rota 0: AppShell (HomePage e FavoritesPage)
                └── Rota 1 (aberta pelo push): EstablishmentDetailsPage
```

- **O erro clássico:** Embora o `Navigator.push` seja chamado dentro do `EstablishmentCard`, a nova tela (`EstablishmentDetailsPage`) **NÃO é filha da `HomePage`!** Ela é inserida como filha direta do **`Navigator`** (que mora no `MaterialApp`).
- Se o `Provider` ficasse dentro da `HomePage`, a tela de detalhes subiria pela árvore até o `MaterialApp` sem encontrá-lo e quebraria com `ProviderNotFoundException`!

---

## Slide 13 — A Regra de Ouro do `Provider`: `context.watch` vs. `context.read`

### Quando assinar reconstruções e quando apenas disparar uma ação?

| Comando | Onde usar | O que faz na árvore | E se eu usar no lugar errado? |
|---|---|---|---|
| **`context.watch<T>()`** | **Exclusivamente dentro do `build`** | Lê o controlador **e inscreve** o widget para reconstruir quando `notifyListeners()` rodar. | Usar `watch` dentro de um `onPressed` lança **erro imediato** (um clique ocorre fora da construção de *frame*). |
| **`context.read<T>()`** | **Em cliques e ações** (`onPressed`, `onTap`, `initState`) | Apenas busca o controlador em $O(1)$ **sem inscrever** o widget. | Usar `read` no `build` deixa a tela **"congelada"**, pois o widget não será avisado quando o estado mudar. |

```dart
@override
Widget build(BuildContext context) {
  final isFav = context.watch<FavoritesController>().isFavorite(item.id); // 👀 Assina no build
  return FavoriteButton(
    isFavorite: isFav,
    onPressed: () => context.read<FavoritesController>().toggle(item),    // ⚡ Age no clique
  );
}
```

---

## Slide 14 — Desacoplamento Visual: Cartão "Burro" e Páginas Orquestradoras

### Por que o `EstablishmentCard` vira `StatelessWidget` e NÃO importa o `provider`?

Para manter a funcionalidade `establishments` independente da funcionalidade `favorites`:

```text
HomePage / FavoritesPage (Orquestradoras)
  ├── Fazem context.watch<FavoritesController>()
  └── Entregam prontos pelo construtor:
        ├── isFavorite: bool
        └── onFavoriteToggle: VoidCallback
              ▼
EstablishmentCard (StatelessWidget Puro)
  └── Usa o FavoriteButton (com tooltip acessível: "Salvar Café Aconchego nos favoritos")
```

- **Resultado:** O `EstablishmentCard` não sabe de onde vem o booleano nem o que acontece no clique. Ele fica 100% reutilizável tanto na `HomePage` quanto na `FavoritesPage`!

---

## Slide 15 — Fechamento da Etapa 1 e Provocação para a Etapa 2

### O que conquistamos hoje vs. O que acontece ao fechar o aplicativo?

**✅ O que já funciona perfeitamente:**
1. Favoritar no cartão da **Home** atualiza a **Aba Favoritos** na hora.
2. Abrir a **Tela de Detalhes** já mostra o coração sincronizado na `AppBar`.
3. Desfavoritar no **Detalhe** ou na **Aba Favoritos** atualiza todas as telas instantaneamente.

**⚠️ O Experimento Final da Aula (A Nova Dor):**
- Favorite 2 estabelecimentos e faça um **Hot Restart** (ou feche e reabra o app).
- **O que aconteceu?** Todos os favoritos sumiram!
- **Por quê?** Porque nosso `FavoritesController` guarda os dados apenas na **memória RAM**.
- **Próximo passo (Etapa 2):** Como salvar esses favoritos no disco sem sujar o `FavoritesController` com código de banco de dados? → **Contrato `FavoritesRepository` (`domain`) e fluxo assíncrono (`Future`)!**

