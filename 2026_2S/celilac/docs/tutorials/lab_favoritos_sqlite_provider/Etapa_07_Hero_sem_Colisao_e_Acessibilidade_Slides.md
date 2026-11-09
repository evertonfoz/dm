# Etapa 7 — `Hero` sem Colisão em `IndexedStack` e Acessibilidade em Cartões de Ação Dupla
## Da Colisão de Transições Visuais à Inclusão Digital com Padrões Universais de UX

> **Instrução para o Gamma:** Cada seção separada por `---` corresponde a um slide. O foco está na progressão **Problema → Dor Arquitetural → Fundamentação → Como Resolver**, utilizando diagramas visuais, tabelas comparativas e trechos mínimos de código.

---

## Slide 1 — Capa

### Etapa 7: `Hero` sem Colisão em `IndexedStack` e Acessibilidade em Cartões de Ação Dupla
**Transições visuais fluidas, desambiguação de tags e engenharia de acessibilidade (WCAG 2.2 / AAA)**

- **Contexto:** Laboratório Sequencial CeliLac (Etapa 7 de 7 — Etapa Final de Consolidação)
- **Foco da aula:**
  1. Sentir a dor do crash fatal `multiple heroes that share the same tag` no `IndexedStack`
  2. Compreender a anatomia interna do `IndexedStack` (`Offstage`) e a física do `HeroController`
  3. Resolver a colisão com desambiguação determinística por prefixo de origem (`heroOrigin`)
  4. Identificar a armadilha do `MergeSemantics` em cartões de ação dupla (TalkBack/VoiceOver)
  5. Construir componentes acessíveis com alvos $\ge 48 \times 48\text{ dp}$, rótulos nominais e tipografia resiliente a 200%

---

## Slide 2 — O Cenário de Produto: O App Precisa Ser Fluido e Inclusivo

### O que o usuário espera nas etapas finais de acabamento?

Até a Etapa 6, garantimos que o app persiste dados em SQLite, evolui versões de banco sem perdas e sincroniza múltiplos estados reativamente com `MultiProvider`.

Agora chegamos ao **nível de produto final**:
1. **Continuidade Visual (UX):** Ao tocar no cartão do restaurante para ver seus detalhes, o logotipo deve "voar" suavemente da lista até o topo da tela de detalhes através de uma animação **`Hero`**.
2. **Acessibilidade Universal (A11y):** O aplicativo precisa ser 100% operável por pessoas com deficiência visual usando **leitores de tela (TalkBack / VoiceOver)** ou pessoas com tremores motores que necessitam de alvos de toque adequados.

> **O Desafio:** Ao implementarmos essas duas funcionalidades simultaneamente sobre uma casca com abas (`IndexedStack`), **duas falhas graves de arquitetura emergem de imediato**!

---

## Slide 3 — A Dor 1: A Colisão Fatal de `Hero` no `IndexedStack`

### O que acontece quando o mesmo item está na Home e nos Favoritos?

Imagine que a tag do `Hero` seja gerada apenas com o identificador do estabelecimento:
```dart
// ❌ Tag ingênua sem contexto de origem
Hero(
  tag: 'establishment-icon-${establishment.id}',
  child: EstablishmentLogo(establishment: establishment),
)
```

### O fluxo do crash ao vivo:
1. O usuário favorita o **Café Aconchego** (`id: '1'`) na aba Início.
2. Ele muda para a aba **Favoritos** (`FavoritesPage`). O Café Aconchego está lá!
3. Ele toca no cartão para abrir a tela de detalhes.
4. **💥 CRASH INSTANTÂNEO NO CONSOLE:**

```text
FlutterError (There are multiple heroes that share the same tag within a subtree.
Within each subtree for which heroes are to be animated (i.e. a PageRoute subtree),
each Hero must have a unique tag.
The tag 'establishment-icon-1' was used more than once.)
```

---

## Slide 4 — Diagnóstico da Dor 1: O Ciclo de Vida do `IndexedStack`

### Por que essa colisão acontece no `IndexedStack`?

Ao contrário de navegações que destroem telas ao trocar de aba, o `IndexedStack`:
- Mantém **todas as abas instanciadas na árvore de elementos** para preservar a rolagem e o estado em memória.
- As abas não visíveis são mantidas vivas sob um widget `Offstage(offstage: true)`.

