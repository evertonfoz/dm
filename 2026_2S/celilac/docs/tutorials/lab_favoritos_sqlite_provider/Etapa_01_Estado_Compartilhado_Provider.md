# Etapa 1 — Estado Compartilhado em Memória com `ChangeNotifier` e `provider`

## Introdução: O que este documento propõe e resolve?

### 1. O Problema Real que Estamos Enfrentando
Em praticamente todo aplicativo móvel moderno — seja um catálogo de estabelecimentos seguros para restritos alimentares (como o **CeliLac**), um e-commerce, um aplicativo de vagas ou um serviço de streaming — existe a funcionalidade de **Favoritos** (ou "Itens Salvos").

Embora pareça um simples botão de coração na tela, essa funcionalidade impõe um desafio arquitetural imediato: **a mesma informação precisa ser lida e modificada por múltiplas telas independentes ao mesmo tempo**:
1. Na **Aba de Início (`HomePage`)**, cada cartão da listagem precisa saber se aquele estabelecimento é favorito para desenhar o coração preenchido ou vazio, além de permitir favoritar diretamente na lista.
2. Na **Tela de Detalhes (`EstablishmentDetailsPage`)** — aberta em uma nova rota empilhada sobre o aplicativo (`Navigator.push`) — a barra superior (`AppBar`) também exibe o coração daquele estabelecimento e permite alterá-lo.
3. Na **Aba de Favoritos (`FavoritesPage`)** — mantida viva em paralelo pelo `IndexedStack` — o aplicativo precisa listar instantaneamente todos os estabelecimentos salvos, do mais recente para o mais antigo, ou exibir um estado vazio orientativo quando nenhum item estiver marcado.

Quando o estudante tenta resolver esse cenário apenas com as ferramentas de estado local que aprendeu nas primeiras aulas (`StatefulWidget` e `setState`), o aplicativo quebra conceitualmente: **cada tela cria sua própria variável booleana isolada na memória**. Marcar o coração na lista não atualiza a tela de detalhes; desmarcar na tela de detalhes não atualiza a lista; e a aba de Favoritos não tem de onde ler os itens selecionados.

### 2. O que esta Etapa 1 Propõe e Resolve
Este documento propõe a transição do **Estado Local Isolado** para uma arquitetura profissional de **Estado Compartilhado Reativo**, resolvendo quatro problemas fundamentais de Engenharia de Software no Flutter:

1. **Organização Arquitetural Escalável (*Feature-First* + Camadas):** Em vez de amontoar todo o código em um único arquivo, estruturamos o projeto desde o início separando a casca global (`app/`) das funcionalidades (`features/establishments`, `features/home`, `features/favorites`) e isolando **Domínio (`domain`)**, **Dados (`data`)** e **Apresentação (`presentation`)**, com cada artefato em seu próprio arquivo.
2. **Fonte Única da Verdade (*Single Source of Truth*) com o Padrão *Observer*:** Eliminamos as variáveis booleanas espalhadas pelas telas e centralizamos a coleção de favoritos em um único controlador (`FavoritesController extends ChangeNotifier`). Quando um item é favoritado ou removido em qualquer lugar do app, o controlador notifica automaticamente todas as telas interessadas (`notifyListeners()`).
3. **Eficiência Algorítmica em Memória (`List` + `Set` em $O(1)$) e Encapsulamento:** Resolvemos o conflito entre precisar de **ordem cronológica** na aba de Favoritos (usando `List<Establishment>` imutável externamente com `List.unmodifiable`) e precisar de **busca instantânea** em cada cartão da listagem (usando um `Set<String>` de IDs com complexidade constante $O(1)$).
4. **Injeção de Dependência na Árvore de Widgets com `provider`:** Resolvemos o problema de como entregar o controlador para diferentes abas e para rotas empilhadas no `Navigator` sem repassar parâmetros por dezenas de construtores (*Prop Drilling*), posicionando o `ChangeNotifierProvider` acima do `MaterialApp` e aplicando a separação estrita entre leitura reativa (`context.watch` no `build`) e disparo de ação (`context.read` em *callbacks*).

### 3. Por que Resolver Primeiro 100% em Memória (Sem Banco de Dados Ainda)?
Misturar, em uma única aula, o aprendizado de `ChangeNotifier`, `provider`, `watch`/`read`, modelagem de tabelas SQL, conversão de tipos e assincronia (`Future`/`async`/`await`) gera sobrecarga cognitiva e dificulta identificar onde está um eventual erro.

Ao construirmos e validarmos a **Etapa 1 funcionando 100% em memória RAM**, o aluno compreende com clareza cristalina como a interface reage às mudanças de estado. Uma vez que a camada de apresentação esteja dominada e sincronizada, a ausência de persistência ao reiniciar o aplicativo ao final desta aula servirá como a motivação perfeita para introduzirmos o contrato `FavoritesRepository` na **Etapa 2** e o banco **SQLite (`sqflite`)** na **Etapa 3**.

---

## Visão Geral do Roteiro de Aula

| Momento | Tempo estimado | O que acontece na aula |
|---|---|---|
| **0. Arquitetura de Pastas e Ponto de Partida** | 15 min | Criamos o projeto-laboratório com separação de pastas e cada artefato em seu próprio arquivo, inicialmente usando estado local (`StatefulWidget`). |
| **1. O Problema (A Dor ao Vivo)** | 10 min | Provocamos na tela a perda de sincronia entre Home, Detalhes e Aba de Favoritos e discutimos a violação da *Fonte Única da Verdade* e o *Prop Drilling*. |
| **2. O Conceito (Fundamentação Teórica e Técnica)** | 25 min | Fundamentamos o Padrão *Observer* (GoF), o funcionamento interno de `Listenable` / `ChangeNotifier` / `notifyListeners()` / `dispose()`, a complexidade $O(1)$ de `Set` + `List`, a anatomia do `Navigator` na árvore de `Element`s e a mecânica interna de `watch` vs. `read`. |
| **3. A Prática (Refatoração Arquivo por Arquivo)** | 25 min | Criamos o `FavoritesController` e o `FavoriteButton` em seus próprios arquivos, injetamos o `ChangeNotifierProvider` em `lab_app.dart` e refatoramos as páginas. |
| **4. Verificação e Ponte com o CeliLac** | 10 min | Validamos os 4 fluxos interativos na tela e mapeamos cada arquivo com o código do **CeliLac**. |

---

## 0. Arquitetura de Pastas e Ponto de Partida

Desde o primeiro minuto de aula, **não colocaremos tudo em um único `main.dart`**. Vamos organizar o projeto-laboratório seguindo a mesma arquitetura profissional do CeliLac: **divisão por funcionalidade (*feature-first*)** combinada com **camadas internas (`domain`, `data`, `presentation`)**, onde **cada classe/artefato possui seu próprio arquivo**.

### 0.1 Fundamentação: Por que arquitetura *Feature-First* + Camadas?

Quando um projeto cresce, organizar pastas apenas pelo "tipo técnico" global (`lib/models/`, `lib/pages/`, `lib/widgets/`, `lib/controllers/`) obriga o desenvolvedor a saltar por quatro diretórios distantes para alterar uma única funcionalidade.

Na abordagem **Feature-First em Camadas**:
1. **`lib/app/`** guarda a casca global da aplicação (configuração do `MaterialApp`, provedores globais e o `AppShell` com a barra de navegação inferior).
2. **`lib/features/<funcionalidade>/`** agrupa tudo o que pertence a um domínio de negócio (`establishments`, `home`, `favorites`).
3. Dentro de cada funcionalidade, separamos as responsabilidades em até três subpastas:
   - **`domain/` (Domínio):** entidades de negócio puras (e, a partir da Etapa 2, contratos de repositórios). Não importa Flutter (`material.dart`) nem pacotes externos.
   - **`data/` (Dados):** fontes de dados concretas (nesta Etapa 1, uma lista em memória; na Etapa 3, o banco SQLite).
   - **`presentation/` (Apresentação):** páginas (`pages/`), componentes visuais reutilizáveis (`widgets/`) e controladores de estado (`ChangeNotifier`).

### 0.2 Árvore de arquivos que teremos ao final desta Etapa 1

