# Lan Party Planner

Um aplicativo Flutter para organizar mini-eventos gamers de forma fácil, rápida e segura.

## Funcionalidades

- **Onboarding interativo:** Apresentação do app, consentimento de privacidade e marketing.
- **Gestão de eventos:** Crie, edite e exclua eventos gamers com checklist e horários.
- **Consentimento e privacidade:** Leitura e aceite de Termos de Uso e Política de Privacidade, com opção de revogação.
- **Armazenamento local:** Todos os dados são salvos localmente no dispositivo.
- **Design moderno:** Interface escura, botões customizados e navegação intuitiva.

## Estrutura de Pastas

```
lib/
  core/           # Tema, utilitários
  models/         # Modelos de dados (ex: Event)
  services/       # Serviços de armazenamento
  features/       # Telas e fluxos principais (onboarding, eventos, consentimento, home)
  widgets/        # Componentes reutilizáveis
  assets/         # Imagens e arquivos .md
```

## Como rodar o projeto

1. **Clone o repositório:**
   ```sh
   git clone https://github.com/PabloEC382/LanParty-Planner.git
   cd LanParty-Planner/lan_party_planner
   ```

2. **Instale as dependências:**
   ```sh
   flutter pub get
   ```

3. **Execute o app:**
   ```sh
   flutter run
   ```

## Configuração de assets

Certifique-se de que o arquivo `pubspec.yaml` contém:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/PNGs/logoIASemfundo.png
    - assets/PNGs/logoIA.png
    - assets/privacidade.md
    - assets/termos.md
```

## Telas principais

- **Onboarding:** Apresentação, consentimento de marketing, leitura de termos e política.
- **Home:** Lista de eventos, botões para CRUD e revogação de consentimento.
- **CRUD de eventos:** Cadastro e edição de eventos com checklist.
- **Histórico de consentimento:** Visualização e revogação do consentimento.

## Tecnologias utilizadas

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [intl](https://pub.dev/packages/intl)
- [crypto](https://pub.dev/packages/crypto)

## Licença

Este projeto não tem liçenca.

## Contribuidores

Desenvolvido por Pablo Emanuel Cechim de Lima
