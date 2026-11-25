# CeliLac com Supabase

## Trocando o catálogo falso pelo banco na nuvem, sem alterar nenhuma tela

---

## Como usar este material

Este é o **oitavo material** da série de construção do **CeliLac**. No anterior (*Introdução ao Supabase*), você criou o seu projeto no Supabase, as tabelas, as regras de segurança e as imagens, e consultou a API com `curl`. Agora o aplicativo passa a ler esse banco.

Desde o material da Home, as telas conversam com um **contrato**, `EstablishmentRepository`, e não com uma classe concreta. Até aqui, quem cumpria o contrato era o `FakeEstablishmentRepository`, com 12 lugares escritos no código. Este material escreve uma segunda implementação, o `SupabaseEstablishmentRepository`, e troca uma pela outra **na raiz de composição**. Home, Detalhe, Explorar e Favoritos não mudam uma linha.

Este material tem **quatro objetivos**:

1. Conectar o Flutter ao Supabase com **as chaves fora do código** e fora do Git.
2. Converter o JSON da API para as entidades do domínio, numa camada isolada e testável.
3. Fazer as **falhas reais de rede** (sem internet, servidor mudo, projeto pausado) chegarem às telas de erro que já existem.
4. Testar tudo isso **sem internet**, com um servidor falso.

Duas marcações aparecem ao longo do texto:

- **No CeliLac** — o que fazemos neste projeto.
- **No seu projeto** — como adaptar a mesma decisão para outro domínio.

### Pré-requisitos

- O material 7 concluído: **seu** projeto Supabase com o `01_schema.sql`, o `02_seed.sql` e as imagens no *bucket* `establishments`.
- A **Project URL** e a **chave pública** (*publishable* ou *anon*) anotadas. A chave **secreta** não é usada em nenhum momento.
- O CeliLac até o material 6 (Explorar), rodando com `flutter analyze` e `flutter test` limpos.

### Ao final deste material, você será capaz de

1. Instalar e inicializar o `supabase_flutter`.
2. Passar configuração ao aplicativo com `--dart-define-from-file`, sem versionar chaves.
3. Fazer consultas com `select`, `order`, `eq` e `maybeSingle`, incluindo **dados embutidos** de tabelas filhas.
4. Converter `snake_case`, `enum`, `numeric`, `time` e caminhos do Storage em entidades Dart.
5. Definir um **contrato de erro**: o que vira `null` e o que vira exceção.
6. Configurar *timeout* e novas tentativas automáticas, e explicar por que são necessários.
7. Migrar dados locais quando os identificadores do servidor mudam.
8. Testar um repositório remoto com um `SupabaseClient` real e um HTTP falso (`MockClient`).

### Arquivos desta etapa

| Arquivo | Situação | Papel |
|---|---|---|
| `pubspec.yaml` | alterado | `supabase_flutter`, e `http` só para testes |
| `supabase.example.json` | **novo** | modelo de configuração, versionado |
| `supabase.json` | **novo, fora do Git** | a URL e a chave pública de **cada aluno** |
| `.gitignore` | alterado | ignora `supabase.json` |
| `.vscode/launch.json` | alterado | o F5 passa o `supabase.json` |
| `android/app/src/main/AndroidManifest.xml` | alterado | permissão de internet para o APK de *release* |
| `macos/Runner/*.entitlements` | alterados | permissão de rede de saída no macOS |
| `lib/app/config/supabase_config.dart` | **novo** | lê e valida a configuração |
| `lib/main.dart` | alterado | `Supabase.initialize` e escolha do repositório |
| `lib/app/celilac_app.dart` | alterado | recebe o repositório e o expõe no `MultiProvider` |
| `lib/app/shell/app_shell.dart` | alterado | lê o repositório do contexto, em vez de criar o *fake* |
| `lib/features/establishments/domain/repositories/establishment_repository.dart` | alterado | documenta o contrato e define a exceção |
| `lib/features/establishments/data/establishment_json.dart` | **novo** | JSON da API → entidades |
| `lib/features/establishments/data/supabase_establishment_repository.dart` | **novo** | as consultas |
| `lib/features/favorites/data/sqlite_favorites_repository.dart` | alterado | migração dos favoritos antigos (versão 3) |
| `test/support/supabase_api_json.dart` | **novo** | respostas da API usadas nos testes |
| `test/features/establishments/establishment_json_test.dart` | **novo** | conversão |
| `test/features/establishments/supabase_establishment_repository_test.dart` | **novo** | consultas, `null` e erros |
| `test/app/supabase_config_test.dart` | **novo** | validação da configuração |
| `test/app/supabase_catalog_flow_test.dart` | **novo** | erro e "Tentar novamente" na Home, de ponta a ponta |

Nenhum arquivo em `presentation/` muda.

---

# Parte 0: Antes do código — o problema

## 0.1 Onde estamos

```text
HomePage ─┐
Explore ──┼──► EstablishmentRepository ◄── FakeEstablishmentRepository
Detalhe ──┘       (contrato)                (12 lugares no código)
```

O contrato tem dois métodos:

```dart
Future<List<Establishment>> fetchNearby();
Future<EstablishmentDetails?> fetchDetails(String establishmentId);
```

## 0.2 Onde queremos chegar

```text
HomePage ─┐                                  SupabaseEstablishmentRepository
Explore ──┼──► EstablishmentRepository ◄──       │  consultas (select, eq…)
Detalhe ──┘                                      │  conversão (establishment_json)
                                                 ▼
                                    API REST do SEU projeto Supabase
```

## 0.3 Os quatro problemas desta etapa

| Problema | Pergunta | Onde resolvemos |
|---|---|---|
| **Chaves** | Como o aplicativo conhece a URL e a chave sem que elas fiquem no Git? | Parte 2 |
| **Formatos** | O banco fala `snake_case`, `text`, `numeric` e `time`; o Dart fala `camelCase`, `enum`, `double` e `Duration`. Quem traduz? | Parte 4 |
| **Falhas** | O *fake* nunca falhava. A internet falha o tempo todo. As telas estão prontas para isso? | Partes 5 e 7 |
| **Ids antigos** | Os favoritos salvos têm ids `'1'..'12'`, e o banco usa uuids. O que fazer com eles? | Parte 8 |

## 0.4 A regra que guia tudo: a tela não pode saber

Se a `HomePage` importasse `supabase_flutter`, trocar de servidor (ou testar sem internet) exigiria mudar a tela. Por isso, **tudo o que é Supabase fica em `data/`** e na raiz de composição (`main.dart`). As telas continuam recebendo um `EstablishmentRepository` e tratando duas situações que já conhecem: **dados** ou **exceção**.

---

# Parte 1: Dependências e plataforma

## 1.1 Instalando os pacotes

```bash
flutter pub add supabase_flutter dev:http
```

Resultado no `pubspec.yaml`:

```yaml
dependencies:
  # ...
  supabase_flutter: ^2.18.3

dev_dependencies:
  # ...
  http: ^1.6.0
```

| Pacote | Para quê |
|---|---|
| `supabase_flutter` | o *client* oficial: banco (PostgREST), Storage, Auth etc. Ele traz o pacote `supabase` |
| `http` (dev) | só para os testes: o `MockClient` faz o papel do servidor (Parte 9) |

> **Por que declarar `http` se ele já vem junto com o Supabase?** Porque os testes o importam diretamente (`package:http/testing.dart`). O *lint* `depend_on_referenced_packages` exige que todo pacote importado esteja no `pubspec.yaml`, e não apenas presente como dependência de outro.

## 1.2 Permissão de internet no Android

Abra `android/app/src/main/AndroidManifest.xml`. Até aqui, o CeliLac nunca acessou a rede, e a permissão **não estava** lá. Ela só aparecia nos manifestos `debug/` e `profile/`, que o Flutter cria para o *hot reload*.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- O catálogo vem do Supabase. Sem esta linha, o APK de release não
         acessa a internet (debug e profile já a declaram nos seus manifestos). -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
```

> **Armadilha clássica:** tudo funciona com `flutter run` (*debug*), mas o APK de *release*, instalado no celular de alguém, mostra "Não foi possível carregar os estabelecimentos". O motivo é a falta da permissão no manifesto `main/`.

## 1.3 Permissão de rede no macOS

Se você roda o aplicativo como aplicativo de macOS, a *sandbox* da Apple bloqueia conexões de saída. Acrescente em `macos/Runner/DebugProfile.entitlements` **e** em `macos/Runner/Release.entitlements`:

```xml
	<key>com.apple.security.network.client</key>
	<true/>
```

iOS, Android (com a permissão acima) e Web não precisam de mais nada para acessar URLs `https://`.

---

# Parte 2: Chaves fora do código

## 2.1 O que pode ir no aplicativo

Revisão do material 7:

| Credencial | No aplicativo? |
|---|---|
| Project URL | sim |
| Chave **pública** (*publishable* / *anon*) | sim: ela só pode o que o RLS deixa |
| Chave **secreta** (*secret* / *service_role*) | **nunca**: ela ignora o RLS |

A chave pública **pode** estar dentro do aplicativo instalado. Mesmo assim, **não** a colocamos no código-fonte, por dois motivos:

1. **Cada aluno tem o seu projeto.** Se a URL estivesse no código, todo `git pull` traria a URL de outra pessoa.
2. **Hábito.** Quem aprende a escrever `const key = '...'` no código vai fazer o mesmo, um dia, com uma chave secreta.

## 2.2 `--dart-define-from-file`

O Flutter aceita valores na **compilação**:

