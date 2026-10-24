# CeliLac: Perfil Alimentar (roteiro de implementação)
## Formulários, persistência em JSON, estado compartilhado entre telas e testes

> **Material final gerado:** [CeliLac_Perfil_Alimentar.md](CeliLac_Perfil_Alimentar.md), com capturas e diagramas em `docs/perfil/`. Este roteiro continua como registro do plano e das decisões.

> **Este documento é o plano de trabalho**, e não o material didático final. Ele registra **o que** será implementado, em que ordem, com quais arquivos, decisões e critérios de pronto. Depois da implementação (e de cada parte validada com `flutter analyze` e `flutter test`), ele serve de base para escrever o material `CeliLac_Perfil_Alimentar.md` no mesmo formato dos anteriores (Conceito → código → **Conceitos** → **Atenção** / **No seu projeto** / **Execute**).

Este material continua o **CeliLac: Detalhe do Estabelecimento**. O onboarding fez três promessas; duas já têm onde ser cumpridas:

| Página do onboarding | Promessa | Onde é cumprida |
|---|---|---|
| 1. Descoberta | "Encontre opções adequadas a você" | Home: lista "Perto de você" (busca e categorias ainda "em breve") |
| 2. Informação | "Entenda antes de escolher" | Detalhe do estabelecimento |
| 3. Personalização | "Uma experiência mais relevante" | **Este material** |

Hoje, o cartão "Complete seu perfil alimentar" da Home e a aba **Perfil** respondem "em breve". O próprio cartão já promete o comportamento que vamos construir: *"Conte o que você precisa evitar e veja **primeiro** as opções mais adequadas."*

---

# Parte 0: Antes do código

## 0.1 Conceito: o que é um perfil (e o que não é)

O perfil existe para **mudar o que o app mostra**. Cada campo precisa ter um efeito visível; um campo que não muda nada é burocracia.

| Campo | Efeito visível |
|---|---|
| Nome (opcional) | Saudação "Boa tarde, Ana!" na Home |
| O que preciso evitar (glúten, lactose) | A lista "Perto de você" mostra primeiro quem atende, com o selo "Atende ao seu perfil" |
| Cuidado com contaminação cruzada | Guardado agora; usado no detalhe (Desafio 1) e no filtro do Explorar (próximo material) |

**Não é um cadastro:** sem e-mail, sem senha e sem servidor. O perfil fica **no aparelho**. Isso deve ser dito ao usuário na própria tela ("Suas informações ficam só neste aparelho").

**Responsabilidade:** o app não diagnostica nada. A tela traz a frase "O CeliLac não substitui orientação médica ou nutricional." e evita termos clínicos nos rótulos ("Preciso evitar glúten", e não "Sou celíaco").

## 0.2 Fluxo

```text
Splash ──(carrega onboarding + perfil)──► AppShell
                                              │
     Home: cartão "Complete seu perfil" ──push──► ProfileFormPage ──salvar──► pop + "Perfil salvo"
     Aba Perfil: resumo ou estado vazio ──push──► ProfileFormPage
                                              │
     Ao salvar: Home e aba Perfil se atualizam sozinhas (estado compartilhado)
```

- O formulário abre com `push` **sobre o shell** (a barra some), como o detalhe.
- A aba Perfil **mostra** o perfil; o formulário **edita**. Separar leitura e edição evita uma tela que é ao mesmo tempo resumo e formulário.

## 0.3 Estrutura e hierarquia do formulário

```text
AppBar: "Perfil alimentar"  [voltar]
──────────────────────────────────────
Como podemos te chamar? (opcional)
[ Nome                              ]

O que você precisa evitar?          ← obrigatório: pelo menos um
[✓] Glúten
[ ] Lactose
  (mensagem de erro aqui, se nada marcado)

[switch] Preciso de cuidado com contaminação cruzada
         Mostraremos se o lugar tem área de preparo
         ou utensílios separados.    ← só habilitado com "Glúten" marcado

ⓘ Suas informações ficam só neste aparelho.
  O CeliLac não substitui orientação médica ou nutricional.
──────────────────────────────────────
[            Salvar perfil           ]  ← ativo só quando algo mudou
```

## 0.4 O que fica de fora (e por quê)

| Tentação | Por que não agora |
|---|---|
| Login, conta, sincronização na nuvem | Exige servidor, privacidade (LGPD) e recuperação de senha. O perfil local já cumpre a promessa. |
| Foto de perfil | Não muda nada no que o app mostra (Parte 0.1). |
| **Esconder** quem não atende ao perfil | Filtrar é papel do Explorar. Na Home, **ordenar** mantém tudo visível e não esconde opções que a pessoa talvez aceite. |
| Muitas restrições (ovo, soja, nozes...) | O domínio do app (`DietaryOption`) só conhece glúten e lactose. Novas opções entram primeiro nos **dados** dos estabelecimentos. |
| Abrir o formulário ao final do onboarding | O onboarding já é uma barreira antes do app; somar um formulário aumenta o abandono. A Home convida, sem obrigar. |
| Aviso de contaminação no detalhe | Fica como desafio (Parte 10), para manter o material focado. |
| Provider / Riverpod | Primeiro entendemos o mecanismo que eles usam por baixo (`InheritedWidget` + `ChangeNotifier`). O pacote vem com os Favoritos. |

## 0.5 Estrutura de pastas

```text
lib/
├── app/
│   ├── celilac_app.dart                         ← (alterado) cria o ProfileController e o ProfileScope
│   └── shell/
│       └── app_shell.dart                       ← (alterado) aba Perfil real
└── features/
    ├── profile/                                 ← nova feature
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── dietary_profile.dart         ← novo
    │   │   ├── repositories/
    │   │   │   └── profile_repository.dart      ← novo: o contrato
    │   │   └── profile_match.dart               ← novo: funções puras (atende? ordenar)
    │   ├── data/
    │   │   ├── dietary_profile_json.dart        ← novo: toJson / fromJson
    │   │   └── local_profile_repository.dart    ← novo: SharedPreferencesAsync
    │   └── presentation/
    │       ├── profile_controller.dart          ← novo: ChangeNotifier
    │       ├── profile_scope.dart               ← novo: InheritedNotifier
    │       ├── dietary_option_labels.dart       ← novo: extension com os rótulos do perfil
    │       ├── pages/
    │       │   ├── profile_page.dart            ← novo: aba Perfil
    │       │   └── profile_form_page.dart       ← novo: formulário
    │       └── widgets/
    │           ├── restrictions_field.dart      ← novo: FormField<Set<DietaryOption>>
    │           ├── profile_summary_card.dart    ← novo
    │           ├── profile_privacy_note.dart    ← novo
    │           └── discard_changes_dialog.dart  ← novo
    ├── establishments/presentation/widgets/
    │   └── establishment_card.dart              ← (alterado) selo "Atende ao seu perfil"
    ├── home/presentation/
    │   ├── pages/home_page.dart                 ← (alterado) ordena, esconde o cartão, abre o formulário
    │   └── widgets/home_header.dart             ← (alterado) nome na saudação
    ├── onboarding/presentation/onboarding_page.dart  ← (alterado) ilustrações próprias
    └── startup/presentation/splash_page.dart    ← (alterado) carrega o perfil; tokens de espaçamento

test/
├── support/
│   ├── memory_profile_repository.dart           ← novo: repositório em memória
│   └── pump_app.dart                            ← novo: monta a tela com ProfileScope
├── app/
│   └── app_shell_test.dart                      ← novo: aba Perfil no shell
├── features/profile/
│   ├── dietary_profile_test.dart                ← novo
│   ├── dietary_profile_json_test.dart           ← novo
│   ├── local_profile_repository_test.dart       ← novo: SharedPreferences em memória
│   ├── profile_match_test.dart                  ← novo
│   ├── profile_controller_test.dart             ← novo
│   ├── profile_scope_test.dart                  ← novo: of × read
│   ├── profile_form_page_test.dart              ← novo
│   └── profile_page_test.dart                   ← novo
├── features/startup/
│   └── splash_page_test.dart                    ← novo: perfil carregado na Splash
└── features/home/home_page_test.dart            ← (alterado) perfil + acessibilidade permanente
```

**Por que `profile/` é uma feature própria:** é um assunto (o usuário e suas necessidades) usado por várias telas (Home, aba Perfil e, depois, Explorar e Detalhe).

**Direção da dependência:** `profile/domain` importa `DietaryOption` e `Establishment` de `establishments/domain`. O contrário **não** acontece: estabelecimentos não sabem que existe perfil. Quem junta os dois é a Home (camada de apresentação).

