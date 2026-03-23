# MoodJournal

Um diário de humor e bem-estar desenvolvido em Flutter para estudantes com rotina intensa.

## Características

- 🎨 Interface minimalista e moderna
- 🔒 Foco na privacidade dos dados
- 📱 Experiência otimizada para dispositivos móveis
- 📊 Acompanhamento do humor ao longo do tempo
- 🎯 Meta diária de check-in
- 📝 Histórico completo de entradas

## Paleta de Cores

- **Rose**: #E11D48 (cor principal)
- **Indigo**: #4338CA (cor secundária)
- **Surface**: #FAFAFA (cor de fundo)

## Como Executar

1. Certifique-se de ter o Flutter instalado em sua máquina
2. Clone este repositório
3. Navegue até o diretório do projeto
4. Execute os seguintes comandos:

```bash
flutter pub get
flutter run
```

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── models/
│   └── mood_entry.dart      # Modelo de dados para entradas de humor
├── services/
│   └── mood_storage.dart    # Serviço de armazenamento local
├── screens/
│   ├── home_screen.dart     # Tela principal
│   └── mood_history_screen.dart # Tela de histórico
├── widgets/
│   ├── mood_selector.dart   # Seletor de humor
│   ├── mood_card.dart       # Card de entrada de humor
│   └── daily_goal_card.dart # Card de meta diária
└── theme/
    └── app_theme.dart       # Configurações de tema
```

## Funcionalidades

### Tela Principal

- Seletor de humor com 5 opções (muito feliz, feliz, neutro, triste, muito triste)
- Indicação visual quando já foi registrado o humor do dia
- Card de meta diária configurável
- Lista das 3 entradas mais recentes

### Histórico

- Visualização de todas as entradas de humor
- Opção de excluir entradas
- Ordenação por data (mais recentes primeiro)

### Armazenamento

- Dados armazenados localmente no dispositivo
- Nenhum dado é enviado para servidores externos
- Backup automático via SharedPreferences

## Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento
- **Dart**: Linguagem de programação
- **SharedPreferences**: Armazenamento local
- **Material Design 3**: Design system

## Próximos Passos

- [ ] Adicionar notas personalizadas às entradas
- [ ] Implementar gráficos de evolução do humor
- [ ] Adicionar lembretes de check-in
- [ ] Implementar exportação de dados
- [ ] Adicionar temas personalizáveis