```bash
flutter run --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co \
            --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Como digitar isso toda vez é cansativo, usamos um arquivo JSON:

```bash
flutter run --dart-define-from-file=supabase.json
```

No código, cada valor é lido com `String.fromEnvironment`, que devolve `''` (texto vazio) se ninguém o passou.

> **`--dart-define` não é segredo.** O valor é gravado **dentro** do aplicativo compilado, e quem desmontar o APK o encontra. Isso é aceitável para a chave pública, e é exatamente por isso que a chave secreta não pode passar por aqui. O objetivo do `--dart-define` é manter a chave **fora do Git**, não escondê-la do usuário.

## 2.3 Os arquivos

**No CeliLac**, o modelo é versionado:

`supabase.example.json`

```json
{
  "SUPABASE_URL": "https://SEU-PROJETO.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_COLE_AQUI_A_CHAVE_PUBLICA"
}
```

Cada aluno copia o modelo e preenche com os **próprios** valores:

```bash
cp supabase.example.json supabase.json
```

O arquivo real fica fora do Git. No início do `.gitignore`:

```gitignore
# Supabase: URL e chave pública de cada aluno (modelo em supabase.example.json)
supabase.json
```

Confira antes do primeiro *commit*:

```bash
git check-ignore -v supabase.json   # deve mostrar a regra do .gitignore
git status                          # supabase.json NÃO pode aparecer
```

## 2.4 O F5 do VS Code

Em `.vscode/launch.json`, cada configuração ganha `toolArgs`:

```json
{
  "name": "celilac (debug)",
  "request": "launch",
  "type": "dart",
  "program": "lib/main.dart",
  "toolArgs": [
    "--dart-define-from-file=supabase.json"
  ]
}
```

O mesmo vale para as configurações `profile` e `release`.

## 2.5 Validando a configuração: `SupabaseConfig`

Um erro de configuração (variável esquecida, URL sem `https://`, chave errada) deve aparecer **na hora de abrir o aplicativo**, com uma mensagem clara, e não como um "Não foi possível carregar" misterioso.

`lib/app/config/supabase_config.dart`

```dart
import 'dart:convert';

/// Endereço e chave pública do projeto Supabase, lidos na compilação.
///
/// Os valores vêm de `--dart-define-from-file=supabase.json` (ou de
/// `--dart-define`), nunca do código-fonte: assim cada aluno usa o próprio
/// projeto e nenhuma chave vai para o Git.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  /// Lê os valores passados por `--dart-define`. Vazios se ninguém passou.
  factory SupabaseConfig.fromEnvironment() {
    return const SupabaseConfig(
      url: String.fromEnvironment('SUPABASE_URL'),
      publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    );
  }

  final String url;
  final String publishableKey;

  /// A URL sem a barra final: `https://x.supabase.co/` vira
  /// `https://x.supabase.co`, e o client não monta `//rest/v1`.
  String get normalizedUrl =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// O que impede a conexão. Lista vazia quando está tudo certo.
  List<String> get problems => [
    if (url.isEmpty)
      'SUPABASE_URL não foi definida.'
    else if (!url.startsWith('https://'))
      'SUPABASE_URL deve começar com https://.',
    if (publishableKey.isEmpty)
      'SUPABASE_PUBLISHABLE_KEY não foi definida.'
    else if (_isSecretKey(publishableKey))
      'SUPABASE_PUBLISHABLE_KEY recebeu a chave SECRETA. Use a chave pública '
          '(publishable ou anon) e gere uma nova chave secreta no painel.',
  ];

  /// Reconhece os dois formatos de chave secreta: o novo (`sb_secret_...`) e
  /// o antigo, um JWT cujo conteúdo diz `"role": "service_role"`.
  static bool _isSecretKey(String key) {
    if (key.startsWith('sb_secret_')) {
      return true;
    }
    final parts = key.split('.');
    if (parts.length != 3) {
      return false;
    }
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return (jsonDecode(payload) as Map<String, dynamic>)['role'] ==
          'service_role';
    } on FormatException {
      return false;
    }
  }
}
```

### Conceitos

- **`String.fromEnvironment` precisa de contexto `const`.** O valor é resolvido na compilação, por isso a *factory* devolve um `const SupabaseConfig(...)`.
- **Separar a leitura da validação.** `fromEnvironment()` só lê, e `problems` só valida. Assim, o teste cria `SupabaseConfig(url: '', ...)` diretamente, sem precisar de `--dart-define`.
- **`if`/`else` dentro de uma lista.** As *collection-ifs* do Dart montam a lista de problemas sem nenhuma variável temporária.
- **Reconhecer a chave secreta antiga.** As chaves antigas (`anon` e `service_role`) são **JWTs**: três partes separadas por ponto, e a do meio é um JSON em Base64 que diz o papel (`role`). Ler esse JSON não exige a assinatura. É só uma checagem de segurança, e não autentica nada.

> **Este é um cinto de segurança, não uma garantia.** Ele pega o erro mais comum (colar a chave errada). Mas se a chave secreta já foi parar num APK distribuído ou num *commit*, ela está **comprometida**: gere uma nova no painel e revogue a antiga.

---

# Parte 3: Inicializando o Supabase no `main`

`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/celilac_app.dart';
import 'app/config/supabase_config.dart';
import 'features/establishments/data/supabase_establishment_repository.dart';

Future<void> main() async {
  // Necessário antes de qualquer plugin (o Supabase guarda a sessão no aparelho).
  WidgetsFlutterBinding.ensureInitialized();

  final config = SupabaseConfig.fromEnvironment();
  final problems = config.problems;
  if (problems.isNotEmpty) {
    throw StateError(
      'Configuração do Supabase incompleta:\n'
      '- ${problems.join('\n- ')}\n'
      'Rode com: flutter run --dart-define-from-file=supabase.json '
      '(modelo em supabase.example.json).',
    );
  }

  await Supabase.initialize(
    url: config.normalizedUrl,
    publishableKey: config.publishableKey,
  );

  runApp(
    CeliLacApp(
      // A troca do fake pelo Supabase acontece só nesta linha.
      establishmentRepository: SupabaseEstablishmentRepository(
        Supabase.instance.client,
      ),
    ),
  );
}
```

### Conceitos

- **`main` assíncrono.** `Supabase.initialize` devolve um `Future`, e o `main` espera por ele antes do `runApp`.
- **`WidgetsFlutterBinding.ensureInitialized()`.** Plugins (o Supabase usa armazenamento local para a sessão de login) só funcionam depois que o Flutter está ligado. Sem essa linha, o `initialize` falha.
- **`publishableKey`.** Nas versões atuais do `supabase_flutter`, o parâmetro antigo `anonKey` está marcado como obsoleto. Os dois aceitam qualquer uma das chaves públicas.
- **Falhar cedo (*fail fast*).** Sem configuração, o aplicativo **não abre**, e o terminal mostra exatamente o que falta. Não há "volta silenciosa" para o *fake*: ela esconderia o erro, e você passaria horas se perguntando por que os dados nunca mudam.
- **`Supabase.initialize` não acessa o banco.** Ele só prepara o *client*. A primeira chamada de rede acontece quando a Home pede `fetchNearby()`. Por isso, um celular sem internet **abre** o aplicativo normalmente e vê a tela de erro da Home, em vez de travar na Splash.

> **No seu projeto:** a regra é a mesma para qualquer serviço (Firebase, uma API própria): **configuração de fora, validada no início, com mensagem útil.**

---

# Parte 4: Do JSON às entidades (`establishment_json.dart`)

## 4.1 O mesmo padrão dos favoritos

No material 5, `favorite_establishment_row.dart` isolou a tradução entre `Establishment` e uma linha do SQLite. Fazemos o mesmo para a API: **um arquivo, em `data/`, só com funções de conversão**, sem rede, sem Supabase e sem Flutter. Por isso ele é trivial de testar.

## 4.2 O que precisa ser traduzido

Compare a resposta da API (material 7, Parte 8.2) com a entidade:

| JSON da API | Tipo no JSON | Entidade | Tipo no Dart | Conversão |
|---|---|---|---|---|
| `id` | texto (uuid) | `id` | `String` | nenhuma |
| `category` | texto `'cafe'` | `category` | `EstablishmentCategory` | `values.byName` |
| `distance_in_km` | número `0.35` | `distanceInKm` | `double` | `(x as num).toDouble()` |
| `rating` | número `4.8` | `rating` | `double` | `(x as num).toDouble()` |
| `dietary_options` | lista de textos | `dietaryOptions` | `Set<DietaryOption>` | `byName` em cada item |
| `logo_path` | texto ou `null` | `logoSource` | `String?` | caminho → URL pública |

E no detalhe (Parte 8.4):

| JSON da API | Forma | Entidade | Conversão |
|---|---|---|---|
| `establishment_details` | **objeto** ou `null` (1:1) | campos de `EstablishmentDetails` | `null` → sem detalhes |
| `opening_hours` | **lista** (1:N) | `List<OpeningHours>` | `"07:00:00"` → `Duration` e ordenação |
| `establishment_photos` | **lista** (1:N) | `List<EstablishmentPhoto>` | ordenação por `position`, caminho → URL |
| `safety_practices` | lista de textos | `Set<SafetyPractice>` | `byName` |

## 4.3 O arquivo completo

`lib/features/establishments/data/establishment_json.dart`

```dart
import '../domain/entities/dietary_option.dart';
import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_category.dart';
import '../domain/entities/establishment_details.dart';
import '../domain/entities/establishment_photo.dart';
import '../domain/entities/opening_hours.dart';
import '../domain/entities/safety_practice.dart';

/// Transforma um caminho do Storage (`cafe_aconchego/logo.png`) na URL
/// pública do arquivo. Quem sabe montar a URL é o client do Supabase.
typedef PublicUrlBuilder = String Function(String storagePath);

/// Uma linha de `establishments`, como a API REST devolve.
Establishment establishmentFromJson(
  Map<String, dynamic> json, {
  required PublicUrlBuilder publicUrl,
}) {
  return Establishment(
    id: json['id'] as String,
    name: json['name'] as String,
    // byName: o banco só aceita os nomes dos enums (check), então um valor
    // desconhecido é erro de versão, não algo a esconder.
    category: EstablishmentCategory.values.byName(json['category'] as String),
    neighborhood: json['neighborhood'] as String,
    // numeric chega como número no JSON, mas 5.0 pode chegar como 5 (int).
    distanceInKm: (json['distance_in_km'] as num).toDouble(),
    rating: (json['rating'] as num).toDouble(),
    dietaryOptions: {
      for (final name in json['dietary_options'] as List<dynamic>)
        DietaryOption.values.byName(name as String),
    },
    logoSource: _publicUrlOrNull(json['logo_path'], publicUrl),
  );
}

