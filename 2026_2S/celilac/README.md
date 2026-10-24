# CeliLac

Aplicativo Flutter para encontrar estabelecimentos e produtos adequados a quem precisa evitar glúten e lactose. Projeto didático: cada etapa do app é acompanhada de um material passo a passo em `docs/tutorials/`.

## Como rodar

Feito com Flutter 3.47 / Dart 3.13.

```bash
flutter pub get
flutter run
```

Qualidade:

```bash
flutter analyze
flutter test
```

## Materiais (ordem de leitura)

| # | Material | O que constrói |
|---|---|---|
| 1 | [Splash e Onboarding](docs/tutorials/CeliLac_Splash_e_Onboarding.md) | Identidade visual, splash nativa e animada, onboarding com persistência |
| 2 | [Homepage](docs/tutorials/CeliLac_HomePage.md) | Tema e tokens, domínio e repositório, shell de navegação, estados de carregamento, acessibilidade, testes |
| 3 | [Detalhe do Estabelecimento](docs/tutorials/CeliLac_Detalhe_Estabelecimento.md) | Navegação com dados, `Hero`, horários, imagens, ações externas, testes |
| 4 | [Perfil Alimentar](docs/tutorials/CeliLac_Perfil_Alimentar.md) | Formulários, persistência em JSON, estado compartilhado entre telas, Home personalizada |

O [roteiro de implementação do Perfil Alimentar](docs/tutorials/CeliLac_Perfil_Alimentar_Roteiro.md) registra o plano e as decisões tomadas durante a implementação, e serviu de base para o material 4.

## Organização

```text
lib/
├── app/          tema, tokens, shell de navegação, rotas e widgets compartilhados
└── features/     uma pasta por assunto (startup, onboarding, home, establishments)
    └── <feature>/
        ├── domain/        entidades e contratos, sem Flutter
        ├── data/          implementações (fake, armazenamento local)
        └── presentation/  páginas e widgets
```

Os dados dos estabelecimentos são fictícios (`FakeEstablishmentRepository`), e as imagens foram geradas por IA.