```text
ARQUITETURA DA COLISÃO NA ÁRVORE:
[ AppShell ]
   └── [ IndexedStack (Mesma Route) ]
          ├── [ Aba 0: HomePage ] ──────► Hero(tag: 'establishment-icon-1')  [Visível]
          │                                                                      ▲
          │                                                                      │ 💥 DUPLICIDADE!
          └── [ Aba 1: FavoritesPage ] ─► Hero(tag: 'establishment-icon-1')  [Offstage]
```

> **A Raiz do Problema:** Quando o `Navigator.push` inicia o voo, o `HeroController` varre toda a rota de origem. Ao encontrar **dois widgets com a mesmíssima tag**, ele não sabe de qual coordenada da tela decolar o voo e aborta com erro fatal.

---

## Slide 5 — A Dor 2: A "Barreira Invisível" do `MergeSemantics`

### O que acontece quando tentamos facilitar a leitura de um cartão com 2 ações?

O cartão de um estabelecimento possui **duas ações independentes**:
1. **Ação Principal:** Tocar no cartão abre a `EstablishmentDetailsPage`.
2. **Ação Secundária:** Tocar no coração salva ou remove dos favoritos.

A recomendação comum para cartões simples é usar `MergeSemantics` para o leitor de tela ler o texto de forma fluida.

```dart
// ❌ ARMADILHA: MergeSemantics engolindo botões filhos
MergeSemantics(
  child: Card(
    child: InkWell(
      onTap: () => abrirDetalhes(),
      child: Row(
        children: [
          Text(establishment.name),
          IconButton(
            tooltip: 'Favoritar',
            onPressed: () => toggleFavorite(),
            icon: Icon(Icons.favorite),
          ),
        ],
      ),
    ),
  ),
)
```

---

## Slide 6 — Diagnóstico da Dor 2: A Árvore Semântica Colapsada

### O que o leitor de tela (TalkBack / VoiceOver) realmente enxerga?

O `MergeSemantics` **funde todos os nós semânticos da subárvore em um único bloco**.
Quando há dois manipuladores de toque (`InkWell` e `IconButton`), o nó mesclado mantém apenas a ação primária do elemento ancestral!

```text
❌ COM MERGESEMANTICS (Acessibilidade Destruída):
┌─────────────────────────────────────────────────────────────┐
│ Nó Semântico Único:                                         │
│ "Café Aconchego, Centro, 350m, nota 4.8. Toque duas vezes" │
│                                                             │
│ ⚠️ O botão de favoritar DESAPARECE da árvore semântica!     │
│ ⚠️ Qualquer toque duplo abre os detalhes.                   │
│ ⚠️ Usuário com leitor de tela NÃO CONSEGUE favoritar!       │
└─────────────────────────────────────────────────────────────┘
```

> **E tem mais:** Se o botão tivesse um rótulo estático `"Favoritar"`, um usuário de tecnologia assistiva ouviria dez vezes a palavra *"Favoritar"* sem saber a qual restaurante cada botão pertence.

---

## Slide 7 — A Solução do `Hero`: Tags com Prefixo `origin`

### Como garantir tags únicas na árvore sem perder a animação?

Criamos uma função geradora pura que recebe a **origem do contexto**:

```dart
// lib/features/establishments/presentation/establishment_hero_tag.dart
String establishmentHeroTag(
  String establishmentId, {
  String origin = 'home',
}) {
  return '$origin-establishment-icon-$establishmentId';
}
```

```text
DESAMBIGUAÇÃO NO INDEXEDSTACK:
[ AppShell ]
   └── [ IndexedStack ]
          ├── [ Aba 0: HomePage ] ──────► Hero(tag: 'home-establishment-icon-1')
          │                                 (Tag única na rota!)
          │
          └── [ Aba 1: FavoritesPage ] ─► Hero(tag: 'favorites-establishment-icon-1')
                                            (Tag única na rota!)
```

- Cada aba ganha seu próprio namespace de tags.
- Zero colisão de `Hero`, mesmo com dezenas de itens repetidos em diferentes abas!

---

## Slide 8 — Simetria Origem ↔ Destino no `Navigator`

### Para onde o voo do `Hero` deve viajar?