```text
lab_favoritos/
├── pubspec.yaml
├── lib/
│   ├── main.dart                                                     ← Ponto de entrada (apenas runApp)
│   ├── app/
│   │   ├── lab_app.dart                                              ← Raiz do app (ChangeNotifierProvider + MaterialApp)
│   │   └── shell/
│   │       └── app_shell.dart                                        ← Casca com IndexedStack e NavigationBar
│   └── features/
│       ├── establishments/
│       │   ├── domain/
│       │   │   └── entities/
│       │   │       └── establishment.dart                            ← Entidade de domínio imutável
│       │   ├── data/
│       │   │   └── sample_establishments.dart                        ← Catálogo inicial em memória
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── establishment_details_page.dart               ← Tela de detalhes (rota empilhada)
│       │       └── widgets/
│       │           ├── establishment_card.dart                       ← Cartão do estabelecimento
│       │           └── favorite_button.dart                          ← (Criado no Passo 3) Botão de coração reutilizável
│       ├── home/
│       │   └── presentation/
│       │       └── pages/
│       │           └── home_page.dart                                ← Aba 0: Listagem de estabelecimentos
│       └── favorites/
│           └── presentation/
│               ├── favorites_controller.dart                         ← (Criado no Passo 3) ChangeNotifier (List + Set)
│               └── pages/
│                   └── favorites_page.dart                           ← Aba 1: Lista de favoritos salvos
```

### 0.3 Criando o projeto no terminal

Execute no terminal:

```bash
flutter create --empty lab_favoritos
cd lab_favoritos
```

---

## 1. O Problema (A Dor Provocada ao Vivo)

Para que o aluno sinta na pele **por que** precisamos de gerenciamento de estado compartilhado, vamos primeiro criar os arquivos iniciais resolvendo o botão de coração com o que o aluno já conhece: um `StatefulWidget` com `bool _isFavorite = false` local em cada tela.

### 1.1 Criando os arquivos do cenário inicial (com estado local)

Abaixo, construímos os 9 arquivos iniciais do nosso projeto. Antes de cada código, há a fundamentação do papel daquele artefato e dos recursos da linguagem Dart e do Flutter utilizados nele.

---

#### Arquivo 1: `lib/features/establishments/domain/entities/establishment.dart`

**O que este arquivo propõe e resolve:**
Propõe o modelo de dados único e padronizado que representa um estabelecimento em todo o aplicativo. Ele resolve o problema de trafegar dados soltos e desestruturados (como mapas `Map<String, dynamic>` ou variáveis separadas `String nome`, `double nota`) entre as telas e o controlador de favoritos, garantindo segurança de tipos (*type safety*) em tempo de compilação.

**Papel Arquitetural (`domain/entities`):**
Este arquivo fica na camada mais interna da funcionalidade de estabelecimentos: o **Domínio (`domain`)**. Uma **Entidade de Domínio** representa um conceito central do mundo real (um estabelecimento seguro para pessoas com restrição alimentar). Repare que este arquivo **não possui nenhum `import`**: ele não conhece `flutter/material.dart`, não conhece banco de dados e não conhece gerenciadores de estado. Isso garante que a regra de negócio seja pura e independente de tecnologia.

**Fundamentação dos recursos utilizados no código:**
- **Imutabilidade (`final` e `const`):** Todos os atributos (`id`, `name`, `category`, `neighborhood`, `rating`) são declarados como `final` — uma vez criado o objeto, seus dados internos jamais mudam acidentalmente no meio da execução.
- **Construtor constante (`const Establishment({...})`):** Como todos os campos são `final`, o construtor pode ser `const`. Isso permite que o compilador do Dart crie instâncias em tempo de compilação (*canonicalização de memória*), economizando memória RAM e acelerando comparações.
- **Parâmetros nomeados obrigatórios (`required this.id`, etc.):** Entre chaves `{...}`, exigem que quem instancia a classe explicite o nome de cada campo (`name: 'Café Aconchego'`), evitando erros de inversão na ordem de parâmetros do mesmo tipo (`String`).

```dart
class Establishment {
  const Establishment({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.rating,
  });

  final String id;
  final String name;
  final String category;
  final String neighborhood;
  final double rating;
}
```

---

#### Arquivo 2: `lib/features/establishments/data/sample_establishments.dart`

**O que este arquivo propõe e resolve:**
Propõe uma coleção inicial de estabelecimentos de exemplo em memória para abastecer o catálogo do aplicativo. Ele resolve a necessidade de termos dados realistas para testar a listagem, a navegação para os detalhes e a ação de favoritar sem depender, neste primeiro momento, de internet ou de um servidor externo.

**Papel Arquitetural (`data`):**
Este arquivo pertence à camada de **Dados (`data`)** da funcionalidade `establishments`. Enquanto não conectamos uma API externa ou um banco de dados para o catálogo, este módulo funciona como nossa fonte de dados inicial. Separá-lo da tela (`HomePage`) respeita o **Princípio da Responsabilidade Única (SRP)**: a tela não deve conter dados "chumbados" (*hardcoded*) misturados com código de layout.

**Fundamentação dos recursos utilizados no código:**
- **Lista constante em tempo de compilação (`const sampleEstablishments = <Establishment>[...]`):** Ao declarar a lista como `const` (o que só é possível porque o construtor de `Establishment` também é `const`), toda a coleção já nasce pronta e imutável na memória. Nenhuma tela consegue adicionar ou remover itens dessa lista original por engano.

```dart
import '../domain/entities/establishment.dart';

const sampleEstablishments = <Establishment>[
  Establishment(
    id: '1',
    name: 'Café Aconchego',
    category: 'Café',
    neighborhood: 'Centro',
    rating: 4.8,
  ),
  Establishment(
    id: '2',
    name: 'Padaria Trigo Zero',
    category: 'Padaria',
    neighborhood: 'Jardim América',
    rating: 4.9,
  ),
  Establishment(
    id: '3',
    name: 'Bistrô Sem Traço',
    category: 'Restaurante',
    neighborhood: 'Bela Vista',
    rating: 4.7,
  ),
];
```

---

#### Arquivo 3: `lib/features/establishments/presentation/widgets/establishment_card.dart` *(Versão inicial com estado local isolado)*

**O que este arquivo propõe e resolve:**
Propõe um componente visual de cartão (`Card` + `ListTile`) para exibir o resumo de um estabelecimento (nome, categoria, bairro, nota e botão de coração) e abrir sua tela de detalhes ao ser tocado. Nesta versão inicial, ele resolve a troca visual do ícone de coração usando um estado local (`bool _isFavorite`), servindo como **experimento didático** para demonstrar por que guardar estado compartilhado dentro de um widget de item de lista falha ao navegar entre telas.

**Papel Arquitetural (`presentation/widgets`):**
Fica na subpasta `widgets/` da camada de **Apresentação (`presentation`)**, pois não é uma tela inteira (não tem `Scaffold` nem `AppBar`), mas sim uma **peça visual reutilizável** que representa um item da lista.

**Por que começamos com `StatefulWidget` aqui (e qual é a armadilha)?**
Quando o estudante aprende Flutter básico, a primeira reação para fazer um botão mudar de ícone ao ser clicado é transformar o componente em um `StatefulWidget` e guardar um `bool _isFavorite = false` dentro da classe `State`.
- **Como funciona aqui:** Ao clicar no `IconButton`, chamamos `setState(() { _isFavorite = !_isFavorite; })`, o que reconstrói **apenas aquele cartão específico**.
- **Onde está o erro arquitetural que provocaremos em aula:** Cada instância de `EstablishmentCard` na tela cria seu próprio objeto `_EstablishmentCardState` isolado na memória. Nenhuma outra tela do aplicativo tem acesso a essa variável privada `_isFavorite`!
- **Navegação Imperativa (`Navigator.of(context).push`):** No `onTap` do `ListTile`, empilhamos a tela de detalhes usando `MaterialPageRoute`, passando o objeto `Establishment` selecionado pelo construtor.

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';
import '../pages/establishment_details_page.dart';

/// PROBLEMA DIDÁTICO AQUI: cada cartão guarda seu próprio `_isFavorite` local!
class EstablishmentCard extends StatefulWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
  });

  final Establishment establishment;

  @override
  State<EstablishmentCard> createState() => _EstablishmentCardState();
}