## 0.6 Roteiro

```text
Parte 1  Preparando o terreno   ilustrações do onboarding, pendências herdadas, README, acessibilidade da Home
Parte 2  Domínio                DietaryProfile, igualdade por valor, contrato, funções puras de "atende"
Parte 3  Persistência           JSON, SharedPreferencesAsync, dados corrompidos ou de versões antigas
Parte 4  Estado compartilhado   ChangeNotifier, InheritedNotifier, onde criar, carregar na Splash
Parte 5  O formulário           Form, TextFormField, FormField próprio, campo dependente, salvar, descartar
Parte 6  A aba Perfil           vazio × preenchido, resumo, editar
Parte 7  A Home personalizada   saudação, cartão condicional, ordenação, selo no cartão
Parte 8  Qualidade              fonte ampliada, leitor de tela em formulários, teclado, áreas de toque
Parte 9  Testes                 repositório em memória, unidade, controller, widget (complementar)
Parte 10 Revisão                decisões, alternativas, pendências; aplicando no seu projeto; desafios
```

---

# Parte 1: Preparando o terreno

Como na Parte 1 do Detalhe: antes da feature nova, arrumar o que ela vai tocar. **Rode `flutter test` antes e depois** de cada passo; nada de comportamento muda aqui.

## 1.1 Ilustrações do onboarding

**Situação:** as três páginas usam `discovery.png` (pendência do material de Splash e Onboarding, Parte 5.4). A página 3 é justamente a promessa que este material cumpre, então a ilustração precisa existir.

**Passos:**
1. Gerar `information.png` e `profile.png` com os prompts do **Apêndice A** deste roteiro, usando `discovery.png` como referência de estilo.
2. Conferir: fundo transparente, 1254×1254 px (mesmo tamanho da `discovery.png`), sem texto, paleta da marca, menos de 300 KB (otimizar com `pngquant` ou TinyPNG).
3. Salvar em `assets/images/onboarding/` (a pasta já está declarada no `pubspec.yaml`).
4. Trocar os `imagePath` das páginas 2 e 3 em `onboarding_page.dart`.

**Pronto quando:** as três páginas mostram ilustrações diferentes e a série parece feita pela mesma mão.

**Para o material:** decisões de *asset* (tamanho, peso, transparência) e consistência de série; reaproveitar a especificação do Apêndice A do material de Splash. O texto para os alunos está pronto nas Partes 1.1.1 a 1.1.6 abaixo.

### 1.1.1 Conceito: tamanho em pixels × peso do arquivo

Uma imagem tem **duas** medidas diferentes, e elas costumam ser confundidas:

| Medida | O que é | Exemplo | Afeta |
|---|---|---|---|
| **Dimensões** | quantos pixels a imagem tem | 1254 × 1254 px | a **nitidez** na tela |
| **Peso** | quantos bytes o arquivo ocupa | 1 MB | o tamanho do app para baixar e instalar |

Quando o arquivo está pesado, a tentação é **diminuir as dimensões**. O peso cai, mas a imagem passa a ter menos pixels do que a tela precisa, e o Flutter é obrigado a **esticá-la**: as bordas ficam borradas. O caminho certo é **diminuir as cores** e manter as dimensões.

### 1.1.2 Quantos pixels a tela precisa?

O Flutter mede o layout em **dp** (*density-independent pixels*, pixels independentes de densidade). Cada aparelho tem uma **densidade** (`devicePixelRatio`): quantos pixels físicos existem em cada dp.

```text
pixels necessários = largura na tela (dp) × densidade do aparelho
```

A ilustração do onboarding ocupa a largura da tela menos as margens. Medimos com um teste de widget (`tester.getSize`) em quatro tamanhos de aparelho:

| Aparelho | Largura na tela | Densidade | Pixels necessários |
|---|---|---|---|
| Android pequeno (360×640) | 153 dp | 2x | 306 px |
| Android comum (Pixel) | 348 dp | 2,625x | 914 px |
| iPhone 15 | 329 dp | 3x | 987 px |
| iPhone Pro Max | 366 dp | 3x | 1098 px |

No Android pequeno a ilustração fica menor porque a **altura** da tela a limita (`Flexible` + `AspectRatio(1)`).

**Conclusão:** a imagem precisa de cerca de **1100 px** para ficar nítida em todos. Os originais de **1254 px** atendem com folga.

> **O que aconteceu no projeto da aula:** as imagens foram primeiro reduzidas para 314 px (cerca de 90 KB) e depois para 627 px (cerca de 300 KB). Nos dois casos, num iPhone a imagem era esticada 3,1 e 1,6 vezes, e ficava borrada. O problema só foi resolvido voltando aos originais de 1254 px e comprimindo as **cores**.

### 1.1.3 Conceito: quantização de cores

Um PNG comum (**RGBA de 32 bits**) pode usar até 16 milhões de cores, e cada pixel guarda a sua cor completa. Uma ilustração plana como as do CeliLac usa **poucas** cores: navy, dourado, alguns cinzas e branco. Quase toda essa capacidade é desperdício.

A **quantização** escolhe uma **paleta** de no máximo 256 cores que representa bem a imagem. Cada pixel passa a guardar só o **número** da cor na paleta (1 byte, em vez de 4). A transparência continua funcionando, porque a paleta guarda também a transparência de cada cor.

| | Antes | Depois |
|---|---|---|
| Formato | RGBA, 32 bits por pixel | paleta (*colormap*), 8 bits por pixel |
| Dimensões | 1254 × 1254 | 1254 × 1254 (iguais) |
| Cores possíveis | ~16 milhões | até 256 |

A ferramenta usada é o **`pngquant`**, gratuita e de linha de comando.

### 1.1.4 Execute: comprimindo as ilustrações

Na pasta do projeto (`celilac/`), no macOS com Homebrew:

```bash
# 1. Instalar (uma vez só)
brew install pngquant

# 2. Guardar uma cópia dos originais FORA do projeto
mkdir -p ~/celilac_originais
cp assets/images/onboarding/*.png ~/celilac_originais/

# 3. Comprimir no lugar, mantendo as dimensões
pngquant --quality=70-90 --speed 1 --strip --ext .png --force assets/images/onboarding/*.png

# 4. Conferir dimensões e peso
file assets/images/onboarding/*.png
ls -lh assets/images/onboarding/
```

> **No Windows:** baixe o `pngquant.exe` em pngquant.org (ou `winget install pngquant`) e rode o passo 3 no PowerShell, com a barra invertida no caminho. **No Linux:** `sudo apt install pngquant`.

**O que cada opção faz:**

| Opção | Significado |
|---|---|
| `--quality=70-90` | busca qualidade 90 e aceita no mínimo 70. Se precisar ficar abaixo de 70 para caber em 256 cores, o `pngquant` **não altera** o arquivo e avisa |
| `--speed 1` | o modo mais lento e mais caprichado. Para poucas imagens, leva segundos |
| `--strip` | remove metadados (data, programa que gerou a imagem), que não servem para o app |
| `--ext .png --force` | grava por cima do próprio arquivo. Por isso a cópia do passo 2 |

**Resultado no CeliLac:**

| Arquivo | Antes | Depois | Redução |
|---|---|---|---|
| `discovery.png` | 1.023 KB | 235 KB | 77% |
| `information.png` | 1.080 KB | 222 KB | 79% |
| `profile.png` | 1.003 KB | 219 KB | 78% |
| **Total** | **3,1 MB** | **676 KB** | **78%** |

O comando `file` confirma: as três continuam com `1254 x 1254` e passaram de `8-bit/color RGBA` para `8-bit colormap` (a paleta).

### 1.1.5 Conferindo a qualidade

Compressão com perda exige **olhar**:

1. Abra cada imagem e a cópia correspondente em `~/celilac_originais/` lado a lado, com zoom de 200% (no macOS, no Pré-Visualização).
2. Observe as bordas do ramo dourado e as sombras cinza do chão: são os pontos onde a falta de cores aparece primeiro, como **faixas** (*banding*) em vez de transição suave.
3. Se aparecerem faixas, restaure o original e comprima de novo com mais qualidade: `--quality=80-95`.
4. Rode o app com **reinício completo** (`flutter run` de novo, ou `R` maiúsculo no terminal). O *hot reload* **não** recarrega assets.

> **Atenção:** nunca comprima uma imagem que já foi comprimida. Cada rodada perde um pouco mais. Comprima sempre **a partir do original**, e guarde o original fora do projeto (ou no Git, antes da compressão).

### 1.1.6 Peso do arquivo × memória do aparelho

