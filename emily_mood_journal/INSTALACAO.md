# Instruções de Instalação - MoodJournal

## Pré-requisitos

Para executar o MoodJournal, você precisa ter o Flutter instalado em sua máquina.

### Instalando o Flutter

1. **Baixe o Flutter SDK**

   - Acesse: https://flutter.dev/docs/get-started/install
   - Baixe a versão mais recente do Flutter SDK para Windows

2. **Extraia o arquivo**

   - Extraia o arquivo baixado para uma pasta (ex: `C:\flutter`)

3. **Adicione ao PATH**

   - Abra as Variáveis de Ambiente do Windows
   - Adicione `C:\flutter\bin` ao PATH do sistema
   - Reinicie o terminal/PowerShell

4. **Verifique a instalação**
   ```bash
   flutter doctor
   ```

### Executando o Projeto

1. **Navegue até o diretório do projeto**

   ```bash
   cd C:\Users\Vitor\Documents\GitHub\MoodJournal
   ```

2. **Instale as dependências**

   ```bash
   flutter pub get
   ```

3. **Execute o projeto**
   ```bash
   flutter run
   ```

### Requisitos Adicionais

- **Android Studio** (para desenvolvimento Android)
- **VS Code** com extensão Flutter (recomendado)
- **Git** (para controle de versão)

### Solução de Problemas

Se encontrar erros:

1. **Flutter não reconhecido**

   - Verifique se o Flutter está no PATH
   - Reinicie o terminal após adicionar ao PATH

2. **Erro de dependências**

   ```bash
   flutter clean
   flutter pub get
   ```

3. **Problemas de build**
   ```bash
   flutter doctor
   ```
   Siga as instruções para resolver problemas de configuração.

### Estrutura do Projeto

O projeto está organizado da seguinte forma:

```
MoodJournal/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── services/
│   ├── screens/
│   ├── widgets/
│   └── theme/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### Funcionalidades Implementadas

✅ Interface principal com seletor de humor
✅ Armazenamento local de dados
✅ Histórico de entradas
✅ Meta diária configurável
✅ Tema personalizado (Rose, Indigo, Surface)
✅ Navegação entre telas
✅ Exclusão de entradas
✅ Validação de dados

### Próximos Passos

Após a instalação, você pode:

1. Executar o projeto em um emulador Android
2. Executar em um dispositivo físico
3. Personalizar o tema e cores
4. Adicionar novas funcionalidades