/// Uma linha de `establishments` com as tabelas filhas embutidas:
/// `establishment_details` (objeto, 1:1), `opening_hours` e
/// `establishment_photos` (listas, 1:N).
///
/// Devolve `null` quando o lugar existe mas não tem detalhes cadastrados.
EstablishmentDetails? establishmentDetailsFromJson(
  Map<String, dynamic> json, {
  required PublicUrlBuilder publicUrl,
}) {
  final details = json['establishment_details'] as Map<String, dynamic>?;
  if (details == null) {
    return null;
  }

  final hours = [
    for (final row in json['opening_hours'] as List<dynamic>)
      _openingHoursFromJson(row as Map<String, dynamic>),
  ];
  // A API não garante a ordem das linhas embutidas: ordenamos aqui.
  hours.sort((a, b) {
    final byDay = a.weekday.compareTo(b.weekday);
    return byDay != 0 ? byDay : a.opensAt.compareTo(b.opensAt);
  });

  final photoRows = [
    for (final row in json['establishment_photos'] as List<dynamic>)
      row as Map<String, dynamic>,
  ]..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  return EstablishmentDetails(
    establishmentId: json['id'] as String,
    description: details['description'] as String,
    address: details['address'] as String,
    phone: details['phone'] as String?,
    openingHours: hours,
    safetyPractices: {
      for (final name in details['safety_practices'] as List<dynamic>)
        SafetyPractice.values.byName(name as String),
    },
    photos: [
      for (final row in photoRows)
        EstablishmentPhoto(
          source: publicUrl(row['path'] as String),
          description: row['description'] as String,
        ),
    ],
  );
}

/// Converte um `time` do Postgres (`"07:00:00"`, `"06:30"`, `"24:00:00"`)
/// para o tempo desde a meia-noite.
Duration durationFromPostgresTime(String value) {
  final match = _timePattern.firstMatch(value);
  if (match == null) {
    throw FormatException('Horário inválido', value);
  }
  return Duration(
    hours: int.parse(match.group(1)!),
    minutes: int.parse(match.group(2)!),
    seconds: int.parse(match.group(3) ?? '0'),
  );
}

// HH:MM, com segundos e frações de segundo opcionais (as frações são ignoradas).
final RegExp _timePattern = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?$');

OpeningHours _openingHoursFromJson(Map<String, dynamic> json) {
  return OpeningHours(
    weekday: json['weekday'] as int,
    opensAt: durationFromPostgresTime(json['opens_at'] as String),
    closesAt: durationFromPostgresTime(json['closes_at'] as String),
  );
}

String? _publicUrlOrNull(Object? path, PublicUrlBuilder publicUrl) {
  return switch (path) {
    final String value when value.trim().isNotEmpty => publicUrl(value),
    _ => null,
  };
}
```

## 4.4 As decisões, uma a uma

### `byName` estrito, e não um palpite

No material 5, `establishmentFromRow` era **tolerante**: uma categoria desconhecida virava `restaurant`, e uma opção desconhecida era ignorada. Fazia sentido ali, porque os dados eram **cópias antigas** gravadas pelo próprio aparelho.

Aqui é diferente. O banco tem um `check` que só aceita os nomes dos `enum`. Se aparecer `'bar'`, **o banco e o aplicativo estão em versões diferentes** (alguém acrescentou uma categoria no servidor antes de publicar o aplicativo). Escolher `restaurant` em silêncio mostraria uma informação **errada** para uma pessoa com restrição alimentar. `byName` lança `ArgumentError`, o repositório transforma isso em falha (Parte 5), e a tela mostra o erro.

> **No seu projeto:** decida caso a caso. Um rótulo decorativo pode ter um valor padrão. Um dado de **segurança** (alergênicos, dosagem, preço) deve falhar alto.

### `numeric` → `double`

O PostgREST devolve `numeric` como **número** no JSON (`4.8`). Mas o `jsonDecode` do Dart transforma `5` (sem casas decimais) em `int`, e `json['rating'] as double` quebraria. `(x as num).toDouble()` aceita os dois. É o mesmo cuidado que o SQLite exigiu no material 5.

### `time` → `Duration`

O Postgres manda o horário como texto: `"07:00:00"`. A expressão regular aceita `HH:MM`, `HH:MM:SS` e frações de segundo (`"08:15:30.250"`), e recusa o resto com `FormatException`. `24:00:00` é um `time` válido no Postgres ("fim do dia") e vira `Duration(hours: 24)`, que o `OpeningHours.contains` já entende.

### Ordenar no aplicativo

A API **não garante a ordem** das linhas embutidas (`opening_hours`, `establishment_photos`). Sem ordenação, o carrossel poderia começar pela foto 3, e um restaurante com almoço e jantar poderia mostrar "19:00" antes de "11:30". Ordenar na conversão é simples e funciona com qualquer servidor.

> Daria para pedir a ordem ao servidor (`.order('position', referencedTable: 'establishment_photos')`). Preferimos a conversão porque ela é **testável sem rede** e não depende de quem montou a consulta lembrar disso.

### Caminho → URL: quem monta é o *client*

A conversão recebe uma **função** `publicUrl` em vez de conhecer o Supabase. No aplicativo, essa função é `client.storage.from('establishments').getPublicUrl(path)`. No teste, é uma função de uma linha. O `getPublicUrl` **não acessa a rede**: ele só monta o texto `https://<projeto>.supabase.co/storage/v1/object/public/establishments/<caminho>`.

### `null` em `establishment_details`

A relação é 0..1 (material 7, Parte 4.3). Um lugar pode existir sem detalhes cadastrados. Nesse caso, devolvemos `null`, que a tela de Detalhe já trata com "As informações deste lugar não estão mais disponíveis".

### Conceitos

- **Função de nível superior em `data/`:** sem estado, sem classe, sem dependências, só entrada e saída.
- **`typedef` para funções:** dá nome ao "tipo de função" e documenta a intenção.
- **Injeção de função:** passar `publicUrl` em vez de um objeto do Supabase é a forma mais leve de inversão de dependência.

---

# Parte 5: O repositório (`SupabaseEstablishmentRepository`)

## 5.1 O contrato, agora escrito

Antes, o contrato estava implícito nas telas. Agora ele fica documentado no próprio domínio:

`lib/features/establishments/domain/repositories/establishment_repository.dart`

```dart
import '../entities/establishment.dart';
import '../entities/establishment_details.dart';

/// O contrato do catálogo, igual para o fake e para o Supabase:
///
/// - um lugar que não existe devolve `null` em [fetchDetails];
/// - uma falha (sem rede, tempo esgotado, servidor fora, dado inesperado)
///   lança uma exceção, que as telas mostram com "Tentar novamente".
abstract interface class EstablishmentRepository {
  Future<List<Establishment>> fetchNearby();

  Future<EstablishmentDetails?> fetchDetails(String establishmentId);
}

/// Falha ao buscar o catálogo. Esconde das telas o tipo de erro de cada
/// tecnologia (Supabase, HTTP, JSON), mas guarda o original em [cause].
class EstablishmentRepositoryException implements Exception {
  const EstablishmentRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'EstablishmentRepositoryException: $message ($cause)';
}
```

| Situação | Resultado | O que o Detalhe mostra |
|---|---|---|
| o lugar existe | `EstablishmentDetails` | as informações |
| o lugar **não existe** | `null` | "não estão mais disponíveis" + **Voltar** |
| **falha** (rede, servidor, JSON) | exceção | "Não foi possível carregar" + **Tentar novamente** |

A distinção importa: "não existe" **não melhora** com uma nova tentativa, e "falhou" **pode** melhorar.

## 5.2 O arquivo completo

`lib/features/establishments/data/supabase_establishment_repository.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_details.dart';
import '../domain/repositories/establishment_repository.dart';
import 'establishment_json.dart';

/// Lê o catálogo do Supabase, pela API REST, com a chave pública.
///
/// Só leitura: o RLS do banco libera `select` e nada mais.
class SupabaseEstablishmentRepository implements EstablishmentRepository {
  SupabaseEstablishmentRepository(
    this._client, {
    this.requestTimeout = const Duration(seconds: 8),
    this.retryCount = 1,
  });

  final SupabaseClient _client;

  /// Quanto cada tentativa pode esperar. Sem limite, uma conexão travada
  /// deixaria a tela carregando para sempre.
  final Duration requestTimeout;

  /// Novas tentativas automáticas (sem internet, tempo esgotado, 503).
  /// Depois delas, a tela mostra o "Tentar novamente".
  final int retryCount;

  static const String imagesBucket = 'establishments';

  /// Colunas da lista: exatamente os campos de `Establishment`.
  static const String nearbyColumns =
      'id,name,category,neighborhood,distance_in_km,rating,'
      'dietary_options,logo_path';

  /// Detalhe em UMA chamada: a API embute as tabelas filhas pela chave
  /// estrangeira, sem escrevermos `join`.
  static const String detailsColumns =
      'id,'
      'establishment_details(description,address,phone,safety_practices),'
      'opening_hours(weekday,opens_at,closes_at),'
      'establishment_photos(position,path,description)';

  @override
  Future<List<Establishment>> fetchNearby() {
    return _guard('carregar os estabelecimentos', () async {
      final rows = await _client
          .from('establishments')
          .select(nearbyColumns)
          // Atenção: no Dart, order() é DECRESCENTE se nada for dito.
          .order('distance_in_km', ascending: true)
          .order('name', ascending: true)
          .retry(count: retryCount, requestTimeout: requestTimeout);
      return [
        for (final row in rows)
          establishmentFromJson(row, publicUrl: _publicUrl),
      ];
    });
  }

  @override
  Future<EstablishmentDetails?> fetchDetails(String establishmentId) async {
    // Um id que nem é uuid (como os '1'..'12' do fake) não pode existir no
    // banco. Sem este teste, o Postgres recusaria o filtro com erro 400, e a
    // tela mostraria "Tentar novamente" para algo que nunca vai funcionar.
    if (!_uuidPattern.hasMatch(establishmentId)) {
      return null;
    }

    return _guard('carregar o detalhe do estabelecimento', () async {
      final row = await _client
          .from('establishments')
          .select(detailsColumns)
          .eq('id', establishmentId)
          .maybeSingle() // zero linhas viram null, não erro
          .retry(count: retryCount, requestTimeout: requestTimeout);
      if (row == null) {
        return null;
      }
      return establishmentDetailsFromJson(row, publicUrl: _publicUrl);
    });
  }

  /// Monta a URL pública sem ir à rede: é só texto.
  String _publicUrl(String path) =>
      _client.storage.from(imagesBucket).getPublicUrl(path);

  /// Toda falha vira [EstablishmentRepositoryException]: rede, tempo
  /// esgotado, erro do servidor ou JSON diferente do esperado.
  Future<T> _guard<T>(String action, Future<T> Function() run) async {
    try {
      return await run();
    } catch (error, stackTrace) {
      debugPrint('Não foi possível $action: $error');
      Error.throwWithStackTrace(
        EstablishmentRepositoryException(
          'Não foi possível $action.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
```