Para que o efeito visual funcione, a tela de destino (`EstablishmentDetailsPage`) precisa saber de onde o usuário partiu:

```text
FLUXO SIMÉTRICO DE NAVEGAÇÃO:

  [ Cartão na Home ]                     [ DetailsPage ]
  Hero(tag: 'home-icon-1') ────────────► Hero(tag: 'home-icon-1')
  Navigator.push(..., heroOrigin: 'home')

  [ Cartão nos Favoritos ]               [ DetailsPage ]
  Hero(tag: 'favorites-icon-1') ────────► Hero(tag: 'favorites-icon-1')
  Navigator.push(..., heroOrigin: 'favorites')
```

```dart
// Na DetailsPage:
Hero(
  tag: establishmentHeroTag(establishment.id, origin: heroOrigin),
  child: EstablishmentLogo(establishment: establishment, size: 96),
)
```

> **Resultado:** A transição gráfica decola e pousa com perfeição matemática em ambos os fluxos!

---

## Slide 9 — A Solução de Acessibilidade: Cartão de Ação Dupla Desacoplado

### Como permitir dois toques independentes no mesmo cartão?

**Regra de Ouro:** **Retire o `MergeSemantics` externo!**
O próprio `InkWell` do Flutter já agrupa automaticamente os textos informativos (nome, bairro, nota), enquanto o `FavoriteButton` opera como um nó semântico filho independente.

```text
✅ SEM MERGESEMANTICS (Dois Nós Semânticos Acessíveis):
┌─────────────────────────────────────────────────────────────┐
│ [Nó Semântico 1: Cartão + InkWell]                          │
│ "Café Aconchego, Centro, 350m, nota 4.8.                    │
│  Toque duas vezes para abrir detalhes."                     │
│                                                             │
│                      ┌────────────────────────────────────┐ │
│                      │ [Nó Semântico 2: FavoriteButton]   │ │
│                      │ "Salvar Café Aconchego nos         │ │
│                      │  favoritos. Botão."                │ │
│                      └────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

- O leitor de tela foca primeiro o cartão e, ao deslizar o dedo, foca o coração!
- Ambos os comandos podem ser executados via tecnologia assistiva.

---

## Slide 10 — O `FavoriteButton`: Alvo de $48 \times 48\text{ dp}$ e Rótulo Nominal

### Construindo o botão com padrões WCAG 2.2 / AAA:

```dart
class FavoriteButton extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    // 1. Rótulo contextualizado com o NOME do estabelecimento
    final label = isFavorite
        ? 'Remover $establishmentName dos favoritos'
        : 'Salvar $establishmentName nos favoritos';

    return IconButton(
      tooltip: label, // Anunciado pelo TalkBack / VoiceOver
      onPressed: onPressed,
      color: AppColors.navy,
      style: IconButton.styleFrom(
        // 2. Feedback visual de seleção com alto contraste
        backgroundColor: isFavorite
            ? AppColors.gold.withValues(alpha: 0.22)
            : null,
      ),
      // 3. Variação de forma (ícone cheio vs vazado) = Independência de cor
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
    );
  }
}
```

- **Área mínima de toque:** O `IconButton` do Material 3 preserva $48 \times 48\text{ dp}$ nativamente.
- **`labeledTapTargetGuideline`:** Aprovado em todos os testes de acessibilidade!

---

## Slide 11 — Tipografia Responsiva (200% Dynamic Type)

### Por que empilhar a nota e o coração verticalmente à direita?

Em telas estreitas ($320\text{ dp}$) com fonte a $200\%$, colocar o botão de $48\text{ dp}$ **ao lado** da nota consumiria mais de $110\text{ dp}$ de largura horizontal, comprimindo o nome e estourando a tela (*RenderFlex overflow*).

```text
┌───────────────────────────────────────────────────────────┐
│ ┌──────┐  Café Aconchego                   ★ 4,8          │ ← Linha 1: Nota
│ │ Logo │  Café · Centro · 350 m             (♡)           │ ← Linha 2: Coração
│ └──────┘  [Sem glúten] [Sem lactose]                      │
│                                                           │
│                                    [👤 Atende ao perfil]  │ ← Linha 3: Selo
└───────────────────────────────────────────────────────────┘
```

- **Alinhamento em Coluna à Direita (`CrossAxisAlignment.end`):** Não consome nenhum pixel extra de largura útil.
- Suporta nomes longos com `TextOverflow.ellipsis` e quebra de selos com `Wrap`.

---

## Slide 12 — O Código do `EstablishmentCard` Refatorado

### A integração perfeita de todas as soluções em um único widget:

```dart
Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: onTap, // Ação 1: Abrir detalhes
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: establishmentHeroTag(establishment.id, origin: heroOrigin),
                child: EstablishmentLogo(establishment: establishment),
              ),
              Expanded(child: ...), // Textos informativos
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(children: [Icon(Icons.star_rounded), Text(rating)]),
                  if (onFavoriteToggle != null)
                    FavoriteButton( // Ação 2: Favoritar independente
                      establishmentName: establishment.name,
                      isFavorite: isFavorite,
                      onPressed: onFavoriteToggle!,
                    ),
                ],
              ),
            ],
          ),
          if (matchesProfile) _ProfileMatchBadge(),
        ],
      ),
    ),
  ),
)
```

---

## Slide 13 — Verificação Visual com o `SemanticsDebugger`

### Como comprovar a acessibilidade sem depender de intuição?

Ative a propriedade no `MaterialApp`:
```dart
MaterialApp(
  showSemanticsDebugger: true, // Raio-X da árvore de acessibilidade
  // ...
)
```

```text
O QUE VOCÊ VÊ NA TELA DO EMULADOR:
┌──────────────────────────────────────────────────────────┐
│ [ Retângulo 1: "Café Aconchego... Toque para abrir"    ] │
│                                                          │
│                                   ┌────────────────────┐ │
│                                   │ [ Retângulo 2:     │ │
│                                   │   "Salvar Café..." │ │
│                                   │    48×48 dp ]      │ │
│                                   └────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