class _EstablishmentCardState extends State<EstablishmentCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.establishment;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${item.category} · ${item.neighborhood} · ★ ${item.rating}'),
        trailing: IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          color: _isFavorite ? Colors.red.shade700 : null,
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EstablishmentDetailsPage(establishment: item),
            ),
          );
        },
      ),
    );
  }
}
```

---

#### Arquivo 4: `lib/features/establishments/presentation/pages/establishment_details_page.dart` *(Versão inicial com estado local isolado)*

**O que este arquivo propõe e resolve:**
Propõe a tela de detalhes de um estabelecimento específico, exibida quando o usuário toca em um cartão, contendo um botão de coração na barra superior (`AppBar`). Nesta versão inicial com `StatefulWidget`, ela evidencia o problema clássico da **duplicação de estado**: por manter seu próprio `bool _isFavorite` isolado do cartão da listagem, ela ignora o que foi marcado na tela anterior.

**Papel Arquitetural (`presentation/pages`):**
Fica em `pages/` porque representa uma **tela completa** (possui `Scaffold` e `AppBar`), aberta quando o usuário toca em um cartão na listagem ou nos favoritos.

**Fundamentação dos recursos utilizados e do problema demonstrado:**
- **Acesso aos dados do Widget pai (`widget.establishment`):** Em um `StatefulWidget`, os parâmetros imutáveis ficam na classe `EstablishmentDetailsPage`, e a classe de estado (`_EstablishmentDetailsPageState`) os acessa através da propriedade `widget`.
- **Ações na barra superior (`AppBar.actions`):** Colocamos um `IconButton` à direita do título na `AppBar` para permitir favoritar ou desfavoritar diretamente na tela de detalhes.
- **O problema da duplicação de estado:** Repare que `_EstablishmentDetailsPageState` declara **outro** `bool _isFavorite = false;`. Quando esta página abre, `_isFavorite` sempre começa como `false`, ignorando completamente se o usuário já havia marcado o coração lá no `EstablishmentCard`!

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';

/// PROBLEMA DIDÁTICO AQUI TAMBÉM: a tela de detalhes tem outro `_isFavorite`!
class EstablishmentDetailsPage extends StatefulWidget {
  const EstablishmentDetailsPage({
    super.key,
    required this.establishment,
  });

  final Establishment establishment;

  @override
  State<EstablishmentDetailsPage> createState() =>
      _EstablishmentDetailsPageState();
}

class _EstablishmentDetailsPageState extends State<EstablishmentDetailsPage> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.establishment;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red.shade700 : null,
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('${item.category} · ${item.neighborhood}'),
              const SizedBox(height: 4),
              Text('Nota: ★ ${item.rating}'),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

#### Arquivo 5: `lib/features/home/presentation/pages/home_page.dart` *(Versão inicial)*

**O que este arquivo propõe e resolve:**
Propõe a tela principal de listagem do aplicativo (aba **Início**), resolvendo a exibição rolável de todos os estabelecimentos do catálogo através de uma lista construída sob demanda (`ListView.builder`).

**Papel Arquitetural (`features/home/presentation/pages`):**
Representa a primeira aba do aplicativo (**Início**), responsável por exibir o catálogo de estabelecimentos disponíveis.

**Fundamentação dos recursos utilizados no código:**
- **`StatelessWidget`:** Nesta versão inicial, a `HomePage` apenas monta a estrutura da página (`Scaffold` + `AppBar` + `ListView.builder`).
- **Renderização sob demanda com `ListView.builder`:** Em vez de criar todos os cartões de uma vez na memória (como faria um `ListView(children: [...])`), o construtor `.builder` recebe `itemCount` e a função `itemBuilder(context, index)`. O Flutter executa essa função **apenas para os itens que cabem na tela visível** à medida que o usuário rola a página, garantindo alta performance mesmo se a lista crescer para milhares de estabelecimentos.

```dart
import 'package:flutter/material.dart';

import '../../../establishments/data/sample_establishments.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimentos')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sampleEstablishments.length,
        itemBuilder: (context, index) {
          return EstablishmentCard(
            establishment: sampleEstablishments[index],
          );
        },
      ),
    );
  }
}
```

---

#### Arquivo 6: `lib/features/favorites/presentation/pages/favorites_page.dart` *(Versão inicial)*

**O que este arquivo propõe e resolve:**
Propõe a tela exclusiva para consulta rápida dos lugares salvos pelo usuário (aba **Favoritos**). Nesta versão inicial, ela expõe visualmente o bloqueio arquitetural do estado local: como os booleanos `_isFavorite` estão presos dentro de cada `EstablishmentCard`, esta aba ainda não consegue saber quais estabelecimentos devem ser listados aqui.

**Papel Arquitetural (`features/favorites/presentation/pages`):**
Representa a segunda aba da barra inferior (**Favoritos**), onde o usuário espera encontrar todos os estabelecimentos que marcou com o coração.

**Fundamentação dos recursos utilizados no código:**
- **Callback opcional de navegação (`final VoidCallback? onExploreTap`):** Recebe do `AppShell` uma função sem argumentos (`void Function()`) para que, quando a lista estiver vazia, um botão possa levar o usuário de volta para a aba **Início** sem que a `FavoritesPage` precise conhecer a implementação interna do `AppShell`.
- **A dor visível:** Nesta versão inicial sem estado compartilhado, a página está "cega": ela não tem de onde ler quais cartões foram favoritados lá na `HomePage` ou na `EstablishmentDetailsPage`.

```dart
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Como listar aqui os estabelecimentos favoritados na outra aba?',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
```

---

#### Arquivo 7: `lib/app/shell/app_shell.dart`

**O que este arquivo propõe e resolve:**
Propõe a estrutura de navegação por abas na parte inferior da tela (`NavigationBar`), resolvendo a alternância instantânea entre a aba **Início** (`HomePage`) e a aba **Favoritos** (`FavoritesPage`) sem destruir o estado nem perder a posição de rolagem de cada aba graças ao `IndexedStack`.

**Papel Arquitetural (`app/shell`):**
O `AppShell` é a "casca" de navegação principal do aplicativo. Ele fica em `lib/app/shell/` porque coordena múltiplas *features* (`HomePage` e `FavoritesPage`) através de uma barra de navegação inferior (`NavigationBar` do Material 3).

**Fundamentação dos recursos utilizados no código:**
- **Exemplo clássico de Estado Efêmero (`int _selectedIndex = 0`):** Qual aba está selecionada no momento interessa **exclusivamente** ao `AppShell`. Por isso, `AppShell` é um `StatefulWidget` e continuará sendo mesmo depois de adicionarmos o `provider`! Isso ensina ao aluno que `provider` não substitui todo `StatefulWidget` — estados puramente locais de UI continuam usando `setState`.
- **Preservação de estado das abas com `IndexedStack`:** Se trocássemos o `body` usando `body: _selectedIndex == 0 ? HomePage() : FavoritesPage()`, toda vez que o usuário mudasse de aba o Flutter **destruiria** a aba anterior e a recriaria do zero ao voltar (perdendo a posição de rolagem da lista). O `IndexedStack` mantém **todas as abas filhas montadas e vivas simultaneamente na árvore**, exibindo apenas a filha correspondente ao `index: _selectedIndex`.

```dart
import 'package:flutter/material.dart';