## 5.3 Da URL do `curl` para o Dart

Cada trecho da cadeia de métodos corresponde a um parâmetro que você escreveu no material 7, Parte 8.3:

| Dart | Parâmetro na URL | SQL equivalente |
|---|---|---|
| `.from('establishments')` | `/rest/v1/establishments` | `from establishments` |
| `.select('id,name,…')` | `select=id,name,…` | `select id, name, …` |
| `.eq('id', x)` | `id=eq.x` | `where id = x` |
| `.order('distance_in_km', ascending: true)` | `order=distance_in_km.asc` | `order by distance_in_km` |
| `.select('id,opening_hours(…)')` | `select=id,opening_hours(…)` | um `join` feito pela API |
| `.maybeSingle()` | — | "no máximo uma linha" |

Os testes da Parte 9 conferem a URL que o aplicativo realmente envia.

## 5.4 Armadilha: `order()` é decrescente por padrão

No `curl`, `order=rating` é **crescente**. No Dart, `.order('distance_in_km')` sem mais nada gera `order=distance_in_km.desc.nullslast`, isto é, **do mais longe para o mais perto**. O parâmetro `ascending` vale `false` por padrão no pacote `postgrest`.

Foi o teste da Parte 9 que pegou isso durante a escrita deste material: o código parecia certo, mas a URL enviada mostrava `desc`. Por isso escrevemos sempre `ascending: true` explicitamente.

> **Repare:** o *fake* devolvia os lugares na ordem em que foram escritos (`'1'`, `'2'`…), e não por distância. Com o Supabase, a Home passa a mostrar "Perto de você" **de fato** do mais perto para o mais longe, como o comentário do `sortByProfile` já supunha ("dois filtros preservam a ordem por distância"). O desempate por `name` deixa a ordem estável quando duas distâncias são iguais.

## 5.5 `maybeSingle()`: zero linhas é `null`

Sem `maybeSingle()`, o filtro `id=eq.x` devolve uma **lista** (`[]` ou `[{...}]`). Com ele, o *client* devolve `null` para nenhuma linha, o objeto para uma linha e um erro para mais de uma (o que nunca acontece com a chave primária). É exatamente o "não existe → `null`" do contrato.

> Existe também `.single()`, que trata zero linhas como **erro**. Para o nosso contrato, ele estaria errado.

## 5.6 Por que validar o uuid antes de consultar

O id é `String` no domínio, mas a coluna é `uuid` no banco. Se o aplicativo pedir `id=eq.1`, o Postgres **não** responde "não achei", e sim "isso não é um uuid" (HTTP 400, código `22P02`). Esse erro chegaria à tela como **falha**, com o botão "Tentar novamente", que nunca resolveria.

Quando isso acontece? Exatamente com os **favoritos antigos** (Parte 8), cujos ids eram `'1'..'12'`. A expressão regular resolve sem ir à rede: um id que nem tem o formato de uuid **não pode existir**, então a resposta é `null`.

## 5.7 *Timeout* e novas tentativas: a política de rede

O *fake* respondia sempre, em 800 ms. A rede real tem três comportamentos ruins:

| Situação | Sem política | Com a política do CeliLac |
|---|---|---|
| sem internet | erro quase imediato | 1 nova tentativa após ~1 s, depois erro |
| servidor que não responde (rede travada) | **espera para sempre**: a Home fica no carregamento eterno | cada tentativa desiste em 8 s; erro em até ~17 s |
| 503 passageiro | erro | 1 nova tentativa automática |

O `.retry(count: …, requestTimeout: …)` vale **para aquela consulta**:

- **`requestTimeout`**: o tempo máximo de **cada** tentativa. O *client* **aborta** a conexão (não apenas para de esperar) e lança `TimeoutException`.
- **`count`**: quantas **novas** tentativas, para falhas de rede, tempo esgotado e os códigos 503 e 520. A espera entre elas cresce: 1 s, 2 s, 4 s…

> **Por que não configurar isso uma vez só, no `Supabase.initialize`?** O `initialize` aceita `postgrestOptions: PostgrestClientOptions(requestTimeout: …, retryCount: …)`. Mas, na versão usada aqui (`supabase` 2.16.5), **o `client.from(...)` não repassa essas opções** para a consulta: só o `client.rest` as respeita. Verificamos isso no código-fonte do pacote, e o teste de *timeout* da Parte 9 travaria se dependesse delas. Declarar a política na própria consulta funciona em qualquer versão e deixa visível, no repositório, quanto tempo uma tela pode esperar.
>
> Quando o pacote passar a repassar as opções, as duas formas convivem: o valor da consulta tem prioridade.

**Sem `requestTimeout`, não existe limite nenhum.** O padrão do pacote é esperar indefinidamente. Esquecer isso é o motivo número um de "o aplicativo ficou carregando e nunca mais saiu".

## 5.8 `_guard`: uma exceção só, com a causa guardada

As falhas chegam de muitos tipos:

| Origem | Tipo |
|---|---|
| sem internet | `ClientException` (pacote `http`) |
| tempo esgotado | `TimeoutException` |
| erro HTTP (401, 404, 5xx, página HTML) | `PostgrestException` |
| JSON fora do contrato | `ArgumentError`, `TypeError`, `FormatException` |

O `_guard` captura **todas** e lança uma só: `EstablishmentRepositoryException`. Isso tem três efeitos:

1. **As telas não importam `supabase_flutter`.** O tipo de erro que elas poderiam ver é do domínio.
2. **A causa não se perde.** O campo `cause` guarda a exceção original, e o `debugPrint` a mostra no terminal (`Invalid API key`, `Failed host lookup`…). Sem isso, a tela diria só "Não foi possível carregar", e você não saberia por quê.
3. **`Error.throwWithStackTrace`** relança com a **pilha original**, e o depurador aponta para onde o erro nasceu, não para o `_guard`.

> **E capturar `TypeError`, que normalmente é *bug*?** Neste ponto específico, um `TypeError` quase sempre significa "o JSON veio diferente do combinado" (uma coluna renomeada no banco, por exemplo). Para quem usa o aplicativo, isso é uma **falha do catálogo**, e a resposta certa é a tela de erro, não um aplicativo quebrado. A causa continua no `debugPrint` para quem desenvolve.

---

# Parte 6: A raiz de composição

## 6.1 O que é a "raiz de composição"

É o **único lugar** que conhece as classes concretas e as liga entre si. No CeliLac, são o `main.dart`, o `CeliLacApp` (o `MultiProvider`) e o `AppShell` (que monta as abas). Antes deste material, o `FakeEstablishmentRepository` aparecia em **dois** desses lugares: como padrão do `CeliLacApp` e três vezes no `AppShell`.

## 6.2 `CeliLacApp`: o repositório passa a ser obrigatório

`lib/app/celilac_app.dart` (trechos alterados)

```dart
class CeliLacApp extends StatelessWidget {
  const CeliLacApp({
    super.key,
    this.profileRepository,
    this.favoritesRepository,
    required this.establishmentRepository,
  });

  final ProfileRepository? profileRepository;
  final FavoritesRepository? favoritesRepository;

  /// De onde vem o catálogo. Quem decide é o `main` (Supabase) ou o teste
  /// (fake); nenhuma tela sabe qual é.
  final EstablishmentRepository establishmentRepository;

  @override
  Widget build(BuildContext context) {
    // Acima do MaterialApp: as rotas empilhadas também enxergam os
    // controladores, e o ChangeNotifierProvider cuida de criar e descartar.
    return MultiProvider(
      providers: [
        // Provider simples (não ChangeNotifier): o repositório não muda, só
        // precisa estar ao alcance do AppShell.
        Provider<EstablishmentRepository>.value(value: establishmentRepository),
        // ... ProfileController e FavoritesController sem mudança ...
        ChangeNotifierProvider<ExploreController>(
          create: (_) => ExploreController(establishmentRepository),
        ),
      ],
      // ... MaterialApp sem mudança ...
```

- **Por que `required`?** Um valor padrão (`?? const FakeEstablishmentRepository()`) faria o aplicativo de produção **depender do *fake***, e um esquecimento no `main` passaria despercebido. Com `required`, o compilador obriga cada ponto de entrada (o `main` e os testes) a escolher.
- **Por que `Provider` e não `ChangeNotifierProvider`?** O repositório não tem estado que mude, nem nada para avisar. O `Provider` simples só o deixa **alcançável** pela árvore.
- **Por que `.value`?** Porque o objeto foi criado fora (no `main`) e quem o criou cuida dele. É a mesma regra do material 5: `create` quando o *provider* é dono do objeto, `.value` quando não é.

## 6.3 `AppShell`: ler do contexto em vez de criar

`lib/app/shell/app_shell.dart` (trecho alterado)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/establishments/domain/repositories/establishment_repository.dart';
// ... imports das páginas ...

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // O mesmo repositório para as três abas, vindo do MultiProvider. O AppShell
  // não sabe se é o Supabase ou um fake.
  late final EstablishmentRepository _repository = context
      .read<EstablishmentRepository>();

  late final List<Widget> _tabs = [
    HomePage(
      repository: _repository,
      onOpenExplore: () => _onDestinationSelected(1),
    ),
    ExplorePage(repository: _repository),
    FavoritesPage(
      repository: _repository,
      onExploreTap: () => _onDestinationSelected(1),
    ),
    const ProfilePage(),
  ];