A compressão diminui o **arquivo** (o app fica menor para baixar), mas **não** a memória usada para mostrar a imagem. Para desenhar, o Flutter **descompacta** cada imagem em RGBA:

```text
1254 × 1254 pixels × 4 bytes = cerca de 6 MB de memória por ilustração
```

No onboarding isso não preocupa: são três imagens, uma por vez. Numa **lista** com dezenas de fotos, o caminho é decodificar a imagem no tamanho em que ela aparece, com `cacheWidth`/`ResizeImage`, como na Parte 5 do material de Detalhe do Estabelecimento.

> **Alternativa: variantes por densidade.** O Flutter também aceita pastas `2.0x/` e `3.0x/` ao lado do asset (`assets/images/onboarding/2.0x/discovery.png`) e escolhe a variante certa para cada aparelho. Vale a pena quando a diferença entre as versões é grande, como ícones ou fotos. Para três ilustrações de cerca de 220 KB, um arquivo só é mais simples.

**Conceitos:**
- **Dimensões × peso:** nitidez depende das dimensões; tamanho do app depende do peso.
- **dp e `devicePixelRatio`:** pixels necessários = largura em dp × densidade.
- **Quantização:** troca milhões de cores possíveis por uma paleta de até 256; perde pouco em ilustrações planas e mais em fotos (para fotos, prefira JPEG ou WebP).
- **Compressão com perda:** sempre a partir do original, sempre conferida a olho.
- **Arquivo × memória:** o arquivo comprimido é descompactado em RGBA na hora de desenhar.

**No seu projeto:**
1. Meça quanto a imagem ocupa na tela (em dp) no maior aparelho que você quer atender.
2. Multiplique por 3: essa é a largura mínima em pixels.
3. Comprima as cores com `pngquant` (ilustrações) ou converta para JPEG/WebP (fotos).
4. Confira com zoom e no aparelho.

## 1.2 Pendências visuais herdadas

Vamos mexer na `SplashPage` na Parte 4, então é o momento de resolver as pendências registradas nos materiais anteriores:

| Pendência | Onde | Ação |
|---|---|---|
| Texto `navy 70%` | `onboarding_page.dart:241`, `splash_page.dart:174` | Subir para 80%, conferindo o contraste (Home, Parte 1.5) |
| Espaçamentos fora da grade | `splash_page.dart` (`12.0`, `40.0`, `10.0`, `32.0`, `8.0`, `16.0`) | Trocar pelos tokens `AppSpacing` mais próximos (12→`sm`/`md`, 40→`xl`, 10→`sm`) e conferir visualmente |
| Splash nativa com `color_dark`, app só claro | `flutter_native_splash.yaml` | **Decidir:** remover o modo escuro da splash nativa ou registrar de novo como pendência até existir `AppTheme.dark` |

**Pronto quando:** `grep -n "alpha: 0.7" lib/` não acha texto e a Splash usa só tokens.

## 1.3 Acessibilidade permanente da Home