import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomePage(),
          FavoritesPage(
            onExploreTap: () => setState(() => _selectedIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
```

---

#### Arquivo 8: `lib/app/lab_app.dart` *(Versão inicial)*

**O que este arquivo propõe e resolve:**
Propõe o componente raiz de configuração global do aplicativo (`MaterialApp`), resolvendo em um único lugar a definição do tema visual Material 3, do navegador de rotas (`Navigator`) e da tela inicial (`AppShell`).

**Papel Arquitetural (`app/lab_app.dart`):**
É o widget raiz que configura o aplicativo como um todo: tema visual (`ThemeData`), título, remoção da faixa de *debug* e definição da tela inicial (`home: const AppShell()`). Também será aqui, no topo da árvore de widgets, que registraremos nossos estados globais compartilhados no Passo 3.

**Fundamentação dos recursos utilizados no código:**
- **`MaterialApp`:** Cria internamente o `Navigator` principal do aplicativo (que gerencia a pilha de telas abertas com `push`/`pop`), além de fornecer o `Theme` e o `MediaQuery` para todos os widgets filhos.
- **`ColorScheme.fromSeed` (`colorSchemeSeed: Colors.indigo`):** Gera automaticamente uma paleta harmônica completa no padrão Material 3 a partir de uma cor semente.

```dart
import 'package:flutter/material.dart';

import 'shell/app_shell.dart';

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab Favoritos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
```

---

#### Arquivo 9: `lib/main.dart`

**O que este arquivo propõe e resolve:**
Propõe um ponto de partida mínimo e limpo para a execução do sistema operacional (`void main()`), resolvendo a inicialização da árvore de widgets do Flutter (`runApp`) sem misturar configurações de tema, rotas ou telas dentro do arquivo de inicialização.

**Papel Arquitetural (`lib/main.dart`):**
É a porta de entrada (*entrypoint*) exigida pelo compilador do Dart (`void main()`). Em uma arquitetura limpa, o `main.dart` deve ser mínimo: sua única responsabilidade é inicializar o motor do Flutter e entregar o widget raiz (`const LabApp()`) para a função `runApp()`.

```dart
import 'package:flutter/material.dart';

import 'app/lab_app.dart';

void main() {
  runApp(const LabApp());
}
```

---

### 1.2 Roteiro para provocar a dor em sala (3 cliques ao vivo)

Rode o aplicativo (`flutter run`) e faça estes 3 passos projetando a tela para os alunos:

1. **Clique 1:** Na aba **Início** (`HomePage`), toque no coração do **Café Aconchego**. O ícone fica vermelho e preenchido.
2. **Clique 2:** Toque no cartão do **Café Aconchego** para abrir a `EstablishmentDetailsPage`.
   - *Pergunta para a turma:* "Por que o coração lá no topo da tela de detalhes está vazio se acabamos de favoritar o Café Aconchego?"
   - Toque no coração da `AppBar` (ele preenche), depois toque de novo (ele esvazia) e volte para a lista: o cartão da `HomePage` continua vermelho! As duas telas estão **mentindo uma para a outra**.
3. **Clique 3:** Mude para a aba **Favoritos** (`FavoritesPage`).
   - *Pergunta para a turma:* "Como a `FavoritesPage` vai desenhar os cartões favoritados se cada `_EstablishmentCardState` trancou um `bool _isFavorite` privado dentro de si?"

---

## 2. O Conceito (Fundamentação Teórica e Técnica)

Esta seção traz toda a fundamentação conceitual de Engenharia de Software e do funcionamento interno do Flutter para você explicar no quadro antes de refatorar o código.

---

### 2.1 A Equação da UI Declarativa, Estado Efêmero vs. Compartilhado e *Single Source of Truth*

No paradigma declarativo do Flutter, a interface visual não é "editada" diretamente (como em `button.setIcon(...)` da programação imperativa antiga). Em vez disso, a interface é uma função matemática do estado atual:

$$\text{UI} = f(\text{Estado})$$

Quando o estado muda, o framework reavalia a função $f$ (o método `build`) e atualiza apenas o que mudou na tela. Mas onde esse **Estado** deve morar?

1. **Estado Efêmero (Ephemeral / Local State):**
   - **Definição:** É o estado contido inteiramente dentro de um único widget e que nenhuma outra parte do aplicativo precisa consultar ou alterar.
   - **Exemplo no nosso projeto:** O índice `_selectedIndex` dentro de `_AppShellState`. Nem o `EstablishmentCard` nem a `EstablishmentDetailsPage` precisam saber qual aba está ativa. Portanto, usar `StatefulWidget` + `setState` em `AppShell` é **tecnicamente correto e recomendado**.
   - **Nota sobre o `IndexedStack`:** No `AppShell`, usamos `IndexedStack(index: _selectedIndex, children: [...])`. Diferentemente de trocar o widget no `body` com um `if/else` (o que destruiria e recriaria a aba a cada troca, perdendo até a posição de rolagem da lista), o `IndexedStack` **mantém todas as abas montadas e vivas na árvore de elementos ao mesmo tempo**, apenas pintando na tela aquela correspondente ao `index` atual.

2. **Estado de Aplicação (App / Shared State) e a *Fonte Única da Verdade* (*Single Source of Truth* — SSOT):**
   - **Definição:** É o estado que precisa ser lido, exibido ou modificado por múltiplos widgets espalhados em ramos diferentes da árvore (ou em rotas diferentes da pilha de navegação).
   - **O que deu errado no nosso código inicial?** Violamos o princípio de **Fonte Única da Verdade (SSOT)**: criamos duas variáveis `bool _isFavorite` independentes para representar o mesmo fato do mundo real (*"O Café Aconchego é favorito?"*). Sempre que o mesmo dado é duplicado em dois estados mutáveis independentes, o sistema inevitavelmente entra em **inconsistência de estado**.

3. **Por que não resolver apenas "subindo o estado" via construtores (*Prop Drilling*)?**
   - Se colocássemos um `Set<Establishment>` dentro de `_AppShellState`, teríamos de passar `favorites` e `onToggleFavorite` pelo construtor de `HomePage` → que repassaria para `EstablishmentCard` → que repassaria pelo `Navigator.push` para `EstablishmentDetailsPage`.
   - Na Engenharia de Software, esse antipadrão é chamado de ***Prop Drilling*** (perfuração de propriedades): componentes intermediários (`HomePage`) ficam poluídos com parâmetros que eles mesmos não utilizam, criando **acoplamento estrutural** entre o topo e as folhas da árvore.

---

### 2.2 O Padrão de Projeto *Observer* (GoF)

Para compartilhar uma Fonte Única da Verdade sem acoplar os componentes intermediários, recorremos a um dos padrões comportamentais mais importantes da Engenharia de Software: o **Padrão *Observer***, catalogado pelo *Gang of Four* (Gamma, Helm, Johnson & Vlissides, *Design Patterns*, 1994).

#### Estrutura Clássica do Padrão *Observer*

O padrão define uma dependência **um-para-muitos (`1:N`)** entre objetos, de modo que, quando um objeto muda de estado, todos os seus dependentes são notificados e atualizados automaticamente:

```text
┌────────────────────────────────────┐           ┌──────────────────────────────────┐
│      Subject (Observable)          │           │      Observer (Listener)         │
│  Ex.: FavoritesController          │           │  Ex.: Element da HomePage,       │
├────────────────────────────────────┤           │       FavoritesPage, DetailsPage │
│ - _listeners: List<VoidCallback>   │──────────►├──────────────────────────────────┤
│ + addListener(callback)            │  notifica │ + VoidCallback (marca o widget   │
│ + removeListener(callback)         │   1 : N   │   como "dirty" para rebuild)     │
│ + notifyListeners()                │           └──────────────────────────────────┘
└────────────────────────────────────┘
```

- **Subject (Sujeito / Observável):** detém a Fonte Única da Verdade e mantém uma lista de referências para observadores abstratos (funções de *callback*). **Crucial:** O *Subject* não conhece quais classes concretas estão ouvindo (`HomePage`? `FavoritesPage`? `EstablishmentDetailsPage`?). Ele apenas sabe que existem funções registradas para serem chamadas quando houver mudança.
- **Observer (Observador / Ouvinte):** qualquer componente interessado que se registra no *Subject* (`addListener`) para ser avisado quando o estado mudar e se desregistra (`removeListener`) quando deixa de existir.

---

### 2.3 Fundamentação do `Listenable`, `ChangeNotifier`, `notifyListeners()` e `dispose()` no Flutter

No SDK do Flutter (`package:flutter/foundation.dart`), o Padrão *Observer* já vem implementado de fábrica através da interface `Listenable` e da classe `ChangeNotifier`:

#### 1. `abstract class Listenable`
É o contrato mínimo do *Subject* no Flutter. Define apenas dois métodos:
- `void addListener(VoidCallback listener)` — registra uma função sem argumentos (`void Function()`) para ser chamada quando o objeto mudar.
- `void removeListener(VoidCallback listener)` — remove o registro daquela função.

#### 2. `class ChangeNotifier implements Listenable`
É a implementação pronta e altamente otimizada de `Listenable` fornecida pelo Flutter. Quando criamos `class FavoritesController extends ChangeNotifier`, nossa classe herda:
- Uma estrutura interna privada que armazena os *callbacks* de todos os ouvintes inscritos.
- O método protegido **`notifyListeners()`**:
  - **O que ele faz exatamente quando é chamado?** Ele percorre o vetor interno de *listeners* inscritos e executa cada `VoidCallback()`.
  - **O que é esse `VoidCallback` quando um Widget está ouvindo?** Quando um widget assina um `ChangeNotifier` (via `InheritedNotifier` ou `provider`), o callback registrado chama internamente `element.markNeedsBuild()`.
  - **Ele reconstrói a tela no mesmo microssegundo da linha `notifyListeners()`?** **Não!** `markNeedsBuild()` apenas marca aquele `Element` específico na árvore como *"sujo" (`dirty`)*. No próximo pulso vertical da tela (*vsync frame*, a 60 Hz ou 120 Hz), o motor do Flutter reconstrói **apenas** os widgets marcados como *dirty*, sem desperdiçar CPU caso `notifyListeners()` tenha sido chamado mais de uma vez no mesmo turno.
- O método **`dispose()`**:
  - **Por que ele existe?** Se um controlador não for mais usado, `dispose()` limpa o vetor interno de *listeners* e marca o `ChangeNotifier` como descartado. Se um widget saísse da árvore sem remover sua inscrição (`removeListener`), o `ChangeNotifier` manteria uma referência de memória apontando para um widget morto, causando **vazamento de memória (*memory leak*)** e erros ao tentar atualizar um elemento desmontado.

---

### 2.4 Fundamentação das Estruturas de Dados do Controlador: `List` + `Set` e Imutabilidade

Dentro do `FavoritesController`, precisamos armazenar os estabelecimentos favoritados. Por que não usar apenas uma `List<Establishment>` ou apenas um `Set<Establishment>`?

#### Análise de Complexidade Algorítmica (*Big-O*)

Observe as duas operações realizadas pela interface:

| Operação na UI | Onde é chamada | Frequência | Estrutura Ideal |
|---|---|---|---|
| **Listar todos os favoritos ordenados do mais recente ao mais antigo** | `FavoritesPage.build` | 1 vez ao desenhar a aba | **`List<Establishment>`** (acesso indexado sequencial) |
| **Verificar se `id` está nos favoritos (`isFavorite(id)`)** | `HomePage.build` (para cada cartão) e `EstablishmentDetailsPage.build` | $M$ vezes (uma para cada cartão visível na rolagem) | **`Set<String>`** (tabela *hash* de busca constante) |

- Se implementássemos `isFavorite(String id)` percorrendo uma `List<Establishment>` com `_favorites.any((e) => e.id == id)`:
  - Para cada cartão, o Dart faria uma **busca linear $O(N)$**, comparando elemento por elemento até o fim da lista.
  - Em uma lista de $M$ cartões na tela com $N$ favoritos, o custo seria **$O(M \times N)$**.
- Ao mantermos em paralelo um **`Set<String> _favoriteIds`**:
  - No Dart, `Set` (`LinkedHashSet`) é implementado sobre uma **Tabela de Dispersão (*Hash Table*)**.
  - Quando chamamos `_favoriteIds.contains(establishmentId)`, o Dart calcula o `hashCode` da `String` e vai direto ao endereço de memória correspondente em **tempo constante $O(1)$**, independentemente de existirem 3 ou 10.000 favoritos!

#### Proteção de Invariantes com `List.unmodifiable`

Por que o *getter* `List<Establishment> get favorites => _favorites;` entrega uma lista criada com `List.unmodifiable(...)`?

- Em Dart, listas comuns são mutáveis. Se `_favorites` fosse uma lista comum e você a devolvesse no *getter*, qualquer widget externo poderia fazer acidentalmente:
  ```dart
  controller.favorites.clear(); // ❌ PERIGO!
  ```
- Isso apagaria os dados internos do controlador **sem atualizar `_favoriteIds`** (quebrando a invariante de sincronia entre a `List` e o `Set`) e **sem chamar `notifyListeners()`** (quebrando o Padrão *Observer*)!
- Ao envolver a lista em **`List.unmodifiable(...)`**, o Dart cria uma `UnmodifiableListView`: qualquer tentativa externa de chamar `.add()`, `.remove()` ou `.clear()` lança imediatamente uma `UnsupportedError`. Assim garantimos o **encapsulamento estrito**: o estado só pode ser alterado através do método `toggle()`.

---

### 2.5 Fundamentação da Árvore do Flutter: `BuildContext`, `InheritedWidget`, `ChangeNotifierProvider` e o `Navigator`

Como o `FavoritesController` chega até o `HomePage`, `FavoritesPage` e `EstablishmentDetailsPage` sem passar pelos construtores?

#### 1. O que é o `BuildContext` e o `InheritedWidget`?
- No Flutter, todo `Widget` é apenas uma configuração leve e imutável (como uma planta baixa). Quando o Flutter monta a tela, ele cria um objeto paralelo chamado **`Element`** para cada widget — é o `Element` que permanece vivo na memória entre os *rebuilds*.
- O parâmetro **`BuildContext context`** que todo método `build` recebe **é o próprio `Element` daquele widget na árvore**!
- O Flutter possui um tipo especial de widget chamado **`InheritedWidget`** (e seu derivado `InheritedNotifier`). Ele permite que qualquer `Element` descendente, não importa quão profundo esteja, consulte dados guardados naquele ancestral em **tempo constante $O(1)$** usando seu `context`.

#### 2. O que o pacote `provider` e o `ChangeNotifierProvider` fazem?
No Material 4 do CeliLac, criamos um `InheritedNotifier` manualmente (`ProfileScope`). O pacote **`provider`** é o padrão oficial recomendado pela equipe do Flutter que encapsula o `InheritedWidget` resolvendo três problemas de engenharia:
1. **Criação preguiçosa (*Lazy Initialization*):** o `ChangeNotifierProvider(create: (_) => FavoritesController(), ...)` só instancia o controlador quando o primeiro widget realmente precisar dele.
2. **Gerenciamento automático de memória (`dispose`):** quando o `ChangeNotifierProvider` é removido da árvore de widgets, ele chama automaticamente `controller.dispose()`, sem precisarmos transformar a raiz do app em um `StatefulWidget`.
3. **Semântica explícita de leitura vs. assinatura:** oferece as extensões `context.watch<T>()` e `context.read<T>()` diretamente no `BuildContext`.

#### 3. Por que o `ChangeNotifierProvider` DEVE ficar acima do `MaterialApp`?
Esta é uma dúvida crucial sobre a arquitetura interna do Flutter. Veja como a árvore real de `Element`s se comporta quando abrimos uma nova tela com `Navigator.of(context).push(...)`:

```text
LabApp
 └── ChangeNotifierProvider<FavoritesController>   ← Ancestral de TUDO
      └── MaterialApp
           └── Navigator (e seu Overlay interno)
                ├── Rota 0 (home): AppShell
                │    └── IndexedStack
                │         ├── Aba 0: HomePage
                │         │    └── EstablishmentCard  ──(chama Navigator.push)──┐
                │         └── Aba 1: FavoritesPage                              │
                │                                                               ▼
                └── Rota 1 (empilhada no Navigator): EstablishmentDetailsPage ◄─┘
```

- **Atenção ao detalhe técnico:** Embora o comando `Navigator.of(context).push(...)` seja disparado dentro do `onTap` do `EstablishmentCard`, a nova página (`EstablishmentDetailsPage`) **NÃO é inserida como filha do `EstablishmentCard` nem da `HomePage`!**
- Ela é inserida como uma **nova rota irmã** dentro do **`Navigator`** (que mora dentro do `MaterialApp`).
- Se você colocasse o `ChangeNotifierProvider` dentro da `HomePage` (abaixo do `Navigator`), quando a `EstablishmentDetailsPage` abrisse e tentasse buscar o controlador subindo pela árvore a partir do seu `context`, ela chegaria até o `Navigator` → `MaterialApp` → raiz, **sem passar pela `HomePage`**, lançando `ProviderNotFoundException`!
- Posicionando o `ChangeNotifierProvider` **acima do `MaterialApp`** (em `LabApp`), garantimos que o `Navigator` inteiro seja descendente do provedor. Assim, **qualquer aba do `AppShell` e qualquer rota aberta via `Navigator.push`** enxerga o mesmo `FavoritesController`!

---

### 2.6 Fundamentação de `context.watch<T>()` vs. `context.read<T>()`

Por que o pacote `provider` oferece dois métodos diferentes para acessar o mesmo controlador? Tudo se resume a **registrar ou não uma dependência de reconstrução no `Element`**:

| Método | Equivalente interno no Flutter | O que faz na árvore de `Element`s | Onde usar |
|---|---|---|---|
| **`context.watch<T>()`** | `context.dependOnInheritedWidgetOfExactType<...>()` (`listen: true`) | Devolve a instância de `T` **e registra o `Element` atual na lista de dependentes**. Sempre que `T` chamar `notifyListeners()`, o `build` deste widget será reexecutado. | **Exclusivamente dentro do método `build(BuildContext context)`**. |
| **`context.read<T>()`** | `context.getElementForInheritedWidgetOfExactType<...>()` (`listen: false`) | Sobe a árvore em $O(1)$ e devolve a instância de `T`, **sem registrar assinatura**. Quando `notifyListeners()` for chamado, este ponto **não** causa reconstrução. | **Fora do `build`**: dentro de callbacks de eventos (`onPressed`, `onTap`), métodos auxiliares (`_toggleFavorite`) e `initState()`. |

> **O que acontece se o aluno trocar um pelo outro?**
> 1. **Se usar `context.watch<T>()` dentro de um `onPressed: () { ... }`:** o `provider` dispara um `AssertionError` imediato em tempo de execução explicando que um callback de clique ocorre fora da fase de construção de *frame* e não pode assinar reconstruções.
> 2. **Se usar `context.read<T>()` dentro do `build` para exibir a lista ou o ícone:** o app não dá erro, mas a tela fica "congelada" com o valor inicial! Como o `Element` não assinou o provedor, quando `notifyListeners()` for executado o Flutter não saberá que precisa rodar aquele `build` de novo.

---

## 3. A Prática (Refatoração Passo a Passo por Arquivo)

Agora vamos aplicar toda essa fundamentação no nosso projeto `lab_favoritos`, trabalhando arquivo por arquivo dentro da nossa arquitetura de pastas.

### Passo 3.1 — Instalar o pacote `provider`

No terminal, na raiz do projeto `lab_favoritos`, execute:

```bash
flutter pub add provider
```

Isso registrará `provider` na seção `dependencies:` do seu `pubspec.yaml`.

---

### Passo 3.2 — Criar o `FavoritesController` (`lib/features/favorites/presentation/favorites_controller.dart`)

**O que este arquivo propõe e resolve:**
Propõe um controlador centralizado de estado reativo (`ChangeNotifier`) para gerenciar a coleção de estabelecimentos favoritos em memória. Ele resolve três problemas de uma só vez: elimina a duplicação de estado entre telas (atuando como *Fonte Única da Verdade*), preserva a ordem cronológica de salvamento (`List<Establishment>`) e responde consultas de estado (`isFavorite(id)`) em tempo constante $O(1)$ através de um conjunto auxiliar (`Set<String>`), notificando automaticamente todas as telas inscritas a cada alteração.

**Papel Arquitetural (`features/favorites/presentation`):**
Este arquivo é o **coração reativo** da funcionalidade de Favoritos. Ele implementa o papel de **Subject (Observable)** do Padrão *Observer*, concentrando a Fonte Única da Verdade em memória. Repare que importamos apenas `package:flutter/foundation.dart` (onde vive o `ChangeNotifier`), sem importar `material.dart` — um controlador de estado não deve conhecer widgets visuais, cores ou telas.

**Fundamentação dos recursos utilizados no código:**
- **Encapsulamento com campos privados (`_favorites` e `_favoriteIds`):** Em Dart, o prefixo `_` torna o atributo privado à biblioteca (ao arquivo). Nenhum outro arquivo consegue alterar `_favorites` ou `_favoriteIds` diretamente.
- **Getter público somente-leitura (`List<Establishment> get favorites => _favorites`):** Expõe a lista ordenada para a `FavoritesPage`, mas protegida por `List.unmodifiable(...)`.
- **Operador de espalhamento (*Spread Operator* `...`) e *Cascade Notation* (`..`):**
  - Ao remover um ID do conjunto: `{..._favoriteIds}..remove(establishment.id)` cria um novo `Set` copiando os elementos atuais (`...`) e, na mesma expressão (`..`), remove o ID desejado.
  - Ao adicionar na lista: `[establishment, ..._favorites.where((item) => item.id != establishment.id)]` posiciona o novo estabelecimento na primeira posição (índice `0`, garantindo que o mais recente apareça no topo) seguido de todos os demais favoritos já existentes.
- **Notificação dos observadores (`notifyListeners()`):** Chamado após atualizar as estruturas internas, dispara a reconstrução agendada de todas as telas que assinaram este controlador via `context.watch<FavoritesController>()`.

Crie o arquivo `lib/features/favorites/presentation/favorites_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../../establishments/domain/entities/establishment.dart';

class FavoritesController extends ChangeNotifier {
  // 1. Lista privada: preserva a ordem de inserção (mais recente no índice 0).
  List<Establishment> _favorites = const [];

  // 2. Conjunto privado de IDs: garante consulta isFavorite(id) em tempo O(1).
  Set<String> _favoriteIds = const {};

  // Exposição somente-leitura da lista ordenada.
  List<Establishment> get favorites => _favorites;

  // Consulta em tempo constante O(1) chamada no build de cada cartão.
  bool isFavorite(String establishmentId) =>
      _favoriteIds.contains(establishmentId);

  /// Alterna o estado de favorito de [establishment].
  ///
  /// Devolve `true` se o lugar passou a ser favorito e `false` se foi removido.
  bool toggle(Establishment establishment) {
    if (isFavorite(establishment.id)) {
      // Remoção: cria nova lista imutável sem o item e remove o ID do Set.
      _favorites = List.unmodifiable(
        _favorites.where((item) => item.id != establishment.id),
      );
      _favoriteIds = {..._favoriteIds}..remove(establishment.id);

      // Avisa todos os widgets inscritos via context.watch!
      notifyListeners();
      return false;
    }

    // Adição: posiciona o novo favorito no índice 0 (topo da lista).
    _favorites = List.unmodifiable([
      establishment,
      ..._favorites.where((item) => item.id != establishment.id),
    ]);
    _favoriteIds = {..._favoriteIds, establishment.id};

    // Avisa todos os widgets inscritos via context.watch!
    notifyListeners();
    return true;
  }
}
```

---

### Passo 3.3 — Criar o componente reutilizável `FavoriteButton` (`lib/features/establishments/presentation/widgets/favorite_button.dart`)

**O que este arquivo propõe e resolve:**
Propõe um botão de favoritar padronizado, acessível e puramente apresentacional. Ele resolve o problema da repetição de código visual e semântico nos três lugares em que o coração aparece (cartão da Home, cartão dos Favoritos e `AppBar` da tela de detalhes), garantindo que a troca de ícone, a cor de destaque e o rótulo de acessibilidade (`tooltip` com o nome do estabelecimento) sigam exatamente a mesma regra em todo o app.

**Papel Arquitetural (`features/establishments/presentation/widgets`):**
O botão de coração aparece em **três lugares diferentes** do aplicativo: nos cartões da `HomePage`, nos cartões da `FavoritesPage` e na `AppBar` da `EstablishmentDetailsPage`. Extraí-lo para um widget próprio aplica o princípio **DRY (*Don't Repeat Yourself*)**: se amanhã quisermos mudar a cor, o ícone ou o estilo do botão de favorito, alteramos um único arquivo.

**Fundamentação dos recursos utilizados no código:**
- **Componente puramente apresentacional (*Dumb / Presentational Widget*):** O `FavoriteButton` não sabe como salvar um favorito nem conhece o `FavoritesController`. Ele apenas recebe o estado visual atual (`isFavorite`), o nome do estabelecimento (`establishmentName`) e o callback a ser executado quando for pressionado (`onPressed: VoidCallback`).
- **Acessibilidade e Semântica (`tooltip` dinâmico):** Em uma lista com vários cartões na mesma tela, se todos os botões tivessem apenas o texto genérico *"Favoritar"*, uma pessoa cega utilizando leitor de tela (*TalkBack* no Android ou *VoiceOver* no iOS) ouviria vários botões idênticos sem saber a qual restaurante cada um pertence. Ao interpolar `establishmentName` no `tooltip` (*"Salvar Café Aconchego nos favoritos"* / *"Remover Café Aconchego dos favoritos"*), tornamos cada botão único e autoexplicativo, além de exibir uma dica visual ao segurar o toque sobre o ícone.

Crie `lib/features/establishments/presentation/widgets/favorite_button.dart`:

```dart
import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.establishmentName,
    required this.isFavorite,
    required this.onPressed,
  });

  final String establishmentName;
  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Rótulo contextualizado: essencial para leitores de tela (TalkBack/VoiceOver),
    // anunciando claramente qual estabelecimento será salvo ou removido.
    final label = isFavorite
        ? 'Remover $establishmentName dos favoritos'
        : 'Salvar $establishmentName nos favoritos';

    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      color: isFavorite ? Colors.red.shade700 : null,
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }
}
```

---

### Passo 3.4 — Expor o `FavoritesController` acima do `MaterialApp` (`lib/app/lab_app.dart`)

**O que este arquivo propõe e resolve:**
Propõe a injeção global do `FavoritesController` no topo da árvore de widgets do aplicativo usando `ChangeNotifierProvider`. Ele resolve o problema de disponibilizar a mesma instância do controlador tanto para as abas filhas do `AppShell` quanto para as rotas empilhadas dinamicamente no `Navigator` (como a `EstablishmentDetailsPage`), além de automatizar a criação e o descarte (`dispose()`) do controlador da memória.

**Papel Arquitetural (`lib/app/lab_app.dart`):**
Como vimos na fundamentação da Seção 2.5, o `LabApp` é o topo da árvore de widgets. É aqui que injetamos o `FavoritesController` para que ele fique acessível a toda a aplicação.

**Fundamentação dos recursos utilizados no código:**
- **`ChangeNotifierProvider<FavoritesController>`:** Widget do pacote `provider` que cria uma instância de `FavoritesController` através do construtor `create: (_) => FavoritesController()` e a disponibiliza na árvore de `Element`s via `InheritedWidget`.
- **Gerenciamento automático de ciclo de vida:** Repare que `LabApp` continua sendo um `StatelessWidget`! Não precisamos criar um `StatefulWidget` apenas para instanciar o controlador no `initState` e chamar `controller.dispose()` no `dispose` — o próprio `ChangeNotifierProvider` assume a responsabilidade de descartar o controlador quando não for mais necessário.
- **Posição acima do `MaterialApp`:** Garante que o `Navigator` interno do `MaterialApp` seja filho do provedor. Assim, tanto as abas do `AppShell` quanto qualquer nova página empilhada via `Navigator.push` (como a `EstablishmentDetailsPage`) conseguem localizar a mesma instância de `FavoritesController`.

Atualize o arquivo `lib/app/lab_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/favorites/presentation/favorites_controller.dart';
import 'shell/app_shell.dart';

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Posicionado ACIMA do MaterialApp para que todas as abas do AppShell
    // e todas as rotas empilhadas no Navigator enxerguem a mesma instância.
    return ChangeNotifierProvider<FavoritesController>(
      create: (_) => FavoritesController(),
      child: MaterialApp(
        title: 'Lab Favoritos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}
```

---

### Passo 3.5 — Refatorar o `EstablishmentCard` para um `StatelessWidget` puro (`lib/features/establishments/presentation/widgets/establishment_card.dart`)

**O que este arquivo propõe e resolve:**
Propõe a refatoração do cartão de estabelecimento de um `StatefulWidget` com estado isolado para um `StatelessWidget` puro e desacoplado. Ele resolve a inconsistência visual entre telas ao remover o `bool _isFavorite` interno e passar a receber o estado (`isFavorite`) e a ação (`onFavoriteToggle`) via parâmetros de construtor, permitindo reutilizar o mesmo cartão na `HomePage` e na `FavoritesPage` sem acoplar a feature `establishments` à feature `favorites`.

**Papel Arquitetural (`features/establishments/presentation/widgets`):**
O `EstablishmentCard` pertence à funcionalidade `establishments` e será usado tanto na `HomePage` quanto na `FavoritesPage`.

**Fundamentação da refatoração e do desacoplamento entre *features*:**
1. **De `StatefulWidget` para `StatelessWidget`:** Eliminamos a classe `_EstablishmentCardState` e a variável local `bool _isFavorite`. O cartão não é mais "dono" da verdade sobre ser favorito; ele apenas recebe `this.isFavorite = false` pelo construtor e desenha o ícone correspondente.
2. **Desacoplamento arquitetural (Inversão de Controle via Callbacks):** Repare nos `import`s deste arquivo: **ele não importa `provider` e não importa `FavoritesController`!** Por quê? Porque um widget da feature `establishments` não deve depender diretamente da feature `favorites`. Em vez disso, o cartão recebe os parâmetros `isFavorite` (`bool`), `onFavoriteToggle` (`VoidCallback?`) e `onTap` (`VoidCallback`). Quem decide o que fazer quando o coração ou o cartão é tocado é a **página** que está usando o cartão (`HomePage` ou `FavoritesPage`).

Atualize `lib/features/establishments/presentation/widgets/establishment_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/establishment.dart';
import 'favorite_button.dart';

class EstablishmentCard extends StatelessWidget {
  const EstablishmentCard({
    super.key,
    required this.establishment,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Establishment establishment;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          establishment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${establishment.category} · ${establishment.neighborhood} · ★ ${establishment.rating}',
        ),
        trailing: onFavoriteToggle != null
            ? FavoriteButton(
                establishmentName: establishment.name,
                isFavorite: isFavorite,
                onPressed: onFavoriteToggle!,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
```

---

### Passo 3.6 — Refatorar a `EstablishmentDetailsPage` com `watch` e `read` (`lib/features/establishments/presentation/pages/establishment_details_page.dart`)

**O que este arquivo propõe e resolve:**
Propõe a versão reativa da tela de detalhes do estabelecimento, convertida para `StatelessWidget` e conectada ao `FavoritesController` via `provider`. Ela resolve a dessincronização entre a listagem e a rota de detalhes: ao abrir, lê o estado real do favorito com `context.watch` na `AppBar`, e ao receber um toque no coração, altera o controlador global com `context.read`, refletindo a mudança imediatamente tanto na própria tela quanto na listagem ao fundo.

**Papel Arquitetural (`features/establishments/presentation/pages`):**
É a tela de detalhes aberta sobre o `AppShell` quando o usuário toca em um cartão.

**Fundamentação dos recursos utilizados no código:**
- **Eliminação do estado duplicado:** Assim como fizemos no cartão, convertemos a `EstablishmentDetailsPage` de `StatefulWidget` para `StatelessWidget`.
- **Assinatura reativa no `build` com `context.watch<FavoritesController>()`:** Na primeira linha do método `build`, consultamos `context.watch<FavoritesController>().isFavorite(establishment.id)`. Isso faz duas coisas:
  1. Verifica em tempo constante $O(1)$ se o estabelecimento aberto já está no `Set` de favoritos (fazendo o coração da `AppBar` já abrir no estado correto!).
  2. Inscreve o `Element` da `EstablishmentDetailsPage` como ouvinte (*Observer*) do controlador: assim que o usuário tocar no coração da `AppBar`, `notifyListeners()` fará este `build` rodar novamente e o ícone mudará na hora.
- **Disparo de ação no `onPressed` com `context.read<FavoritesController>()`:** Dentro da função de clique do `FavoriteButton`, usamos `read` (e nunca `watch`) para chamar `.toggle(establishment)` sem criar uma inscrição inválida fora do `build`.

Atualize `lib/features/establishments/presentation/pages/establishment_details_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/entities/establishment.dart';
import '../widgets/favorite_button.dart';

class EstablishmentDetailsPage extends StatelessWidget {
  const EstablishmentDetailsPage({
    super.key,
    required this.establishment,
  });

  final Establishment establishment;

  @override
  Widget build(BuildContext context) {
    // No build: context.watch assina reconstruções quando notifyListeners() rodar.
    final isFavorite = context
        .watch<FavoritesController>()
        .isFavorite(establishment.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: [
          FavoriteButton(
            establishmentName: establishment.name,
            isFavorite: isFavorite,
            // No clique (onPressed): context.read apenas aciona o método sem assinar!
            onPressed: () {
              context.read<FavoritesController>().toggle(establishment);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                establishment.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('${establishment.category} · ${establishment.neighborhood}'),
              const SizedBox(height: 4),
              Text('Nota: ★ ${establishment.rating}'),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Passo 3.7 — Conectar a `HomePage` ao `FavoritesController` (`lib/features/home/presentation/pages/home_page.dart`)

**O que este arquivo propõe e resolve:**
Propõe a conexão reativa da tela de catálogo (aba **Início**) com o `FavoritesController`. Ele resolve a atualização automática de todos os cartões da lista principal sempre que um estabelecimento é favoritado ou removido (seja no próprio cartão, na tela de detalhes ou na aba de Favoritos), repassando para cada `EstablishmentCard` seu estado booleano atualizado e o callback de alternância.

**Papel Arquitetural (`features/home/presentation/pages`):**
A `HomePage` atua como uma **página orquestradora**: ela une os dados do catálogo (`sampleEstablishments`) com o estado de favoritos (`FavoritesController`) e entrega tudo mastigado para cada `EstablishmentCard`.

**Fundamentação dos recursos utilizados no código:**
- **Sincronização automática no retorno da navegação:** Como a `HomePage` chama `final favorites = context.watch<FavoritesController>();` dentro do seu `build`, se o usuário abrir a `EstablishmentDetailsPage`, favoritar (ou desfavoritar) o restaurante lá dentro e voltar, a `HomePage` **já estará reconstruída e atualizada**, pois o `IndexedStack` a manteve viva na árvore ouvindo o mesmo `FavoritesController`!
- **Separação clara entre leitura reativa e ação:**
  - Para preencher a propriedade `isFavorite` do cartão durante a construção da lista, usamos a variável `favorites` obtida via `watch`: `isFavorite: favorites.isFavorite(establishment.id)`.
  - Para preencher o callback `onFavoriteToggle`, usamos `context.read<FavoritesController>().toggle(establishment)`.

Atualize `lib/features/home/presentation/pages/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/data/sample_establishments.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../favorites/presentation/favorites_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Assina o controlador no build para atualizar os corações dos cartões.
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimentos')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sampleEstablishments.length,
        itemBuilder: (context, index) {
          final establishment = sampleEstablishments[index];

          return EstablishmentCard(
            establishment: establishment,
            // 2. Consulta O(1) no Set interno do controlador:
            isFavorite: favorites.isFavorite(establishment.id),
            // 3. Dispara a mutação com context.read no callback:
            onFavoriteToggle: () {
              context.read<FavoritesController>().toggle(establishment);
            },
            onTap: () => _openDetails(context, establishment),
          );
        },
      ),
    );
  }
}
```

---

### Passo 3.8 — Construir a `FavoritesPage` reativa (`lib/features/favorites/presentation/pages/favorites_page.dart`)

**O que este arquivo propõe e resolve:**
Propõe a implementação funcional e reativa da aba **Favoritos**. Ele resolve a exibição em tempo real dos estabelecimentos salvos pelo usuário (ordenados do mais recente para o mais antigo), tratando tanto o **Estado Vazio (*Empty State*)** com botão de retorno ao catálogo quanto a **Lista Populada** com contador gramaticalmente correto, desfavoritação imediata e navegação para a tela de detalhes.

**Papel Arquitetural (`features/favorites/presentation/pages`):**
É a segunda aba do `AppShell`, dedicada a exibir exclusivamente a coleção de estabelecimentos salvos pelo usuário, ordenada do mais recente para o mais antigo.

**Fundamentação dos recursos utilizados no código:**
- **Consumo reativo da lista ordenada:** Ao fazer `final favorites = context.watch<FavoritesController>().favorites;`, a página passa a observar a `List<Establishment>` mantida pelo controlador.
- **Tratamento de Estado Vazio (*Empty State*) com chamada para ação (*Call to Action* — CTA):** Uma boa interface nunca deixa uma tela em branco quando não há dados. Quando `favorites.isEmpty` é verdadeiro, exibimos um ícone ilustrativo, uma explicação clara de como favoritar um lugar e um `FilledButton` (*"Ver estabelecimentos"*) que aciona o callback `onExploreTap` (mudando a aba do `AppShell` de volta para o índice `0`).
- **Pluralização cuidadosa no cabeçalho:** Verificamos `favorites.length == 1 ? '1 lugar salvo' : '${favorites.length} lugares salvos'` para evitar o erro gramatical *"1 lugares salvos"*.
- **Uso de *Collection-For* (`for (final establishment in favorites)`) e *Collection-If* (`if (onExploreTap != null) ...[...]`):** Recursos declarativos do Dart moderno que permitem incluir widgets condicionalmente ou iterar sobre uma coleção diretamente dentro da lista `children: [...]` de uma `Column` ou `ListView`, sem precisar de `.map(...).toList()`.
- **Reaproveitamento total do `EstablishmentCard`:** Passamos `isFavorite: true` (já que todo item nesta aba é, por definição, um favorito) e o mesmo callback de `toggle` (permitindo desfavoritar diretamente pela aba de Favoritos) e de `onTap` (permitindo abrir a tela de detalhes também a partir dos Favoritos).

Atualize `lib/features/favorites/presentation/pages/favorites_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Assina a lista de favoritos no build:
    final favorites = context.watch<FavoritesController>().favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Você ainda não salvou nenhum estabelecimento.\n'
                      'Toque no coração em um lugar para encontrá-lo rápido aqui.',
                      textAlign: TextAlign.center,
                    ),
                    if (onExploreTap != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onExploreTap,
                        child: const Text('Ver estabelecimentos'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    favorites.length == 1
                        ? '1 lugar salvo'
                        : '${favorites.length} lugares salvos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final establishment in favorites)
                  EstablishmentCard(
                    establishment: establishment,
                    isFavorite: true,
                    onFavoriteToggle: () {
                      context.read<FavoritesController>().toggle(establishment);
                    },
                    onTap: () => _openDetails(context, establishment),
                  ),
              ],
            ),
    );
  }
}
```

---

## 4. Verificação e Ponte com o CeliLac

### 4.1 Roteiro de Verificação ao Vivo na Tela

Com o app rodando, repita com os alunos o mesmo roteiro que havia falhado na Seção 1:

1. **Sincronia Home → Detalhes:**
   - Na aba **Início**, toque no coração de **Café Aconchego**.
   - Toque no cartão para abrir `EstablishmentDetailsPage`.
   - **Resultado:** O coração na `AppBar` da tela de detalhes já aparece preenchido!
2. **Sincronia Detalhes → Home:**
   - Ainda na `EstablishmentDetailsPage`, toque no coração da `AppBar` para desmarcar e volte para a `HomePage`.
   - **Resultado:** O cartão na `HomePage` já está desmarcado instantaneamente!
3. **Ordem de inserção na Aba Favoritos:**
   - Na `HomePage`, favorite primeiro **Café Aconchego** e depois **Padaria Trigo Zero**.
   - Alterne para a aba **Favoritos**.
   - **Resultado:** O contador exibe *"2 lugares salvos"* e **Padaria Trigo Zero** aparece no topo (índice `0`), acima de **Café Aconchego**.
4. **Remoção na Aba Favoritos e Estado Vazio:**
   - Na aba **Favoritos**, desmarque os dois corações.
   - **Resultado:** A tela transita imediatamente para o estado vazio e o botão *"Ver estabelecimentos"* leva o usuário de volta para a aba **Início**, onde todos os cartões estão desmarcados.

---

### 4.2 Ponte Direta com o CeliLac

Por termos adotado desde o início a arquitetura de pastas por funcionalidades, **cada arquivo que criamos no projeto-laboratório possui um espelho direto no projeto CeliLac**:

| Arquivo no `lab_favoritos` (Etapa 1) | Arquivo correspondente no **CeliLac** |
|---|---|
| `lib/app/lab_app.dart` | [`lib/app/celilac_app.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/app/celilac_app.dart) |
| `lib/app/shell/app_shell.dart` | [`lib/app/shell/app_shell.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/app/shell/app_shell.dart) |
| `lib/features/establishments/domain/entities/establishment.dart` | [`lib/features/establishments/domain/entities/establishment.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/domain/entities/establishment.dart) |
| `lib/features/establishments/presentation/widgets/favorite_button.dart` | [`lib/features/establishments/presentation/widgets/favorite_button.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/presentation/widgets/favorite_button.dart) |
| `lib/features/establishments/presentation/widgets/establishment_card.dart` | [`lib/features/establishments/presentation/widgets/establishment_card.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/presentation/widgets/establishment_card.dart) |
| `lib/features/establishments/presentation/pages/establishment_details_page.dart` | [`lib/features/establishments/presentation/pages/establishment_details_page.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/establishments/presentation/pages/establishment_details_page.dart) |
| `lib/features/home/presentation/pages/home_page.dart` | [`lib/features/home/presentation/pages/home_page.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/home/presentation/pages/home_page.dart) |
| `lib/features/favorites/presentation/favorites_controller.dart` | [`lib/features/favorites/presentation/favorites_controller.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/presentation/favorites_controller.dart) |
| `lib/features/favorites/presentation/pages/favorites_page.dart` | [`lib/features/favorites/presentation/pages/favorites_page.dart`](file:///Users/evertoncoimbradearaujo/Documents/GitHub/dm/2026_2S/celilac/lib/features/favorites/presentation/pages/favorites_page.dart) |

---

### 4.3 Gancho para a Etapa 2 (Provocação Final da Aula)

Para fechar a aula deixando o gancho perfeito para o próximo encontro:
1. Peça para os alunos favoritarem 2 estabelecimentos no app.
2. Peça para executarem um **Hot Restart** (`Shift + R` no terminal ou botão de reiniciar no VS Code) ou fecharem e reabrirem o app.
3. **O que acontece?** Todos os favoritos somem!
4. **Pergunta para a próxima aula (Etapa 2):** *"Nossos favoritos vivem apenas na memória RAM. Precisamos gravá-los no armazenamento do aparelho. Mas se colocarmos código de banco de dados diretamente dentro do `FavoritesController`, quebraremos nossa separação em camadas (`domain`, `data`, `presentation`). Como desacoplar o controlador do mecanismo de persistência?"* → **Contrato `FavoritesRepository` (`domain`), inversão de dependência e fluxo assíncrono (`Future`)!**
