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
| 5 | [Favoritos, SQLite e Provider](docs/tutorials/CeliLac_Favoritos_SQLite_e_Provider.md) | Persistência relacional com `sqflite`, migração de esquema (`onUpgrade`), `MultiProvider` e sincronização entre Home, Detalhe e aba Favoritos |
| 6 | [Explorar: busca, filtros e ordenação](docs/tutorials/CeliLac_Explorar_Busca_e_Filtros.md) | Consulta imutável, função pura de filtragem, estado derivado de três fontes, *debounce*, filtros acessíveis e integração Home ↔ Explorar |

O [roteiro de implementação do Perfil Alimentar](docs/tutorials/CeliLac_Perfil_Alimentar_Roteiro.md) registra o plano e as decisões tomadas durante a implementação do material 4, e o documento [Base para Slides — Favoritos, SQLite e Provider](docs/tutorials/CeliLac_Favoritos_SQLite_e_Provider_Slides.md) estrutura os problemas, soluções e opções da etapa 5 para apresentação em aula.

Cada etapa maior também tem um **laboratório sequencial** (um conceito por vez, com guia e slides por degrau): [Favoritos](docs/tutorials/lab_favoritos_sqlite_provider/README.md) e [Explorar](docs/tutorials/lab_explorar_busca_filtros/README.md). A base de slides da etapa 6 está em [CeliLac_Explorar_Busca_e_Filtros_Slides.md](docs/tutorials/CeliLac_Explorar_Busca_e_Filtros_Slides.md).

## Organização

```text
lib/
├── app/          tema, tokens, shell de navegação, rotas e widgets compartilhados
└── features/     uma pasta por assunto (startup, onboarding, home, establishments, profile, favorites, explore)
    └── <feature>/
        ├── domain/        entidades e contratos, sem Flutter
        ├── data/          implementações (fake, armazenamento local)
        └── presentation/  páginas e widgets
```

Os dados dos estabelecimentos são fictícios (`FakeEstablishmentRepository`), e as imagens foram geradas por IA.