- Dois retângulos verdes/pretos de foco independentes.
- Rótulos textuais explícitos correspondendo a cada intenção de toque.

---

## Slide 14 — Mapeamento com o CeliLac e Consolidação

### Conexão com os arquivos de produção do CeliLac:

| Laboratório Sequencial | Projeto CeliLac Real | Responsabilidade |
|---|---|---|
| `establishment_hero_tag.dart` | `presentation/establishment_hero_tag.dart` | Elimina colisão de `Hero` no `IndexedStack` com prefixo `origin`. |
| `favorite_button.dart` | `presentation/widgets/favorite_button.dart` | Botão inclusivo com alvo de $48\times 48\text{ dp}$ e `tooltip` nominal. |
| `establishment_card.dart` | `presentation/widgets/establishment_card.dart` | Cartão de ação dupla sem `MergeSemantics` aglutinador. |
| `establishment_details_page.dart`| `presentation/pages/establishment_details_page.dart`| Recepção de `heroOrigin` para transição simétrica de voo. |

---

## Slide 15 — A Jornada Completa dos 7 Degraus Concluída!

### Da memória efêmera ao aplicativo profissional, resiliente e inclusivo:

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │ Degrau 7: Hero sem Colisão e Acessibilidade (WCAG 2.2 / AAA)          │
 ├────────────────────────────────────────────────────────────────────────┤
 │ Degrau 6: MultiProvider e Inicialização Paralela Concorrente (.wait)   │
 ├────────────────────────────────────────────────────────────────────────┤
 │ Degrau 5: Evolução do Banco e Migração de Esquema (ALTER TABLE)        │
 ├────────────────────────────────────────────────────────────────────────┤
 │ Degrau 4: Tradução de Tipos Compostos Dart ↔ SQLite (enum, Set, Date) │
 ├────────────────────────────────────────────────────────────────────────┤
 │ Degrau 3: Persistência Relacional com SQLite (CRUD e Anti-Injection)   │
 ├────────────────────────────────────────────────────────────────────────┤
 │ Degrau 2: Desacoplamento de Domínio e Contrato Repository Assíncrono   │
 ├────────────────────────────────────────────────────────────────────────┤
 │ Degrau 1: Estado Compartilhado em Memória com ChangeNotifier (O(1))   │
 └────────────────────────────────────────────────────────────────────────┘
```

> **Missão Cumprida:** Seu aplicativo agora conta com uma base arquitetural sólida, segura contra falhas, com alta performance em memória e disco, e desenhado para todos os usuários!