Pendência do Detalhe (Parte 9): copiar o teste `segue as regras de acessibilidade` (`establishment_details_page_test.dart:153`) para `home_page_test.dart`, com as quatro diretrizes (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`).

**Por que agora:** a Parte 7 vai mudar a Home (cartão condicional, selo novo). O teste precisa existir **antes** para pegar uma regressão.

## 1.4 README do projeto

Trocar o README padrão do Flutter por: o que é o CeliLac, como rodar (`flutter pub get`, `flutter run`, `flutter test`), versão do Flutter/Dart usada e a lista dos materiais em `docs/tutorials/` na ordem de leitura.

## 1.5 Registro da implementação (24/10/2026)

- **1.1** `information.png` e `profile.png` geradas (1254×1254, fundo transparente, série coerente com a `discovery.png`) e ligadas às páginas 2 e 3. Primeiro foram reduzidas em **dimensões** (314 px e depois 627 px), o que borrava a imagem; depois, voltaram aos 1254 px originais e foram comprimidas com `pngquant --quality=70-90 --speed 1 --strip`: de 3,1 MB para 676 KB no total (−78%), com qualidade conferida a olho. Originais guardados em `~/celilac_originais/`. Texto didático nas Partes 1.1.1 a 1.1.6.
- **1.2** Texto de 70% para 80% no onboarding e na Splash. Espaçamentos trocados pelos tokens, com mudanças visuais pequenas: onboarding, imagem→título 40→32 e título→traço dourado 12→16; Splash, traço→frase 12→8, progresso→versão 40→32, texto→barra 10→8. Também foram trocados por tokens, sem mudança visual: o *padding* da barra superior e do botão, o *padding* lateral e as bolinhas do indicador. **Decisão:** o `color_dark` da splash nativa fica até existir `AppTheme.dark` (continua como pendência no material).
- **1.3** Teste `segue as regras de acessibilidade` na Home: passou sem ajustes (as 4 diretrizes).
- **1.4** README reescrito.
- `flutter analyze` sem avisos; 32 testes passando.

## 1.6 O que **não** muda na Parte 1

`ComingSoonView` continua existindo: Explorar e Favoritos ainda o usam. Só a aba Perfil sai dele (Parte 6).

---

# Parte 2: Domínio

## 2.1 `DietaryProfile`

```dart
// features/profile/domain/entities/dietary_profile.dart
class DietaryProfile {
  const DietaryProfile({
    this.name,
    this.restrictions = const {},
    this.needsCrossContactCare = false,
  });

  static const DietaryProfile empty = DietaryProfile();

  final String? name;
  final Set<DietaryOption> restrictions;   // reaproveita o enum dos estabelecimentos
  final bool needsCrossContactCare;

  bool get isComplete => restrictions.isNotEmpty;

  DietaryProfile copyWith({...});

  @override
  bool operator ==(Object other) => ...;    // igualdade por valor (inclui o Set)

  @override
  int get hashCode => ...;
}
```

**Decisões a explicar:**
- **Reaproveitar `DietaryOption`** em vez de criar um enum novo: "preciso evitar glúten" e "o lugar oferece sem glúten" são o **mesmo** conceito visto de dois lados. Isso é o que torna a comparação da Parte 2.3 trivial.
- **Nome opcional (`String?`)**, normalizado no formulário (`trim`; vazio vira `null`).
- **`copyWith`** com o problema clássico: como "limpar" o nome (passar `null`) se `null` significa "não mudar"? Solução didática: parâmetro `clearName` (ou função `String? Function()?`). Escolher **uma** e explicar.
- **Igualdade por valor (`==` e `hashCode`)**: necessária para "o botão Salvar só fica ativo quando algo mudou" (Parte 5.6). Comparar `Set` sem importar Flutter: `a.length == b.length && a.containsAll(b)`; `hashCode` com `Object.hash(name, Object.hashAllUnordered(restrictions), needsCrossContactCare)`.
- **Regra de negócio no domínio:** cuidado com contaminação só faz sentido com glúten (as `SafetyPractice` falam de "itens sem glúten"). O `copyWith`/construtor **não** força isso; quem garante é o formulário (Parte 5.5). Registrar a decisão.

**Conceitos:** `static const`, igualdade por valor × por identidade, `hashCode` consistente com `==`, `Object.hashAllUnordered`.

## 2.2 O contrato

```dart
// features/profile/domain/repositories/profile_repository.dart
abstract interface class ProfileRepository {
  Future<DietaryProfile> load();      // nunca null: sem perfil salvo = DietaryProfile.empty
  Future<void> save(DietaryProfile profile);
}
```

**Contraste com `fetchDetails`** (que devolve `null` para "não encontrado"): aqui **ausência de perfil é um estado normal**, representado pelo objeto vazio (*Null Object*). Explicar quando cada abordagem é melhor.

## 2.3 Funções puras: "atende ao meu perfil?"

```dart
// features/profile/domain/profile_match.dart
bool meetsProfile(Establishment establishment, DietaryProfile profile);

/// Primeiro quem atende; dentro de cada grupo, a ordem original (distância).
List<Establishment> sortByProfile(List<Establishment> establishments, DietaryProfile profile);
```

- `meetsProfile`: `establishment.dietaryOptions.containsAll(profile.restrictions)`. Perfil vazio: **ninguém** recebe o selo (sem perfil, o selo não diz nada), e a ordem não muda.
- `sortByProfile`: **devolve uma nova lista**, sem alterar a recebida. **Atenção:** `List.sort` do Dart **não é estável**. Para manter a ordem por distância dentro de cada grupo, usar dois `where` concatenados (`[...atende, ...naoAtende]`), que é estável e legível. Bom ponto para um teste de unidade.

**Conceitos:** função pura, imutabilidade da entrada, estabilidade de ordenação, por que isso fica fora do widget (mesma regra do `greetingFor`).

## 2.4 Registro da implementação (24/10/2026)

- `lib/features/profile/domain/entities/dietary_profile.dart`: escolhido `clearName: true` para limpar o nome no `copyWith` (mais legível para iniciantes que `String? Function()?`). Igualdade com `length` + `containsAll` e `Object.hashAllUnordered`.
- `lib/features/profile/domain/repositories/profile_repository.dart`: contrato `load` / `save`; `load` nunca devolve `null`.
- `lib/features/profile/domain/profile_match.dart`: `meetsProfile` (perfil vazio → `false`) e `sortByProfile` com dois `where`, com um comentário explicando que `List.sort` não é estável.
- Domínio sem `import 'package:flutter/...'` (conferido com `grep`).
- Testes de unidade **adiantados** da Parte 9.2: `dietary_profile_test.dart` (10 casos) e `profile_match_test.dart` (7 casos). 49 testes passando; `flutter analyze` sem avisos.
- **Atenção para o material:** no teste de igualdade, os dois perfis são criados com `final`, e não `const`. Objetos `const` com os mesmos valores são **canonicalizados** (viram o mesmo objeto), e o teste deixaria de provar a igualdade por valor. Bom ponto para explicar `const` × `identical`.

---

# Parte 3: Persistência

## 3.1 Conceito: do objeto ao texto e de volta

`SharedPreferences` só guarda tipos simples. Duas opções: uma chave por campo ou **um JSON em uma chave só**. Escolha: **JSON em uma chave** (`dietary_profile`):
- a gravação é **atômica** (não existe perfil "meio salvo");
- `toJson`/`fromJson` é exatamente o que será preciso quando houver API.

## 3.2 `dietary_profile_json.dart` (camada `data`)

```dart
extension DietaryProfileJson on DietaryProfile {
  Map<String, Object?> toJson() => {
    'version': 1,
    'name': name,
    'restrictions': [for (final r in restrictions) r.name],
    'needsCrossContactCare': needsCrossContactCare,
  };
}

DietaryProfile dietaryProfileFromJson(Map<String, Object?> json);
```

**Decisões a explicar:**
- **Por que fora do domínio:** o formato de gravação é detalhe de infraestrutura; o domínio continua sem saber que JSON existe.
- **Enums por `.name`**, e não por `.index`: reordenar o enum não corrompe dados antigos.
- **Leitura tolerante:** valor desconhecido em `restrictions` (enum renomeado, versão futura) é **ignorado**, e não derruba o app. Campo ausente usa o padrão. Tipo errado também.
- **`version`:** campo para migrações futuras; hoje só é gravado.

## 3.3 `LocalProfileRepository`

```dart
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({SharedPreferencesAsync? preferences});  // mesmo padrão do OnboardingStorage
  static const String _key = 'dietary_profile';
  ...
}
```

- `load`: sem chave → `DietaryProfile.empty`; JSON inválido (`FormatException`) → `DietaryProfile.empty` **e** apaga a chave corrompida? Decidir e justificar (sugestão: devolver vazio sem apagar, para não perder dados por um bug de leitura).
- `save`: `jsonEncode` + `setString`. Erros **sobem** (o controller decide como avisar).

**Conceitos:** `jsonEncode`/`jsonDecode`, `Map<String, Object?>`, *pattern matching* do Dart 3 para ler o JSON com segurança (`if (json case {'name': String? name})`), injeção da dependência pelo construtor para testes.

## 3.4 Registro da implementação (24/10/2026)

Mudanças em relação ao plano das Partes 3.2 e 3.3, já pensando nos materiais de SQLite e Supabase (Parte 3.5):

- **Chaves em `snake_case`** (`needs_cross_contact_care`), e não `camelCase`: são os nomes que as colunas terão no SQLite e no Postgres do Supabase. Assim, o mesmo `toJson`/`dietaryProfileFromJson` serve para ler uma linha do Supabase (que chega como `Map<String, dynamic>`).
- **A versão do formato saiu do `toJson`:** quem grava `schema_version` é o `LocalProfileRepository` (`{'schema_version': 1, ...profile.toJson()}`). Motivo: a versão é um detalhe **do armazenamento local**. Uma tabela não teria essa coluna, e o `toJson` precisa servir para os dois. O `fromJson` ignora chaves que não conhece.
- **Leitura tolerante, em Dart 3:**
  - `switch` com *guard* para o nome: `final String name when name.trim().isNotEmpty => name`.
  - `DietaryOption.values.asNameMap()` para converter texto em enum sem laço.
  - **Elemento nulo-ciente** (`?options[value]`, Dart 3.8) dentro do literal de `Set`: valor desconhecido simplesmente não entra. O analisador (`use_null_aware_elements`) sugeriu essa forma no lugar de `if (... case final option?) option`; vale mostrar as duas.
  - `json['needs_cross_contact_care'] == true`: qualquer coisa que não seja o booleano `true` vira `false`.
- **JSON corrompido:** `load` devolve `DietaryProfile.empty` **sem apagar** a chave; JSON válido que não é objeto (`[1, 2]`) também vira vazio (`if (jsonDecode(stored) case final Map<String, Object?> json)`).
- **Erros do armazenamento** (no `getString`/`setString`) **sobem**; quem decide o que fazer é o controller (Parte 4).
- **Testes sem aparelho:** `shared_preferences_platform_interface` como `dev_dependency`, com `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()` no `setUp`. Arquivos: `dietary_profile_json_test.dart` (7 casos, incluindo o **JSON da versão 1 fixo no teste**) e `local_profile_repository_test.dart` (6 casos, incluindo "fechar e abrir o app" com uma instância nova do repositório).
- `flutter analyze` sem avisos; 62 testes passando.

## 3.5 Ponte para os próximos materiais: SQLite e Supabase

O perfil fica em `SharedPreferences` porque é **um registro só**, lido inteiro e gravado inteiro. O material deve dizer quando isso deixa de bastar, e o contrato `ProfileRepository` é o que torna a troca barata: **só a raiz de composição muda** (Parte 4.4).

```text
                        ProfileRepository (contrato, no domínio)
                       /              |                 \
LocalProfileRepository   SqliteProfileRepository   SupabaseProfileRepository
 (SharedPreferences,      (material de SQLite)      (material de Supabase)
  este material)