```

- **`late final` com `context.read`:** o campo só é calculado no primeiro uso, que acontece dentro do `build`. Nesse momento, o `context` já está na árvore e enxerga o `MultiProvider`. E, como é `final`, a busca acontece **uma vez**.
- **`read` e não `watch`:** o repositório nunca muda, então não há motivo para redesenhar.
- O `AppShell` continua `const AppShell()`, e a `SplashPage`, que o cria, não mudou.

## 6.4 O que **não** mudou

| Arquivo | Mudou? |
|---|---|
| `HomePage`, `EstablishmentDetailsPage`, `ExplorePage`, `FavoritesPage` | não |
| `ExploreController`, `FavoritesController` | não |
| `SourceImage` | não (já aceitava `https://`) |
| `FakeEstablishmentRepository` | não (continua servindo aos testes) |

Esse é o retorno do investimento feito no material 2, quando criamos o contrato antes de existir servidor.

---

# Parte 7: Erros reais chegando às telas

## 7.1 Como cada tela trata erro hoje

Antes de escrever o repositório, verificamos o que as telas já fazem:

| Tela | Como espera os dados | Em caso de exceção | Nova tentativa |
|---|---|---|---|
| **Home** | `FutureBuilder` sobre `fetchNearby()` | `snapshot.hasError` → "Não foi possível carregar os estabelecimentos." | botão chama `_reload()` (novo `Future`); puxar para atualizar também |
| **Detalhe** | `FutureBuilder` sobre `fetchDetails(id)` | `hasError` → "Não foi possível carregar as informações deste lugar." | botão chama `_reload()`. E `null` → "não estão mais disponíveis" + Voltar |
| **Explorar** | `ExploreController.load()` com `try/catch` | `ExploreStatus.failure` + `debugPrint` | botão chama `explore.retry()` |
| **Favoritos** | SQLite local | — | — (não depende da rede) |

Todas tratam **qualquer** exceção. Então basta o repositório **lançar** (e não devolver lista vazia, nem travar) para que o comportamento certo apareça. É isso que o `_guard` (falhas viram exceção) e o `requestTimeout` (nunca travar) garantem.

## 7.2 Cenário por cenário

| Cenário real | O que o *client* vê | O que a pessoa vê |
|---|---|---|
| modo avião | `ClientException` (*host lookup*) | erro em ~1 s, "Tentar novamente" |
| Wi-Fi conectado, mas sem saída (rede de hotel) | conexão que não responde → `TimeoutException` | carregando por até ~17 s, depois erro |
| projeto **pausado** (plano gratuito) | resposta de erro HTTP ou ausência de resposta | erro, e "Tentar novamente" volta a funcionar depois do *Restore project* |
| chave errada | `PostgrestException` 401 `Invalid API key` | erro, e o terminal mostra a causa |
| RLS sem política de leitura | `[]` (sucesso!) | "Ainda não encontramos opções perto de você." |
| lugar apagado no banco | `maybeSingle()` → `null` | "não estão mais disponíveis" + Voltar |
| favorito antigo (`'1'`) | nenhuma chamada | "não estão mais disponíveis" + Voltar |

> **O RLS não é erro.** Uma tabela sem política de leitura devolve lista vazia com HTTP 200, e o aplicativo mostra "nada perto de você", que é honesto do ponto de vista dele. É o mesmo sintoma do material 7, Parte 6.5. Se a Home ficar vazia e o painel mostrar dados, suspeite do RLS antes do Flutter.

> **Sobre o projeto pausado:** não testamos contra um projeto pausado real (veja a Parte 9.6). O que garantimos é que **qualquer** resposta de erro (inclusive uma página HTML em vez de JSON) e **qualquer** ausência de resposta terminam numa exceção, e não numa tela travada.

## 7.3 Imagens sem rede

Logos e fotos agora são URLs, e o `SourceImage` usa `NetworkImage`. Sem internet, o `errorBuilder` que já existe mostra o *fallback* (o ícone da categoria). Os oito lugares sem imagem continuam com `logo_path` nulo e caem no mesmo *fallback*, sem nenhuma chamada de rede.

---

# Parte 8: Os favoritos antigos

## 8.1 O problema

Os favoritos ficam no SQLite do aparelho e guardam uma **cópia** do estabelecimento (material 5, Parte 0.3). Depois da troca de catálogo, cada cópia antiga tem:

- `id` `'1'`..`'12'`, que **não existe** no Supabase (lá é `a0000000-…-000000000001`);
- `logo_source` com um caminho de *asset* (`assets/images/...`), e não uma URL.

O que aconteceria se não fizéssemos nada?

| Onde | Efeito |
|---|---|
| aba Favoritos | os cartões aparecem (a cópia é local) |
| coração na Home | **apagado** para todos: o id `uuid` da Home nunca é igual a `'1'` |
| tocar num favorito antigo | o Detalhe busca `'1'` → `null` (Parte 5.6) → "não estão mais disponíveis" |
| favoritar de novo o mesmo café | **duas** cópias na aba Favoritos: uma com `'1'` e outra com o uuid |

O último efeito é o pior: dados duplicados que a pessoa não entende.

## 8.2 A decisão: limpar a tabela ao trocar de catálogo

**No CeliLac**, usamos o mecanismo de migração do material 5: subimos o `schemaVersion` para 3, e o `onUpgrade` apaga as linhas antigas.

`lib/features/favorites/data/sqlite_favorites_repository.dart` (trechos)

```dart
  /// 1: tabela inicial. 2: coluna `logo_source`.
  /// 3: catálogo no Supabase (ids passam a ser uuids; favoritos antigos saem).
  static const int schemaVersion = 3;
```

```dart
  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Cada passo roda só se a migração atravessa aquela versão.
    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN logo_source TEXT',
      );
    }
    if (oldVersion < 3 && newVersion >= 3) {
      // Os favoritos salvos apontam para os ids '1'..'12' do catálogo fake,
      // que não existem no Supabase (lá os ids são uuids). A cópia guardada
      // também traz caminhos de assets em vez de URLs. Recomeçar do zero é a
      // opção mais simples e honesta para um catálogo fictício.
      await db.delete(tableName);
    }
  }
```

- **Quando roda?** Uma única vez, na primeira abertura da versão nova do aplicativo, em aparelhos que já tinham o banco na versão 2 (ou 1). Instalações novas passam pelo `onCreate` e começam vazias.
- **Por que `&& newVersion >= 3`?** Para que cada passo rode só quando a migração **atravessa** aquela versão. O teste antigo "migra da versão 1 para a 2" chama `upgradeSchema(db, 1, 2)` e não pode apagar nada. Na vida real, `newVersion` é sempre a versão atual, e a condição extra não muda nada.
- **Por que no `onUpgrade` e não num `if` no `main`?** Porque o SQLite já guarda "em que versão este banco está" (o `user_version`), garante que o passo roda **uma vez só** e roda **antes** de qualquer leitura. Reinventar isso com uma *flag* no `SharedPreferences` traria os mesmos problemas que o material 5 resolveu.

## 8.3 As alternativas, e por que não as escolhemos

| Alternativa | Como seria | Por que não, aqui |
|---|---|---|
| **Traduzir os ids** | no `onUpgrade`, `UPDATE favorites SET id = 'a0000000-0000-4000-8000-' \|\| printf('%012d', id)` | funciona **só** porque o seed usa uuids fixos e previsíveis. Num banco real (`gen_random_uuid()`), não há como adivinhar o novo id. E a cópia continuaria com o logo antigo |
| **Revalidar na abertura** | ao carregar os favoritos, chamar `fetchDetails` para cada um e apagar os que voltarem `null` | exige rede para abrir uma tela que hoje funciona *offline*. Faz N chamadas. E apagaria favoritos válidos se o servidor estivesse fora |
| **Deixar como está** | contar com o "não estão mais disponíveis" do Detalhe | as cópias duplicadas e os corações apagados confundem quem usa |
| **Guardar só o id e buscar o resto** | mudar o modelo dos favoritos | desfaz a decisão do material 5 (favoritos *offline*). É um material inteiro |

> **No seu projeto:** a regra geral é **"dados locais que apontam para o servidor precisam de uma estratégia quando os identificadores mudam"**. Com dados reais de usuários, apagar raramente é aceitável: prefira uma tabela de correspondência (id antigo → id novo) fornecida pelo servidor, ou uma migração no próprio servidor que mantenha os ids antigos. Para um catálogo fictício que existe só para aprender, recomeçar do zero é a escolha honesta.

---

# Parte 9: Testes sem rede

## 9.1 A estratégia

Não há (nem deve haver) Supabase nos testes automatizados: eles precisam rodar *offline*, em segundos, e dar sempre o mesmo resultado. Usamos três camadas:

| Camada | O que é real | O que é falso | Arquivo |
|---|---|---|---|
| conversão | `establishment_json.dart` | o JSON (texto copiado da API) | `establishment_json_test.dart` |
| repositório | **`SupabaseClient` de verdade** e o repositório | só o HTTP (`MockClient`) | `supabase_establishment_repository_test.dart` |
| ponta a ponta | `HomePage` + *client* real + repositório | só o HTTP | `supabase_catalog_flow_test.dart` |

**Por que um `SupabaseClient` de verdade, e não uma interface falsa?** Uma interface própria (`EstablishmentRemoteSource`, com um *fake* nos testes) também funcionaria, mas deixaria **sem teste** justamente a parte que pode errar: a cadeia `.from().select().order()…`, a URL gerada, o comportamento do `maybeSingle()` e o tratamento de erros HTTP pelo pacote. Trocando só o HTTP, o teste exercita todo o caminho até o "fio". Foi assim que descobrimos o `order()` decrescente (Parte 5.4).

## 9.2 Os dados de teste: o JSON real da API

`test/support/supabase_api_json.dart` guarda as respostas **como texto**, do jeito que chegam pela rede, a partir do material 7, Parte 8, completadas com os dados do `02_seed.sql`:

```dart
const testSupabaseUrl = 'https://celilac-teste.supabase.co';

const cafeAconchegoId = 'a0000000-0000-4000-8000-000000000001';
const emporioDaTerraId = 'a0000000-0000-4000-8000-000000000012';

/// `GET /rest/v1/establishments?select=id,name,...`  (Parte 8.2)
const nearbyResponseJson = '''
[
  {
    "id": "a0000000-0000-4000-8000-000000000001",
    "name": "Café Aconchego",
    "category": "cafe",
    "neighborhood": "Centro",
    "distance_in_km": 0.35,
    "rating": 4.8,
    "dietary_options": ["glutenFree", "lactoseFree"],
    "logo_path": "cafe_aconchego/logo.png"
  },
  {
    "id": "a0000000-0000-4000-8000-000000000012",
    "name": "Empório da Terra",
    "category": "market",
    "neighborhood": "Zona 7",
    "distance_in_km": 5.00,
    "rating": 4.0,
    "dietary_options": ["glutenFree"],
    "logo_path": null
  }
]
''';
```

O arquivo traz também `cafeAconchegoDetailsResponseJson` (com os 7 horários e as 3 fotos), `emporioDaTerraDetailsResponseJson` (sem telefone e sem fotos) e a função `testPublicUrl(path)`.

> **Dica:** para os seus próprios dados, rode o `curl` do material 7, Parte 8.4, e **cole a resposta real** num arquivo como este. Um JSON escrito "de cabeça" testa o que você imagina que a API devolve, não o que ela devolve.

## 9.3 Testando a conversão

`test/features/establishments/establishment_json_test.dart` (trechos)

```dart
/// A primeira linha de uma resposta da API, já decodificada.
Map<String, dynamic> _firstRow(String responseJson) =>
    (jsonDecode(responseJson) as List<dynamic>).first as Map<String, dynamic>;

void main() {
  group('establishmentFromJson', () {
    test('converte snake_case, enums, números e o caminho do logo', () {
      final cafe = establishmentFromJson(
        _firstRow(nearbyResponseJson),
        publicUrl: testPublicUrl,
      );

      expect(cafe.id, cafeAconchegoId);
      expect(cafe.category, EstablishmentCategory.cafe);
      expect(cafe.distanceInKm, 0.35);
      expect(cafe.dietaryOptions, {
        DietaryOption.glutenFree,
        DietaryOption.lactoseFree,
      });
      expect(
        cafe.logoSource,
        '$testSupabaseUrl/storage/v1/object/public/establishments/'
        'cafe_aconchego/logo.png',
      );
    });

    test('aceita números inteiros no JSON (5 em vez de 5.0)', () {
      final row = _firstRow(nearbyResponseJson)
        ..['distance_in_km'] = 5
        ..['rating'] = 4;

      final cafe = establishmentFromJson(row, publicUrl: testPublicUrl);

      expect(cafe.distanceInKm, 5.0);
      expect(cafe.rating, 4.0);
    });

    test('valor de enum desconhecido é erro, não um palpite', () {
      final row = _firstRow(nearbyResponseJson)..['category'] = 'bar';

      expect(
        () => establishmentFromJson(row, publicUrl: testPublicUrl),
        throwsArgumentError,
      );
    });
  });
```

```dart
    test('ordena fotos por position e horários por dia e abertura', () {
      final row = _firstRow(cafeAconchegoDetailsResponseJson);
      row['establishment_photos'] = (row['establishment_photos'] as List)
          .reversed
          .toList();
      row['opening_hours'] = [
        {'weekday': 5, 'opens_at': '19:00:00', 'closes_at': '23:00:00'},
        {'weekday': 5, 'opens_at': '11:30:00', 'closes_at': '15:00:00'},
        {'weekday': 2, 'opens_at': '11:30:00', 'closes_at': '15:00:00'},
      ];
      // ...
      expect(
        details.openingHours
            .map((h) => '${h.weekday} ${h.opensAt.inMinutes}')
            .toList(),
        ['2 690', '5 690', '5 1140'],
      );
    });
```

O arquivo cobre ainda: o logo nulo, os objetos 1:1 e as listas 1:N do detalhe, o lugar sem telefone e sem fotos, o `establishment_details` nulo → `null`, e os formatos de `time` (`07:00:00`, `11:30`, `08:15:30.250`, `24:00:00` e textos inválidos).

## 9.4 Testando o repositório com um HTTP falso

O `SupabaseClient` aceita um `httpClient`. Passamos um `MockClient`, do pacote `http`: uma função que recebe o pedido e devolve a resposta que quisermos. **Nada sai do computador.**

`test/features/establishments/supabase_establishment_repository_test.dart` (a montagem)

```dart
/// O repositório com um SupabaseClient de verdade, mas com o HTTP trocado
/// por [httpClient]: nada sai do computador.
SupabaseEstablishmentRepository _repositoryOn(
  http.Client httpClient, {
  int retryCount = 0, // cada teste vê uma única chamada, salvo se pedir mais
}) {
  final client = SupabaseClient(
    testSupabaseUrl,
    _publishableKey,
    httpClient: httpClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return SupabaseEstablishmentRepository(
    client,
    requestTimeout: const Duration(milliseconds: 200),
    retryCount: retryCount,
  );
}

/// Um "servidor" que responde [body] e, nos pedidos seguintes, cada item de
/// [thenReplies] (o último se repete). Anota os pedidos recebidos.
({SupabaseEstablishmentRepository repository, List<http.Request> requests})
_serverReplying(
  String body, {
  int status = 200,
  Map<String, String>? headers,
  List<({String body, int status})> thenReplies = const [],
  int retryCount = 0,
}) {
  final replies = [(body: body, status: status), ...thenReplies];
  final requests = <http.Request>[];
  final httpClient = MockClient((request) async {
    requests.add(request);
    final reply = replies[(requests.length - 1).clamp(0, replies.length - 1)];
    // `request:` é preenchido por qualquer client HTTP real; o postgrest o lê.
    return http.Response(
      reply.body,
      reply.status,
      headers: headers ?? _json,
      request: request,
    );
  });
  return (
    repository: _repositoryOn(httpClient, retryCount: retryCount),
    requests: requests,
  );
}
```

Detalhes que custaram tempo, para você não repetir:

- **`request: request` na resposta.** O pacote `postgrest` lê `response.request!.method`. Um cliente HTTP real sempre preenche esse campo, mas o `MockClient` simples não. Sem ele, todo teste falha com `Null check operator used on a null value`.
- **`charset=utf-8` no `content-type`.** Sem ele, o `http.Response` codifica o texto como Latin-1, e caracteres fora dessa tabela quebram.
- **`requestTimeout` curto e `retryCount: 0`.** Com os valores de produção, o teste de "sem internet" esperaria a nova tentativa (1 s), e o de "servidor mudo" esperaria 8 s.
- **`autoRefreshToken: false` e `client.dispose()`.** O *client* não deixa *timers* nem *isolates* abertos depois do teste.

**Conferindo a URL e o resultado:**

```dart
    test('pede as colunas da lista, ordenadas, com a chave pública', () async {
      final server = _serverReplying(nearbyResponseJson);

      final establishments = await server.repository.fetchNearby();

      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/establishments');
      expect(
        request.url.queryParameters['select'],
        SupabaseEstablishmentRepository.nearbyColumns,
      );
      expect(
        request.url.queryParameters['order'],
        'distance_in_km.asc.nullslast,name.asc.nullslast',
      );
      expect(request.headers['apikey'], _publishableKey);
      // ... e os lugares convertidos, com a URL do logo ...
    });
```

**O contrato `null`:**

```dart
    test('id inexistente devolve null', () async {
      final server = _serverReplying('[]');

      expect(
        await server.repository.fetchDetails(
          'a0000000-0000-4000-8000-000000000099',
        ),
        isNull,
      );
    });

    test(
      'id que não é uuid (favorito antigo, "1") devolve null sem rede',
      () async {
        final server = _serverReplying('[]');

        expect(await server.repository.fetchDetails('1'), isNull);
        expect(server.requests, isEmpty);
      },
    );
```

**As falhas.** Cada teste confere que sai uma `EstablishmentRepositoryException` **e** que a causa é a esperada:

```dart
/// Exige uma EstablishmentRepositoryException cuja causa é do tipo [C].
Matcher _failsWithCause<C>() => throwsA(
  isA<EstablishmentRepositoryException>().having(
    (e) => e.cause,
    'cause',
    isA<C>(),
  ),
);
```

```dart
    test('sem internet', () async {
      final httpClient = MockClient((request) async {
        throw http.ClientException('Failed host lookup', request.url);
      });
      final repository = _repositoryOn(httpClient);

      await expectLater(
        repository.fetchNearby(),
        _failsWithCause<http.ClientException>(),
      );
    });

    test('servidor que não responde (tempo esgotado)', () async {
      // Um servidor mudo: só "termina" quando o client desiste e aborta,
      // como faria uma conexão de verdade.
      final httpClient = MockClient.streaming((request, _) async {
        await (request as http.Abortable).abortTrigger;
        throw http.RequestAbortedException(request.url);
      });
      final repository = _repositoryOn(httpClient);

      await expectLater(
        repository.fetchNearby(),
        _failsWithCause<TimeoutException>(),
      );
    });
```

O **servidor mudo** merece atenção. O `MockClient` não sabe abortar sozinho: a documentação diz que é responsabilidade do *handler*. Usamos `MockClient.streaming`, que recebe o pedido original com o `abortTrigger`. O *handler* espera esse sinal (que o *timeout* dispara) e então lança `RequestAbortedException`, como um cliente HTTP real faria. O pacote `postgrest` transforma isso em `TimeoutException`.

O arquivo cobre também: 401 (`Invalid API key`), 503 com página HTML, JSON fora do contrato (categoria `"bar"`), lista vazia (RLS), lugar sem linha em `establishment_details` e **uma nova tentativa automática** (503 seguido de 200, com `retryCount: 1`).

## 9.5 Ponta a ponta: a Home, sem internet e depois com internet