```

| Armazenamento | Serve para | No CeliLac |
|---|---|---|
| `SharedPreferences` | poucos valores simples, lidos inteiros | onboarding concluído, perfil |
| SQLite (`sqflite` ou `drift`) | coleções, consultas, ordenação, relações, funcionar *offline* | **Favoritos** (lista que cresce, ordenada por data, consultada por `id`) e *cache* dos estabelecimentos |
| Supabase (Postgres + API REST + autenticação) | dados compartilhados entre aparelhos e usuários | **estabelecimentos reais** no lugar do `FakeEstablishmentRepository`; perfil sincronizado depois do login |

**Sugestão de sequência**, que aproveita o que já existe:

1. **SQLite com os Favoritos:** o caso que `SharedPreferences` resolve mal (lista, consulta "este `id` é favorito?", ordenação por data). Conteúdo: tabela, `CREATE TABLE`, migração de versão do banco (ligação direta com o `schema_version` deste material), `bool` como `INTEGER 0/1`, restrições como texto, `FavoritesRepository` com contrato, testes com `sqflite_common_ffi` em memória. Também é o momento do estado compartilhado "de verdade" (o mesmo favorito na Home, no Detalhe e na aba).
2. **Supabase com os estabelecimentos:** `SupabaseEstablishmentRepository implements EstablishmentRepository` substitui o *fake* sem mudar nenhuma tela; erros de rede reais aparecem nos estados que a Home e o Detalhe **já tratam**. Depois, autenticação e o perfil numa tabela `profiles` (`name text`, `restrictions text[]`, `needs_cross_contact_care boolean`), lida com o mesmo `dietaryProfileFromJson`.

**Para registrar no material:** as chaves `snake_case`, a versão fora do `toJson` e o contrato que nunca devolve `null` são decisões tomadas **agora** para que esses dois materiais sejam uma troca de implementação, e não uma reescrita.

---

# Parte 4: Estado compartilhado

## 4.1 Conceito: o problema

A Home e a aba Perfil ficam **vivas ao mesmo tempo** dentro do `IndexedStack`, e o formulário é empilhado por cima do shell. Quando o formulário salva, as outras duas precisam saber. Passar o perfil por construtores não funciona: a Home já foi construída e não "pergunta de novo".

Mostrar a progressão: `setState` (só vale dentro de um widget) → *callbacks* subindo e descendo (frágil) → **um objeto observável acima de todos** (a solução).

## 4.2 `ProfileController` (`ChangeNotifier`)

```dart
class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;
  DietaryProfile _profile = DietaryProfile.empty;
  bool _isLoaded = false;

  DietaryProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  Future<void> load();                         // idempotente: carregar duas vezes não faz mal
  Future<void> save(DietaryProfile profile);   // grava primeiro; só então atualiza e notifica
}
```

**Decisão central:** `save` **grava antes de notificar**. Se a gravação falhar, o estado em memória continua igual ao do disco e a exceção chega ao formulário, que mostra o erro. Explicar a alternativa (atualização otimista) e por que não aqui.

## 4.3 `ProfileScope` (`InheritedNotifier`)

```dart
class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({super.key, required ProfileController controller, required super.child})
      : super(notifier: controller);

  /// Lê e **se inscreve**: o widget reconstrói quando o perfil muda (use no build).
  static ProfileController of(BuildContext context);

  /// Só lê: para usar em callbacks e no initState (não reconstrói).
  static ProfileController read(BuildContext context);
}
```

- `of` usa `dependOnInheritedWidgetOfExactType`; `read` usa `getInheritedWidgetOfExactType`.
- **Ponte para o futuro:** é exatamente o `context.watch` / `context.read` do Provider. Quando o pacote chegar (Favoritos), a ideia já é conhecida.

## 4.4 Onde criar: acima do `MaterialApp`

`CeliLacApp` vira `StatefulWidget`: cria o `ProfileController` no `initState`, faz o `dispose` e envolve o `MaterialApp` com o `ProfileScope`.

- **Por que acima do `MaterialApp`:** as rotas empilhadas com `push` (formulário, detalhe) ficam **dentro** do `Navigator` do `MaterialApp`. Um *scope* colocado no `AppShell` não seria visto por elas. Desenhar a árvore no material.
- `CeliLacApp({ProfileRepository? profileRepository})`: parâmetro opcional para os testes, com `LocalProfileRepository()` como padrão. Esta é a **raiz de composição** do app.

## 4.5 Carregar na Splash

A Splash já diz "Carregando suas preferências". Agora isso passa a ser verdade:

```dart
final results = await Future.wait([
  OnboardingStorage().isCompleted(),
  ProfileScope.read(context).load(),   // read: estamos fora do build
]);
```

- `Future.wait`: as duas leituras em paralelo.
- `read` antes do primeiro `await` (o `context` ainda é válido) e `mounted` depois, como já é feito.
- Se o carregamento do perfil falhar, o app segue com o perfil vazio (o perfil é melhoria, não bloqueio).

**Conceitos:** `ChangeNotifier`, `notifyListeners`, `InheritedWidget`/`InheritedNotifier`, `of` × `read`, ciclo de vida do controller, raiz de composição, `Future.wait`.

## 4.6 Registro da implementação (24/10/2026)

- **`ProfileController`** (`lib/features/profile/presentation/profile_controller.dart`):
  - `load()` é `_loading ??= _load()`: chamadas simultâneas (Splash e uma tela) ou repetidas **compartilham o mesmo `Future`** e leem o repositório uma vez só. Bom exemplo de `??=` com `Future`.
  - **Falha na leitura é tratada no controller**, e não na Splash: `catch` → segue com `DietaryProfile.empty`, `isLoaded = true` e `debugPrint`. Motivo: se a Splash tratasse, o `isLoaded` ficaria `false` para sempre e a aba Perfil mostraria um indicador eterno.
  - `save` grava primeiro; só depois atualiza e notifica (falha: exceção sobe, estado e ouvintes intactos).
- **`ProfileScope`** (`profile_scope.dart`): `of` com `dependOnInheritedWidgetOfExactType`, `read` com `getInheritedWidgetOfExactType`, os dois com `assert` e mensagem em português quando não há *scope* acima. Importa só `package:flutter/widgets.dart` (não precisa do Material).
- **`CeliLacApp`** virou `StatefulWidget` com `ProfileRepository? profileRepository` (padrão `LocalProfileRepository()`); cria o controller no `initState`, faz o `dispose`, e o `ProfileScope` envolve o `MaterialApp`.
- **Splash** (mudanças em relação à Parte 4.5):
  - O carregamento **começa no início do `_initialize`**, antes das animações, e corre em paralelo com elas: a Splash não fica nem um milissegundo mais longa. O `read` é chamado antes do primeiro `await`, quando o `context` com certeza é válido.
  - Em vez de `Future.wait([...])` (lista sem tipo), foi usado o **`.wait` de *record*** do Dart 3: `final (completed, _) = await (OnboardingStorage().isCompleted(), profileLoad).wait;`. Cada posição mantém o seu tipo (`bool`, `void`), e a desestruturação dá nome ao resultado. Vale mostrar as duas formas.
- **Defeito encontrado pelo teste e corrigido:** a linha "Carregando suas preferências / 42%" da Splash tem largura fixa de 280 e **transbordava** com texto largo (a fonte de teste é mais larga; no aparelho, o mesmo acontece com fonte ampliada). Correção: `Flexible` no texto de status e um `SizedBox(width: AppSpacing.sm)` antes da porcentagem. Bom exemplo de teste que encontra um problema que ninguém procurava.
- **Testes:**
  - `test/support/memory_profile_repository.dart`: repositório em memória com `failOnLoad`, `failOnSave` e contadores.
  - `profile_controller_test.dart` (6): estado inicial, carregar e notificar uma vez, leitura única com chamadas simultâneas, falha na leitura, salvar, falha ao salvar.
  - `profile_scope_test.dart` (2): `of` reconstrói e `read` não, **contando os `build`**. O `save` roda dentro de `tester.runAsync`.
  - `test/features/startup/splash_page_test.dart` (2): o app inteiro (`CeliLacApp`) com `InMemorySharedPreferencesAsync.withData`; carrega o perfil durante a Splash e abre o `AppShell`; falha na leitura não impede de abrir o onboarding. **Atenção:** no fim, `pumpAndSettle(Duration(seconds: 1))` para o atraso de 800 ms do `FakeEstablishmentRepository` terminar, senão o teste falha com "A Timer is still pending".
- `flutter analyze` sem avisos; 72 testes passando.

---

# Parte 5: O formulário (`ProfileFormPage`)

Passo a passo, como na Parte 4 do Detalhe: cada passo roda e mostra algo na tela.

## 5.1 Passo 1: esqueleto e rascunho

- `StatefulWidget`; no `initState`, copiar o perfil atual (`ProfileScope.read`) para o **rascunho** (`_draft`) e criar o `TextEditingController` do nome. `dispose` do controller.
- `Scaffold` + `AppBar("Perfil alimentar")` + `Form(key: _formKey)` + `SingleChildScrollView` + largura máxima do `AppLayout`.
- Botão "Salvar perfil" fixo embaixo (`bottomNavigationBar` com `SafeArea`) para ficar sempre visível, inclusive com o teclado aberto.

**Conceito:** rascunho × perfil salvo. O formulário **nunca** altera o controller até o "Salvar".

## 5.2 Passo 2: o nome (`TextFormField`)

- `textCapitalization: TextCapitalization.words`, `textInputAction: TextInputAction.done`, `autofillHints: [AutofillHints.givenName]`, `maxLength: 30`.
- Validador: vazio é válido (campo opcional); se preenchido, pelo menos 2 caracteres depois do `trim`.
- `onChanged` atualiza o rascunho (para o "Salvar" reagir).

**Conceitos:** `InputDecoration` (rótulo, dica, contador), validador, por que usar `labelText` e não só `hintText` (o *hint* some ao digitar e o leitor de tela pode não lê-lo).

## 5.3 Passo 3: restrições, um `FormField` próprio

```dart
class RestrictionsField extends FormField<Set<DietaryOption>> { ... }
```

- Um `CheckboxListTile` por `DietaryOption`, com rótulos do perfil vindos de uma *extension* (`dietary_option_labels.dart`): `glutenFree` → "Glúten", `lactoseFree` → "Lactose", com `switch` exaustivo (o compilador avisa se surgir uma opção nova).
- Validador: pelo menos uma marcada → "Escolha pelo menos uma opção."; o texto de erro aparece abaixo do grupo (`state.errorText`).
- **Por que um `FormField` próprio:** para entrar no `_formKey.currentState!.validate()` junto com o nome, em vez de uma validação "por fora".

**Conceitos:** `FormField<T>`, `FormFieldState` (`value`, `didChange`, `errorText`), *extension methods* para rótulos da camada de apresentação (o enum continua sem saber de textos do perfil).

## 5.4 Passo 4: o cuidado com contaminação cruzada (campo dependente)

- `SwitchListTile` com título e subtítulo explicativo.
- `onChanged: null` (desabilitado) quando "Glúten" não está marcado; ao desmarcar "Glúten", o rascunho passa `needsCrossContactCare` para `false`.
- **Acessibilidade:** um controle desabilitado precisa explicar por quê. Subtítulo muda para "Disponível quando você marca Glúten."

**Conceito:** campos que dependem de outros; regra de negócio (Parte 2.1) garantida na interface.

## 5.5 Passo 5: aviso de privacidade

`ProfilePrivacyNote`: ícone + as duas frases da Parte 0.1. Texto, e não diálogo: é informação, não decisão.

## 5.6 Passo 6: salvar

- `bool get _hasChanges => _draft != _original;` (usa a igualdade da Parte 2.1).
- Botão desabilitado quando `!_hasChanges || _isSaving`; durante a gravação mostra um `CircularProgressIndicator` pequeno no lugar do texto (e o rótulo semântico "Salvando").
- `_save`: `validate()` → normaliza o nome → `await controller.save(...)` → `if (!mounted) return;` → `pop` + `SnackBar("Perfil salvo")`.
- Erro: `SnackBar("Não foi possível salvar. Tente novamente.")` e a tela **continua** aberta com o rascunho.
- Proteção contra toque duplo (lembrar da Parte 6.3 do material de Splash).

**Conceitos:** `GlobalKey<FormState>`, validação no envio × durante a digitação (`autovalidateMode: onUserInteraction` só **depois** da primeira tentativa de envio), `mounted` após `await`.

## 5.7 Passo 7: descartar alterações

- `PopScope(canPop: !_hasChanges, onPopInvokedWithResult: ...)` → `DiscardChangesDialog` ("Descartar alterações?" / "Continuar editando" / "Descartar").
- Vale para o botão voltar da `AppBar`, o voltar do Android e o gesto do iOS.
- Ponte com o `PopScope` do `AppShell` (Home, Parte 3.4): mesmo widget, outro uso.

**Conceitos:** `showDialog<bool>`, retorno de valor de um diálogo, `AlertDialog` com a ação destrutiva **à direita** e em texto claro.

## 5.8 Registro da implementação (24/10/2026)

**Arquivos novos:**

| Arquivo | Papel |
|---|---|
| `presentation/dietary_option_labels.dart` | `extension DietaryOptionProfileLabel` com `avoidLabel` ("Glúten", "Lactose") por `switch` exaustivo |
| `presentation/widgets/restrictions_field.dart` | `RestrictionsField extends FormField<Set<DietaryOption>>`: um `CheckboxListTile` por opção, validador "Escolha pelo menos uma opção.", erro em `Semantics(liveRegion: true)` |
| `presentation/widgets/profile_privacy_note.dart` | ícone + as duas frases, em `MergeSemantics` (lidas de uma vez) |
| `presentation/widgets/discard_changes_dialog.dart` | `confirmDiscardChanges(context)` → `Future<bool>`; tocar fora do diálogo conta como **não** descartar |
| `presentation/pages/profile_form_page.dart` | a tela |

**Decisões tomadas na implementação (diferenças em relação ao plano):**

- **O rascunho é sempre normalizado:** o `onChanged` do nome já faz `trim` e transforma vazio em `clearName: true`. Assim, `_hasChanges` é só `_draft != _original`: digitar "Ana " sobre "Ana" **não** ativa o "Salvar".
- **O botão "Salvar" fica fora da rolagem, mas não no `bottomNavigationBar`:** o `body` é uma `Column` com `Expanded(Form(SingleChildScrollView(...)))` e o botão embaixo. Motivo: o `bottomNavigationBar` fica **atrás** do teclado; dentro do `body`, o botão sobe junto com o redimensionamento (`resizeToAvoidBottomInset`). Explicar isso no material com uma figura.
- **Regra glúten → contaminação aplicada em `_onRestrictionsChanged`**: ao desmarcar "Glúten", `needsCrossContactCare` vira `false` no mesmo `copyWith`.
- **`autovalidateMode`** do `Form` começa `disabled` e vira `onUserInteraction` depois da primeira tentativa de salvar (`_submitted`): o erro não aparece antes de a pessoa tentar, e some assim que ela corrige.
- **Salvar:** `ScaffoldMessenger` e `ProfileScope.read` capturados **antes** do `await` (o `context` pode não valer depois); `mounted` conferido depois; a `SnackBar` "Perfil salvo" aparece na tela de baixo porque o `ScaffoldMessenger` é do `MaterialApp`, e não da rota.
- **`Navigator.pop()` depois de salvar não passa pelo `PopScope`:** o `PopScope` só intercepta o voltar do sistema, o botão da `AppBar` e o gesto (`maybePop`). Por isso não é preciso atualizar `_original` antes de fechar. **Ponto para o material:** `pop` × `maybePop`.
- O nome usa `filled: true` com fundo branco e `OutlineInputBorder`, para destacar o campo do fundo `#F2F2F2`.
- O formulário **ainda não é aberto por nenhuma tela**: isso acontece nas Partes 6 (aba Perfil) e 7 (cartão da Home). Por enquanto, só os testes o abrem.

**Testes:**

- `test/support/pump_app.dart`: `pumpWithProfile(tester, home, {repository, size, textScale})` monta `ProfileScope` + `MaterialApp` com tema, `pt_BR` e o perfil **já carregado**; `PushButtonHost` empilha uma página para testar o voltar.
- `profile_form_page_test.dart` (12): abre preenchido; "Salvar" só com mudanças (e volta a desabilitar ao desfazer); exige restrição (e o erro some ao corrigir); recusa nome de uma letra; contaminação depende de glúten; salva com nome normalizado, fecha e mostra "Perfil salvo"; falha mantém tela e rascunho; voltar sem mudanças fecha direto; voltar com mudanças pergunta ("Continuar editando" mantém; "Descartar" fecha sem gravar); 200% em 320×640; acessibilidade com perfil **vazio** (interruptor desabilitado) e **preenchido**.
- **Atenção para o material:** `tester.pageBack()` procura o botão pela dica em inglês ("Back"). Com o app em português, use `tester.tap(find.byTooltip('Voltar'))`. O teste ainda confere a tradução de quebra.
- **Para discutir:** o `textContrastGuideline` passa com o interruptor desabilitado, mas o subtítulo "Disponível quando você marca Glúten." aparece em cinza claro, o estilo padrão de controle desabilitado. A WCAG dispensa componentes inativos da regra de contraste, mas este texto **explica** a regra. Avaliar com usuários se ele precisa de cor normal.
- `flutter analyze` sem avisos; 84 testes passando.

---

# Parte 6: A aba Perfil (`ProfilePage`)

- Substitui o `ComingSoonView` da aba Perfil no `AppShell` (a lista `_tabs` continua `const`: a página lê o perfil pelo `ProfileScope`).
- **Perfil vazio:** `StatusMessage` (já compartilhado) com ícone, "Conte o que você precisa evitar para personalizar o CeliLac." e ação "Completar perfil".
- **Perfil preenchido:** `ProfileSummaryCard` com nome (ou "Sem nome"), as restrições como selos (reaproveitar o visual do `DietaryBadge`), o cuidado com contaminação, e o botão "Editar perfil".
- Os dois estados abrem o mesmo `ProfileFormPage` com `MaterialPageRoute`.
- Enquanto `!controller.isLoaded` (caso raro: a aba aberta antes do fim da Splash não acontece, mas os testes podem montar a página direto), mostrar um indicador simples.

**Conceitos:** uma página, dois estados vindos do mesmo dado; `ListenableBuilder` × `ProfileScope.of` (mostrar os dois, usar um).

## 6.1 Registro da implementação (24/10/2026)

- **`ProfilePage`** (`presentation/pages/profile_page.dart`): `StatelessWidget`. O `ProfileScope.of(context)` no `build` basta para a aba se redesenhar quando o perfil muda, sem `setState` e sem `StatefulWidget`. **Ponto forte para o material:** a aba não tem estado próprio; o estado mora no controller.
  - Tem `Scaffold` + `AppBar("Perfil")` próprios, dentro do `Scaffold` do shell. Scaffolds aninhados são normais; a Home usa `SliverAppBar` porque rola com o conteúdo.
  - Três estados: carregando (`!isLoaded`), vazio (`StatusMessage` com "Completar perfil") e preenchido (`ProfileSummaryCard`); `ProfilePrivacyNote` nos dois últimos.