`test/app/supabase_catalog_flow_test.dart`

```dart
void main() {
  testWidgets(
    'sem internet, a Home mostra o erro; com a rede de volta, '
    '"Tentar novamente" carrega o catálogo do Supabase',
    (tester) async {
      var online = false;
      final httpClient = MockClient((request) async {
        if (!online) {
          throw http.ClientException('Failed host lookup', request.url);
        }
        return http.Response(
          nearbyResponseJson,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
          request: request,
        );
      });
      // O SupabaseClient abre um isolate para JSON: criar e descartar fora
      // do relógio falso do testWidgets (runAsync), senão o teste trava.
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          testSupabaseUrl,
          'sb_publishable_chave_de_teste',
          httpClient: httpClient,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      ))!;
      final repository = SupabaseEstablishmentRepository(client, retryCount: 0);

      await pumpWithProfile(
        tester,
        Scaffold(body: HomePage(repository: repository)),
        exploreRepository: repository,
        size: const Size(360, 2400),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar os estabelecimentos.'),
        findsOne,
      );

      online = true;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Café Aconchego'), findsOne);
      expect(find.text('Empório da Terra'), findsOne);
      expect(find.text('Tentar novamente'), findsNothing);

      await tester.runAsync(client.dispose);
    },
  );
}
```

> **Armadilha do `testWidgets`:** o `testWidgets` roda num **relógio falso**, em que o tempo só anda quando você chama `pump`. O `SupabaseClient` cria um *isolate* (uma linha de execução separada, para decodificar JSON grande) e, no relógio falso, esperar por ele nunca termina: na primeira versão deste teste, `flutter test` ficou parado indefinidamente. `tester.runAsync` executa um trecho no relógio **real**, e é ali que criamos e descartamos o *client*. Nos testes com `test()` (sem *widgets*), o relógio já é real e isso não é necessário.

## 9.6 Ajustes nos apoios de teste

- **`pumpWithProfile`** (`test/support/pump_app.dart`) passou a registrar também o `Provider<EstablishmentRepository>`, com a **mesma** instância do `ExploreController`, como o `CeliLacApp` faz:

```dart
  // O mesmo repositório para o ExploreController e para o AppShell, como no app.
  final establishmentRepository =
      exploreRepository ??
      const FakeEstablishmentRepository(delay: Duration.zero);
  final exploreController = ExploreController(establishmentRepository);
```

```dart
      providers: [
        Provider<EstablishmentRepository>.value(value: establishmentRepository),
        ChangeNotifierProvider<ProfileController>.value(value: controller),
```

- **`splash_page_test.dart`** passa `establishmentRepository: const FakeEstablishmentRepository()` ao `CeliLacApp`, agora obrigatório.
- **`sqlite_favorites_repository_test.dart`** ganhou o teste da migração para a versão 3:

```dart
  test(
    'migra para a versão 3 apagando os favoritos do catálogo fake',
    () async {
      final v2Db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          singleInstance: false,
          onCreate: SqliteFavoritesRepository.createSchema,
        ),
      );
      addTearDown(v2Db.close);
      final v2Repo = SqliteFavoritesRepository(openDatabase: () async => v2Db);
      await v2Repo.add(_cafe);
      await v2Repo.add(_bakery);

      await SqliteFavoritesRepository.upgradeSchema(v2Db, 2, 3);

      expect(await v2Repo.loadAll(), isEmpty);
      expect(await v2Repo.isFavorite('1'), isFalse);
    },
  );
```

- **`supabase_config_test.dart`** cobre a configuração válida, as ausências, o `https://`, a barra final e as duas formas de chave secreta (`sb_secret_` e JWT `service_role`), além de aceitar o JWT `anon`.

## 9.7 Rodando

```bash
flutter analyze
flutter test
```

**No CeliLac**, ao final desta etapa: **193 testes passando** (eram 162). O `flutter analyze` não acusa nenhum problema novo. Se o seu SDK for mais novo que o 3.47, aparecem avisos `deprecated_member_use` sobre `material.dart`, iguais aos dos arquivos anteriores.

## 9.8 O que os testes **não** cobrem

Seja honesto com o que um teste prova. Tudo acima roda **sem** um projeto Supabase real, e por isso **não foram verificados**:

| Não verificado automaticamente | Como verificar à mão (Parte 10) |
|---|---|
| que o **seu** banco devolve exatamente o JSON dos *fixtures* | comparar com o `curl` do material 7 |
| que as **políticas de RLS** do seu projeto liberam a leitura | a Home mostra 12 lugares |
| que as **imagens** existem no Storage com os caminhos do seed | os 4 logos e as fotos aparecem |
| o comportamento exato de um **projeto pausado** (código HTTP, demora) | pausar o projeto no painel e abrir o aplicativo |
| a **demora real** do *timeout* e da nova tentativa num celular | modo avião, Wi-Fi sem saída |
| a permissão de internet num **APK de *release*** | `flutter build apk` e instalar |

---

# Parte 10: Rodando de verdade

## 10.1 Primeira execução

1. Confira o banco: no SQL Editor, a contagem do material 7, Parte 5.2, deve dar `12 | 12 | 74 | 11`.
2. Crie o `supabase.json` a partir do modelo e preencha com **os seus** valores.
3. Rode:

```bash
flutter pub get
flutter run --dart-define-from-file=supabase.json
```

4. Depois da Splash, a Home deve mostrar os 12 lugares, **do mais perto para o mais longe**. Os 4 com imagem mostram o logo baixado do Storage, e os outros mostram o ícone da categoria.
5. Abra o Café Aconchego: horários, práticas e o carrossel com as 3 fotos.

## 10.2 Roteiro de verificação manual

| # | Ação | Esperado |
|---|---|---|
| 1 | rodar **sem** `--dart-define-from-file` | o aplicativo não abre, e o terminal mostra `Configuração do Supabase incompleta` |
| 2 | Home, Detalhe e Explorar com internet | dados do banco, imagens do Storage |
| 3 | mudar um nome no **Table Editor** e puxar a Home para atualizar | o nome novo aparece **sem publicar o aplicativo** |
| 4 | ligar o **modo avião** e puxar a Home | em poucos segundos, "Não foi possível carregar…" |
| 5 | desligar o modo avião e tocar em **Tentar novamente** | a lista volta |
| 6 | modo avião, aba **Explorar** com erro → **Tentar novamente** com rede | a lista volta |
| 7 | modo avião, abrir um lugar | a tela mostra o resumo e o erro de detalhe, com nova tentativa |
| 8 | modo avião, aba **Favoritos** | os favoritos aparecem (são locais), e os logos caem no ícone |
| 9 | trocar a chave por uma inválida | erro na Home, e `Invalid API key` no terminal |
| 10 | colocar a chave **secreta** no `supabase.json` | o aplicativo recusa abrir |
| 11 | aparelho que já tinha favoritos do *fake* | depois de atualizar o aplicativo, a aba Favoritos está vazia |

> **Repare no item 3:** é a razão de existir deste material. O dado mora num só lugar, e o aplicativo reflete a mudança sem uma nova versão.

---

# Parte 11: Revisão

## 11.1 Resumo das decisões

| Decisão | Motivo |
|---|---|
| Configuração por `--dart-define-from-file` | cada aluno com o seu projeto; nada de chaves no Git |
| `SupabaseConfig` valida no início e recusa chave secreta | erro claro na hora, e não "carregando" misterioso |
| Sem volta silenciosa para o *fake* | um esquecimento de configuração não pode parecer que funciona |
| Conversão em `establishment_json.dart` | mesmo padrão do material 5; testável sem rede |
| `byName` estrito | dado de segurança alimentar não pode virar palpite |
| Ordenar horários e fotos na conversão | a API não garante a ordem das linhas embutidas |
| `maybeSingle()` | "não existe" = `null`, como o contrato exige |
| Validar uuid antes de consultar | id inválido é "não existe", não "falhou" |
| `requestTimeout` e `retry` na consulta | nunca travar; `client.from` não respeita as opções globais nesta versão |
| `EstablishmentRepositoryException` com `cause` | telas sem Supabase; a causa visível no terminal |
| `CeliLacApp` com repositório obrigatório | produção não depende do *fake* |
| Favoritos: limpar na versão 3 | ids e cópias antigas não servem mais |
| `SupabaseClient` real + `MockClient` nos testes | testa a URL e o tratamento de erros do pacote, não só a nossa lógica |

## 11.2 Armadilhas encontradas

| Sintoma | Causa | Correção |
|---|---|---|
| Home do mais longe para o mais perto | `order()` é decrescente por padrão no Dart | `ascending: true` |
| Tela carregando para sempre | sem `requestTimeout` | `.retry(requestTimeout: …)` |
| `requestTimeout` no `initialize` sem efeito | `client.from` não repassa `postgrestOptions` (supabase 2.16.5) | política na própria consulta |
| "Tentar novamente" eterno no favorito antigo | `id=eq.1` em coluna `uuid` → HTTP 400 | validar o formato antes; `null` |
| Funciona em *debug*, falha no APK | falta `INTERNET` no manifesto `main` | `<uses-permission … INTERNET/>` |
| Funciona no celular, falha no macOS | *sandbox* sem `network.client` | *entitlement* |
| Home vazia, painel cheio | RLS sem política de leitura | criar a política (material 7, Parte 6) |
| Testes: `Null check operator…` | `MockClient` sem `request:` na resposta | `http.Response(…, request: request)` |
| `testWidgets` parado para sempre | *isolate* do `SupabaseClient` no relógio falso | criar e descartar dentro de `tester.runAsync` |
| `supabase.json` no `git status` | `.gitignore` não atualizado | acrescentar a linha; `git rm --cached` se já foi |

## 11.3 O que ficou de fora

| Assunto | Por quê / quando |
|---|---|
| **Auth** e perfil sincronizado | material futuro: login, políticas `auth.uid()` |
| **Cache** do catálogo | Home e Explorar fazem uma chamada cada uma; sem internet, a Home não mostra nada antigo |
| **Remover os *assets*** do aplicativo | o *fake* e os testes ainda os usam |
| **Distância real** | a coluna `distance_in_km` é ficção didática (material 7, Parte 4.4) |
| **Paginação** | 12 lugares não precisam; mil precisariam de `.range()` |
| **Realtime** | o catálogo não muda a ponto de exigir atualização ao vivo |