- **`ProfileSummaryCard`** (`presentation/widgets/profile_summary_card.dart`):
  - Avatar com a inicial (`name.characters.first`, e não `name[0]`, que quebraria com emoji ou acento combinado) ou ícone, fora da semântica (`ExcludeSemantics`); nome (ou "Seu perfil") marcado como cabeçalho.
  - **Reaproveita o `DietaryBadge`** dos cartões ("Sem glúten", "Sem lactose"), sob o texto "Você procura opções". Decisão: o selo do perfil é **o mesmo** do cartão do estabelecimento, então a pessoa reconhece visualmente o que combina. Isso substitui os rótulos "Glúten"/"Lactose" do formulário: no formulário, a pessoa diz o que **evita**; no resumo, ela vê o que **procura**.
  - Selos ordenados por `DietaryOption.values`, e não pela ordem do `Set` (que depende da ordem em que foram marcados).
  - Linha "Com cuidado contra contaminação cruzada" só quando ligado; botão "Editar perfil" (`OutlinedButton`, 48 dp).
- **`ProfileFormPage.route()`**: método estático que cria a rota. Um só lugar sabe como abrir o formulário; a Home vai usar o mesmo na Parte 7.
- **`AppShell`**: `ComingSoonView` da aba Perfil trocado por `ProfilePage()`; a lista `_tabs` continua `const`.
- **Testes:**
  - `profile_page_test.dart` (8): vazio convida; preenchido mostra resumo; sem nome e sem cuidado extra se adapta; completar troca convite por resumo **sem nova leitura do repositório** (`loadCalls == 1`); editar atualiza o resumo; 200%; acessibilidade vazio/preenchido.
  - `test/app/app_shell_test.dart` (1): a aba Perfil do shell mostra a `ProfilePage`, e não "em breve". O toque usa `find.descendant(of: find.byType(NavigationBar), ...)`, porque "Perfil" também é o título da `AppBar`.
- `flutter analyze` sem avisos; 93 testes passando.

---

# Parte 7: A Home personalizada

## 7.1 Saudação com nome

`HomeHeader({required greeting, String? name})` → "Boa tarde, Ana!" ou "Boa tarde!". Resolve a pendência "`HomeHeader(name: ...)` quando o perfil existir" (Home, Parte 8).

## 7.2 Cartão de perfil condicional

- `ProfilePromptCard` só aparece quando `!profile.isComplete` (resolve o Desafio 2 da Home).
- O botão "Completar perfil" deixa de mostrar "em breve" e abre o `ProfileFormPage`.
- O espaçamento ao redor some **junto** com o cartão (atenção ao `SizedBox` órfão).

## 7.3 Ordenação e selo

- No `builder` do `FutureBuilder`: `sortByProfile(snapshot.data!, profile)`. **Não** chamar o repositório de novo quando o perfil muda: os dados não mudaram, só a ordem (ligar ao "erro mais comum" do `FutureBuilder`, Home Parte 5.6).
- `EstablishmentCard` ganha `bool matchesProfile = false` → selo "Atende ao seu perfil" (ícone de check + texto, **não** só cor), incluído no rótulo do `MergeSemantics` do cartão.
- Abaixo do título "Perto de você", uma linha discreta quando há perfil: "Primeiro, os que atendem ao seu perfil." (explica a ordem, que de outra forma pareceria aleatória).

**Execute:** salvar o perfil com "Lactose" e ver o Empório Natural e o Café Aconchego subirem com o selo; salvar com "Glúten" e "Lactose" e ver só Café Aconchego e Bistrô Bem-Estar com o selo.

**Conceitos:** o mesmo dado (perfil) mudando duas telas vivas ao mesmo tempo; dado derivado calculado no `build`; acessibilidade de um selo.

## 7.4 Registro da implementação (24/10/2026)

- **`HomeHeader`** ganhou `String? name`: "Boa tarde, Ana!" ou "Boa tarde!".
- **`HomePage`**:
  - `final profile = ProfileScope.of(context).profile;` no `build`: a Home se redesenha quando o perfil é salvo no formulário ou na aba Perfil.
  - Cartão de perfil e o espaço **antes** dele dentro do mesmo `if (!profile.isComplete) ...[ ... ]`. Sem o cartão, a busca fica a `xl` das categorias, sem buraco.
  - "Completar perfil" abre `ProfileFormPage.route()` (o "em breve" saiu).
  - Abaixo de "Perto de você", com perfil: "Primeiro, os que atendem ao seu perfil."
  - `_buildNearby(profile)`: `sortByProfile(snapshot.data, profile)` **dentro do `builder`** e `meetsProfile` para cada cartão. O `FutureBuilder` recebe o mesmo `Future`; só a ordem muda, sem nova busca.
- **Selo "Atende ao seu perfil"** (`establishment_card.dart`):
  - O cartão recebe `bool matchesProfile = false`, e o selo é um widget **privado** do próprio cartão (`_ProfileMatchBadge`). **Decisão de arquitetura:** `establishments/` continua sem importar nada de `profile/`; quem calcula o `bool` é a Home, que junta os dois assuntos (Parte 0.5). Bom ponto para o material: "quem decide" × "quem mostra".
  - **Posição (ajustada depois do teste no app):** abaixo da linha inteira do cartão, alinhado à **direita**, na mesma vertical da nota (★). O conteúdo do cartão virou `Column(crossAxisAlignment: end, children: [Row(...), if (matchesProfile) selo])`. Alinhar à direita só dentro da coluna de texto não bastaria: ela termina antes da nota, e o selo ficaria "solto" no meio. Bom exemplo para o material de como a estrutura de `Row`/`Column` define o que dá para alinhar com o quê.
  - Visual: fundo navy cheio com texto branco, diferente dos selos dourados das opções alimentares (o selo fala da **pessoa**, não do lugar); ícone + texto, para não depender só da cor; dentro do `MergeSemantics` do cartão, então o leitor de tela lê "Atende ao seu perfil" junto com o resto.
- **Testes da Home** (`home_page_test.dart`, reescrito com `pumpWithProfile`, 13 casos):
  - "Completar perfil" abre o formulário (substitui o teste do "em breve").
  - Perfil completo: nome na saudação, sem o cartão, com a frase de ordem.
  - Sem perfil: ordem por distância, sem selo. Com perfil "Lactose": Empório Teste (1,2 km) **acima** do Café Teste (350 m), com selo. A ordem é conferida pela posição vertical (`tester.getTopLeft(...).dy`).
  - **Integração:** abrir o formulário pela Home, marcar "Lactose", salvar → cartão some, lista reordenada, selo aparece e `nearbyCalls == 1`.
  - 200% em 320×640 com perfil (o selo deixa o cartão mais alto) e acessibilidade sem e com perfil.
- **Atenção para o material:**
  - `tester.ensureVisible` só encontra o que **já foi construído**. Com o cartão de perfil na tela, o segundo estabelecimento ficava fora da área construída da lista (`SliverList` constrói sob demanda) e o teste falhava com "Bad state: No element". Solução: `tester.scrollUntilVisible(finder, 200)`, que rola até o item existir. Liga com a Parte 4.1 da Home ("por que slivers?").
  - Os testes antigos da Home passaram a rodar em `pt_BR`; o `pageBack()` virou `tap(find.byTooltip('Voltar'))`, como no formulário.
- `flutter analyze` sem avisos; 99 testes passando.

---

# Parte 8: Qualidade

- **Fonte a 200%:** formulário e aba Perfil sem *overflow* em 320×640; o botão fixo embaixo não pode cobrir o último campo (rolagem com *padding* inferior).
- **Teclado:** o campo de nome rola para a vista quando o teclado abre; "Concluir" do teclado fecha o teclado (`onFieldSubmitted` → `unfocus`).
- **Leitor de tela:** grupo "O que você precisa evitar?" anunciado como cabeçalho; erro do grupo anunciado (`SemanticsService.sendAnnouncement` ou `liveRegion`); *switch* desabilitado com o motivo; estado de "Salvando".
- **Áreas de toque:** `CheckboxListTile` e `SwitchListTile` já têm 48 dp; conferir o botão fixo.
- **Contraste:** o selo novo do cartão passa no `textContrastGuideline`.

---

# Parte 9: Testes (complementar)

## 9.1 Apoio

- `test/support/memory_profile_repository.dart`: guarda em memória; opções para **falhar** no `save` e para **atrasar** o `load`. Conta as chamadas.
- `test/support/pump_app.dart`: `pumpWithProfile(tester, child, {profile, repository})`, que monta `ProfileScope` + `MaterialApp` com o `AppTheme` e o `locale` `pt_BR`. Atualizar os testes existentes da Home para usar esse apoio (a Home passa a precisar do *scope*).

## 9.2 Unidade

| Arquivo | Casos |
|---|---|
| `dietary_profile_test.dart` | `isComplete`; `==` e `hashCode` com *sets* em ordem diferente; `copyWith` limpando o nome |
| `dietary_profile_json_test.dart` | ida e volta; restrição desconhecida ignorada; campo ausente; tipo errado; JSON de "versão 1" fixo no teste (protege dados de usuários reais) |
| `profile_match_test.dart` | perfil vazio não muda a ordem nem dá selo; quem atende sobe; ordem por distância preservada dentro dos grupos; lista original intacta |
| `profile_controller_test.dart` | `load` notifica uma vez; `save` grava e notifica; `save` com falha não muda o estado e repassa a exceção |

## 9.3 Widget

| Arquivo | Casos |
|---|---|
| `profile_form_page_test.dart` | "Salvar" desabilitado sem mudanças; erro ao salvar sem restrição; *switch* desabilitado sem glúten e desligado ao desmarcar; salvar fecha a tela e mostra "Perfil salvo"; falha mantém a tela; voltar com alterações pergunta e "Continuar editando" mantém; acessibilidade (4 diretrizes); 200% sem *overflow* |
| `profile_page_test.dart` | vazio mostra a ação; preenchido mostra o resumo; editar e salvar atualiza o resumo **sem** recarregar a página |
| `home_page_test.dart` (alterado) | cartão de perfil some com perfil completo; nome na saudação; ordem e selo; "Completar perfil" abre o formulário; acessibilidade (Parte 1.3) |

**Pronto quando:** `flutter analyze` sem avisos e todos os testes passando (os 31 atuais + os novos).

---

# Parte 10: Revisão, aplicação e desafios

## Decisões e alternativas (para a tabela final do material)

| Decisão | Alternativa | Quando mudar |
|---|---|---|
| perfil local (`SharedPreferences`) | conta + servidor | quando o usuário precisar do perfil em mais de um aparelho |
| JSON em uma chave | uma chave por campo; SQLite (`sqflite`, `drift`) | quando houver coleções e consultas (Favoritos, no material de SQLite) |
| perfil só no aparelho | tabela `profiles` no Supabase | com login, no material de Supabase (o mesmo `fromJson` lê a linha) |
| `ChangeNotifier` + `InheritedNotifier` | Provider, Riverpod, Bloc | com os Favoritos, quando houver vários estados compartilhados |
| ordenar na Home | filtrar | no Explorar, onde o usuário escolhe filtrar |
| `DietaryOption` reaproveitado | enum próprio de restrições | quando o perfil tiver restrições que os estabelecimentos não informam |
| salvar e depois notificar | atualização otimista | quando a gravação for lenta (rede) e a falha for rara |

## Pendências que este material resolve

- [x] Ilustrações próprias no onboarding (Splash, Parte 5.4)
- [x] `navy 70%` e espaçamentos fora da grade (herdadas)
- [ ] Splash nativa escura com app só claro: **mantida** até existir `AppTheme.dark`
- [x] Acessibilidade permanente da Home (Detalhe, Parte 9)
- [x] `HomeHeader(name:)` (Home, Parte 8)
- [x] Desafio 2 da Home: esconder o cartão de perfil
- [x] "em breve" do perfil (Home) e aba Perfil
- [x] (encontrada no caminho) texto de status da Splash transbordava com fonte ampliada

## Desafios propostos

1. **O perfil no detalhe.** Com `needsCrossContactCare`, mostrar no detalhe um aviso quando o lugar não informa `separateKitchen` nem `exclusiveUtensils`. Onde fica a função pura? Quem depende de quem?
2. **Apagar o perfil.** Botão "Apagar perfil" na aba Perfil, com confirmação. O que o contrato precisa ganhar?
3. **Desfazer.** Depois de salvar, a `SnackBar` oferece "Desfazer". O que o controller precisa guardar?
4. **Migração de versão.** Simular a "versão 2" do JSON com um campo renomeado e escrever a migração, com teste usando o JSON da versão 1.
5. **Perfil no fim do onboarding.** Fazer um teste A/B mental: quais métricas diriam se perguntar o perfil no onboarding é melhor?

---

# Apêndice A: Prompts para as ilustrações que faltam

## Especificação

- **Referência obrigatória:** anexe `assets/images/onboarding/discovery.png` ao gerador (ou use `--sref` no Midjourney). É ela que define o estilo da série.
- **Formato:** PNG, fundo **transparente**, 1:1, 1254×1254 px (mesmo tamanho da `discovery.png`). Se o gerador só exportar 1024×1024, tudo bem: o `IllustrationCard` ajusta, mas use o mesmo tamanho nas duas novas.
- **Peso:** abaixo de 300 KB depois de otimizar.
- **Estilo observado na `discovery.png`:** vetor plano, formas arredondadas, contorno navy grosso e uniforme, preenchimentos chapados em dourado, cinza-claro de fundo (prédios e árvores) e branco; um ramo dourado de folhas grande no canto superior direito; selos circulares dourados com check branco; sombra de chão cinza elíptica e suave.

## `information.png`: "Entenda antes de escolher"

```text
Use the attached image as a strict style reference: same flat vector style,
same thick uniform deep navy outline, same flat fills, same level of detail,
same composition density. The new image must look like part of the same series.

Strict color palette: deep navy blue (#263D4F), warm golden yellow (#D9A53A),
light warm gray (#E6E6E6 to #F2F2F2) and white only.

Scene: a large food package (a box or pouch, like the ones in the reference)
turned slightly to show its back label, where the label is represented only by
abstract horizontal lines of different lengths, nothing readable. A large navy
magnifying glass with a golden ring at the handle (same design as in the
reference) is held over the label, enlarging two of those lines. Beside the
package, a navy clipboard with three short abstract checklist rows, each with
a round golden badge containing a white check mark (same badge style as in the
reference). In the soft light-gray background, a simplified café counter or
shelf silhouette, like the light-gray buildings in the reference.
A large, elegant golden leaf branch decorates the top right corner,
identical in style to the reference.
A soft light-gray elliptical ground shadow under the objects.

Meaning: reading and understanding food information before choosing.
Calm, trustworthy and informative mood.

Composition: subject centered, generous empty space around it,
transparent background, square 1:1.
Do not include: any readable text, letters, numbers, logos, real brands,
bread, wheat ears or grain, prohibition or warning signs, photorealism,
gradients, background fill.
```

## `profile.png`: "Uma experiência mais relevante"

```text
Use the attached image as a strict style reference: same flat vector style,
same thick uniform deep navy outline, same flat fills, same level of detail,
same composition density. The new image must look like part of the same series.

Strict color palette: deep navy blue (#263D4F), warm golden yellow (#D9A53A),
light warm gray (#E6E6E6 to #F2F2F2) and white only.

Scene: a large rounded smartphone outline in navy, standing upright, showing
a simple profile screen: a round avatar silhouette at the top, and below it
two rows with toggle switches (the first switched on in golden yellow, the
second switched off in light gray) next to short abstract lines instead of
text. Floating beside the phone, two of the same round golden badges with a
white check mark used in the reference, a small golden heart and two small
sparkles. At the bottom right, two small food packages like the ones in the
reference, one with a golden check badge, suggesting that suitable options
are shown first. In the soft light-gray background, rounded abstract shapes
and simplified trees like in the reference.
A large, elegant golden leaf branch decorates the top right corner,
identical in style to the reference.
A soft light-gray elliptical ground shadow under the objects.

Meaning: a personalized experience that adapts to each person's dietary needs.
Warm, personal and caring mood.

Composition: subject centered, generous empty space around it,
transparent background, square 1:1.
Do not include: any readable text, letters, numbers, logos, real brands,
bread, wheat ears or grain, prohibition or warning signs, a real person's face,
photorealism, gradients, background fill.
```

## Se sair inconsistente

Na mesma conversa, depois da primeira aprovada:

```text
Keep exactly the same illustration style, outline thickness, color palette,
golden leaf branch and badge design as the reference image, so the three
images look like one series. Only change the scene.
```

Se o fundo vier branco em vez de transparente, remova o fundo (ex.: `rembg`, Photoshop, remove.bg) e confira as bordas sobre um fundo escuro antes de usar.