## 11.4 Outras opções do ecossistema

| Necessidade | Opções |
|---|---|
| *client* HTTP genérico | `http`, `dio` (interceptadores, *retry*) |
| gerar a conversão JSON | `json_serializable`, `freezed` (geração de código) |
| *cache* *offline* do catálogo | `drift`, `sqflite` (como nos favoritos), `hive` |
| dublês de teste | `mocktail`, `mockito`; `MockClient` para HTTP |
| injeção de dependências | `provider` (usado aqui), `get_it`, `riverpod` |

> **Por que conversão escrita à mão e não `json_serializable`?** São dois tipos e menos de cem linhas, e escrevê-las mostra **o que** precisa ser traduzido. Com dezenas de entidades, a geração de código compensa.

---

# Parte 12: Aplicando no seu projeto

## 12.1 Roteiro

1. **Contrato primeiro.** As telas já dependem de uma interface? Se não, comece por aí (material 2).
2. **Documente o contrato de erro:** o que é `null`, o que é lista vazia e o que é exceção.
3. **Configuração** por `--dart-define-from-file`, com um `*.example.json` versionado e o real no `.gitignore`.
4. **Permissões de plataforma:** `INTERNET` no Android, `network.client` no macOS.
5. **Conversão isolada** em `data/`, testada com respostas **copiadas da API**.
6. **Repositório** com `requestTimeout`, `retry` e uma exceção de domínio.
7. **Troca na raiz de composição**, sem tocar nas telas.
8. **Dados locais** que apontam para o servidor: decida o que acontece com eles.
9. **Testes** com `MockClient`: sucesso, vazio, `null`, 4xx, 5xx, sem rede e *timeout*.
10. **Verificação manual** com o projeto real, incluindo o modo avião.

## 12.2 Adaptando ao tema do seu aplicativo

| Tema | Lista (`fetchX`) | Detalhe com embutidos | Conversões delicadas |
|---|---|---|---|
| Catálogo de cursos | `courses` | `lessons(...)`, `instructors(...)` | duração (`interval`), níveis (`enum`) |
| Imobiliária estudantil | `listings` | `photos(...)`, `visits(...)` | preço (`numeric`), data de visita |
| Receitas | `recipes` | `ingredients(...)`, `steps(...)` | ordem dos passos (`position`) |
| Clínicas | `clinics` | `schedules(...)` | horários (`time`), dias da semana |
| Vagas de estágio | `jobs` | `requirements(...)` | salário opcional (`null`), datas |

## 12.3 Checklist

- [ ] `supabase.json` fora do Git (`git check-ignore -v supabase.json`), com modelo versionado.
- [ ] Nenhuma chave **secreta** no aplicativo, nem no histórico do Git.
- [ ] `Supabase.initialize` no `main`, depois de `ensureInitialized`.
- [ ] Configuração validada, com mensagem clara se faltar.
- [ ] Conversão em `data/`, testada com o JSON real da API.
- [ ] `order(..., ascending: true)` onde a ordem importa.
- [ ] `maybeSingle()` para "um ou nenhum".
- [ ] `requestTimeout` definido: nenhuma tela pode carregar para sempre.
- [ ] Toda falha vira **uma** exceção de domínio, com a causa guardada.
- [ ] Nenhum arquivo de `presentation/` importa `supabase_flutter`.
- [ ] Testes sem rede para sucesso, vazio, `null`, erro HTTP, sem rede e *timeout*.
- [ ] Permissão de internet no manifesto `main` do Android.
- [ ] Roteiro manual da Parte 10.2 executado com o seu projeto.

## 12.4 Desafios opcionais

1. **`FavoritesPage` sem *fake*:** o construtor da `FavoritesPage` ainda tem `repository = const FakeEstablishmentRepository()` como valor padrão (o `AppShell` sempre passa o real, então ele não é usado). Torne o parâmetro obrigatório e ajuste os testes. Que risco esse padrão escondia?
2. **Uma chamada só:** Home e Explorar chamam `fetchNearby()` cada uma. Faça a Home usar o catálogo do `ExploreController`, ou crie um repositório com *cache* em memória que envolve outro (`CachedEstablishmentRepository implements EstablishmentRepository`). Onde ele entraria? *(Dica: só na raiz de composição.)*
3. **Catálogo *offline*:** guarde a última lista recebida no SQLite e mostre-a quando a rede falhar, com um aviso "dados de <data>". Como fica o contrato de erro?
4. **Filtro no servidor:** implemente um `fetchByCategory(category)` com `.eq('category', category.name)`. Valeu a pena, com 12 lugares? E com 10 mil?
5. **Ordem no servidor:** troque a ordenação das fotos na conversão por `.order('position', referencedTable: 'establishment_photos')`. Escreva um teste que confira a URL. O que se perde?
6. **Traduzir em vez de apagar:** implemente a alternativa "traduzir os ids" da Parte 8.3 numa versão 4 do esquema e discuta por que ela só funciona com o seed didático.
7. **Remover os *assets*:** tire as imagens dos estabelecimentos do `pubspec.yaml`. O que precisa mudar no *fake* e nos testes? Quanto o APK diminui?

---

# Apêndice A: Solução de problemas

| Sintoma / mensagem | Causa provável | Como corrigir |
|---|---|---|
| `Configuração do Supabase incompleta: SUPABASE_URL não foi definida` | rodou sem `--dart-define-from-file` | `flutter run --dart-define-from-file=supabase.json`, ou o F5 com o `launch.json` desta etapa |
| `... recebeu a chave SECRETA` | chave `sb_secret_` ou `service_role` no `supabase.json` | usar a pública; **revogar** a secreta no painel |
| "não foi definida" mesmo com o `supabase.json` preenchido | arquivo fora da raiz do projeto, nome de chave diferente (`SUPABASE_KEY` em vez de `SUPABASE_PUBLISHABLE_KEY`) ou JSON inválido | deixar o arquivo ao lado do `pubspec.yaml`; copiar os nomes do `supabase.example.json`; validar o JSON |
| Home: "Não foi possível carregar"; terminal: `Invalid API key` | chave com espaço, quebra de linha ou de outro projeto | copiar de novo, entre aspas |
| Terminal: `Failed host lookup` | sem internet, ou URL com erro de digitação | conferir a rede e a `SUPABASE_URL` |
| Terminal: `TimeoutException` | rede sem saída, ou projeto acordando da pausa | tentar de novo; *Restore project* no painel |
| Terminal: `PGRST205 Could not find the table` | esquema não criado neste projeto | rodar o `01_schema.sql` (material 7) |
| Terminal: `PGRST200` ao abrir o detalhe | nome de tabela filha errado no `select`, ou chave estrangeira ausente | conferir `detailsColumns` com o esquema |
| Home vazia ("Ainda não encontramos…") | RLS sem política, ou seed não executado | material 7, Partes 5.2 e 6.5 |
| Lugares do mais longe para o mais perto | `order()` sem `ascending: true` | Parte 5.4 |
| Logos e fotos não aparecem, só ícones | caminho no Storage diferente do seed, *bucket* privado ou sem internet | abrir a URL pública no navegador (material 7, Parte 7.3) |
| Funciona em *debug*, não no APK instalado | falta `INTERNET` no `main/AndroidManifest.xml` | Parte 1.2 |
| `ArgumentError: No enum value with that name` no terminal | categoria, opção ou prática no banco que o aplicativo não conhece | corrigir o dado, ou atualizar o `enum` no aplicativo |
| Favoritos sumiram depois da atualização | migração para a versão 3 (Parte 8) | esperado; favorite de novo |
| Teste trava em `testWidgets` com `SupabaseClient` | *isolate* no relógio falso | criar e descartar o *client* em `tester.runAsync` |
| Teste: `Null check operator used on a null value` | `MockClient` sem `request:` | `http.Response(..., request: request)` |

# Apêndice B: Glossário

- **Raiz de composição (*composition root*):** o único lugar do aplicativo que conhece as classes concretas e as liga (aqui: `main`, `CeliLacApp`, `AppShell`).
- **`--dart-define` / `--dart-define-from-file`:** valores passados ao compilador e lidos com `String.fromEnvironment`. Ficam **dentro** do binário: servem para tirar a configuração do Git, não para esconder segredos.
- **`supabase_flutter`:** pacote oficial que reúne os *clients* de banco (PostgREST), Storage e Auth para Flutter.
- **`SupabaseClient`:** o objeto que faz as chamadas; `Supabase.instance.client` depois do `initialize`.
- **Dados embutidos (*embedding*):** pedir à API, no `select`, as linhas de tabelas relacionadas (`opening_hours(...)`), dentro da mesma resposta.
- **`maybeSingle()`:** "no máximo uma linha": devolve o objeto, ou `null` se não houver nenhuma.
- **`requestTimeout`:** tempo máximo de uma tentativa; depois dele, a conexão é abortada e surge `TimeoutException`.
- ***Retry*:** nova tentativa automática depois de uma falha passageira, com espera crescente entre as tentativas.
- **Exceção de domínio:** um tipo de erro definido pelo aplicativo (`EstablishmentRepositoryException`) que esconde os tipos de cada tecnologia.
- **`cause`:** o erro original guardado dentro da exceção de domínio, para diagnóstico.
- **`Error.throwWithStackTrace`:** relança um erro preservando a pilha de chamadas original.
- **JWT (*JSON Web Token*):** texto em três partes (`cabeçalho.conteúdo.assinatura`); as chaves antigas do Supabase têm esse formato.
- **`MockClient`:** cliente HTTP falso do pacote `http`, em que uma função sua faz o papel do servidor.
- ***Fixture*:** dado de teste fixo e reutilizável (aqui, as respostas da API em `supabase_api_json.dart`).
- **`tester.runAsync`:** executa um trecho de um `testWidgets` no relógio real, fora do relógio falso.
- **Migração de dados:** alteração nos dados (e não só na estrutura) ao subir a versão do banco local.
