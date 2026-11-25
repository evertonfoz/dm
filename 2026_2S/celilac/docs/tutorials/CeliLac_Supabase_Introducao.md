# CeliLac: Introdução ao Supabase

## Banco de dados, API e segurança na nuvem, antes de escrever uma linha de Dart

---

## Como usar este material

Este é o **sétimo material** da série de construção do **CeliLac**, e o primeiro que **não mexe no aplicativo**. Aqui construímos o **servidor** que o aplicativo vai consultar no material seguinte.

Nos materiais anteriores, o aplicativo ganhou identidade e onboarding, Home, detalhe, perfil alimentar, favoritos em SQLite e a aba Explorar. Em todos eles, **o catálogo de estabelecimentos mora dentro do código**: a classe `FakeEstablishmentRepository` tem 12 lugares escritos à mão, e o contrato `EstablishmentRepository` foi desenhado desde o início para o dia em que esses dados viessem de fora.

Esse dia chegou. Mas, antes de trocar a implementação, precisamos de um servidor, e ele precisa ser entendido, não apenas copiado. Por isso este material tem **três objetivos**:

1. Apresentar o **Supabase**: o que é, o que oferece e o que não oferece.
2. Criar **o seu projeto** e **o banco do CeliLac** (tabelas, dados, segurança e imagens).
3. **Consultar a API pelo navegador e pelo terminal**, vendo o JSON que o aplicativo vai ler, antes de abrir o Flutter.

Duas marcações aparecem ao longo do texto:

- **No CeliLac** — o que fazemos neste projeto.
- **No seu projeto** — como adaptar a mesma decisão para outro domínio.

> **Continuação:** o próximo material, *CeliLac com Supabase*, implementa o `SupabaseEstablishmentRepository` e troca o *fake* sem alterar nenhuma tela. Ele parte do banco que você montar aqui.

### Pré-requisitos

- Uma conta de e-mail ou de GitHub para criar a conta no Supabase (o plano gratuito basta).
- Um navegador e o terminal (o `curl` já vem no macOS e no Linux; no Windows 10 e 11 ele também está disponível).
- **Nenhum conhecimento prévio de SQL.** A Parte 3 ensina o mínimo.
- O projeto Flutter não é necessário nesta etapa.

### Arquivos deste material

Os dois scripts SQL estão prontos na pasta [`supabase/sql/`](./supabase/sql/):

| Arquivo | O que faz |
|---|---|
| [`01_schema.sql`](./supabase/sql/01_schema.sql) | cria as quatro tabelas, as regras de segurança e o *bucket* de imagens |
| [`02_seed.sql`](./supabase/sql/02_seed.sql) | insere os 12 estabelecimentos fictícios (mesmos dados do `FakeEstablishmentRepository`) |

As imagens a enviar estão em `assets/images/establishments/` do projeto.

### Ao final deste material, você será capaz de

1. Explicar o que é um ***Backend as a Service*** e quais partes do Supabase o CeliLac usa.
2. Criar um projeto no Supabase e identificar **URL**, **chave pública** e **chave secreta**, sabendo qual delas pode ir no aplicativo.
3. Escrever consultas SQL básicas (`select`, `where`, `order by`, `insert`).
4. **Modelar** um domínio de aplicativo em tabelas, escolhendo entre colunas, *arrays* e tabelas filhas.
5. Explicar o que é ***Row Level Security*** (RLS), por que toda tabela nasce fechada e como abrir só a leitura.
6. Enviar arquivos para o **Storage** e obter a URL pública de cada um.
7. Consultar a **API REST** gerada automaticamente, com filtros, ordenação e dados relacionados, usando `curl`.

---

# Parte 0: Antes do código — o problema

## 0.1 O que o aplicativo faz hoje

```text
┌─────────────────────────────────────────┐
│ Aplicativo CeliLac                      │
│                                         │
│  HomePage ──► EstablishmentRepository   │
│                      │                  │
│                      ▼                  │
│        FakeEstablishmentRepository      │
│        (12 lugares escritos no código)  │
└─────────────────────────────────────────┘
```

Isso foi ótimo para aprender, porque não dependia de nada externo. Mas tem limites sérios:

| Limite | Consequência |
|---|---|
| Os dados fazem parte do código | para corrigir um endereço, é preciso **publicar uma nova versão do aplicativo** |
| Cada aparelho tem a sua cópia | ninguém consegue **cadastrar** um lugar novo para todo mundo |
| Não há como saber o que mudou | não existe uma única fonte da verdade |
| Imagens dentro do aplicativo | cada foto aumenta o tamanho do download |

## 0.2 O que queremos

```text
┌──────────────────┐        internet        ┌──────────────────────────┐
│ Aplicativo       │ ◄────────────────────► │ Servidor                 │
│ (qualquer        │   "me dê os lugares"   │ banco de dados + regras  │
│  aparelho)       │   JSON                 │ de acesso + imagens      │
└──────────────────┘                        └──────────────────────────┘
```

Um servidor que guarda os dados, decide **quem pode ler e quem pode escrever** e entrega o resultado em um formato que o aplicativo entende (JSON).

## 0.3 Por que não escrever esse servidor do zero?

Construir um servidor próprio significa instalar e manter um banco de dados, escrever uma API (rotas, validação, erros), cuidar de segurança e de hospedagem, e tudo isso antes de entregar a primeira tela. Para um aplicativo didático, isso é um curso inteiro à parte.

A alternativa é um ***Backend as a Service*** (BaaS): um serviço que **já oferece** banco, API, autenticação e armazenamento de arquivos, configurados por painel.

## 0.4 Por que o Supabase

| Critério | Supabase |
|---|---|
| Banco de dados | **PostgreSQL** padrão: o que se aprende aqui vale em qualquer empresa |
| API | gerada **automaticamente** a partir das tabelas |
| Segurança | regras no próprio banco (RLS), visíveis e testáveis |
| Plano gratuito | suficiente para a turma toda, sem cartão de crédito |
| Dependência do fornecedor | baixa: é código aberto e o banco é Postgres comum, então os dados podem ser exportados |
| Cliente Flutter | pacote oficial `supabase_flutter` |

> **No seu projeto:** as mesmas perguntas servem para escolher qualquer BaaS (Firebase, Appwrite, PocketBase). A diferença mais importante do Supabase para o Firebase é o **modelo de dados**: tabelas relacionais e SQL, em vez de documentos.

---

# Parte 1: O que é o Supabase

## 1.1 Um projeto, cinco serviços

Ao criar um projeto, você recebe **um servidor Postgres exclusivo** e, em volta dele, serviços prontos:

```text
                     seu projeto Supabase
┌───────────────────────────────────────────────────────────┐
│                                                           │
│   API REST ──────┐    (gerada a partir das tabelas)       │
│   Auth ──────────┤    (cadastro e login)                  │
│   Storage ───────┼──► PostgreSQL  ◄── Realtime            │
│   Edge Functions ┘    (seus dados)     (mudanças ao vivo) │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

| Serviço | O que faz | Usamos no CeliLac? |
|---|---|---|
| **Database** (Postgres) | guarda os dados em tabelas | **sim**, neste material |
| **API REST** (PostgREST) | transforma cada tabela em endereços HTTP | **sim**, é o que o aplicativo chama |
| **Storage** | guarda arquivos (imagens) em *buckets* | **sim**, para logos e fotos |
| **Auth** | cadastro, login, sessões | **depois** (perfil sincronizado) |
| **Realtime** | avisa o aplicativo quando uma linha muda | não |
| **Edge Functions** | código seu rodando no servidor | não |

## 1.2 Como uma consulta viaja

Quando o aplicativo pede os estabelecimentos, o caminho é este:

```text
Aplicativo                          Supabase
   │                                   │
   │ GET /rest/v1/establishments       │
   │ + chave pública                   │
   ├──────────────────────────────────►│ 1. A API recebe o pedido
   │                                   │ 2. Identifica quem pede (anon? logado?)
   │                                   │ 3. Transforma em SQL: select * from establishments
   │                                   │ 4. O Postgres aplica as regras de RLS
   │                                   │ 5. Devolve só as linhas permitidas
   │◄──────────────────────────────────┤
   │ [ {"id": "...", "name": "..."} ]  │
```

O ponto central é o passo 4: **quem protege os dados é o banco**, não o aplicativo. Um aplicativo Flutter pode ser aberto e inspecionado por qualquer pessoa, então nenhuma regra de segurança pode depender dele. Voltaremos a isso na Parte 6.

## 1.3 Tabelas, linhas e colunas

Se você já usou o SQLite no material de Favoritos, o modelo é o mesmo: uma **tabela** é um conjunto de **linhas**, e cada linha tem as mesmas **colunas**.

| id | name | category | rating |
|---|---|---|---|
| a000…0001 | Café Aconchego | cafe | 4.8 |
| a000…0002 | Padaria Leve Grão | bakery | 4.6 |

A diferença é **onde** o banco vive. No SQLite, é um arquivo dentro do aparelho. No Supabase, é um servidor na internet, compartilhado por todos os aparelhos.

---

# Parte 2: Criando o seu projeto

## 2.1 Conta e organização

1. Acesse o site do Supabase e entre com o GitHub ou com e-mail.
2. Na primeira vez, o painel pede para criar uma **organização**. Escolha o plano **Free**.

## 2.2 Novo projeto

Clique em **New project** e preencha:

| Campo | O que colocar | Por quê |
|---|---|---|
| **Name** | `celilac` | só um rótulo |
| **Database Password** | uma senha forte, **guardada em local seguro** | dá acesso direto e total ao banco |
| **Region** | *South America (São Paulo)* | a região mais próxima reduz a latência |

A criação leva um ou dois minutos.

> **Guarde a senha do banco.** O painel não a mostra de novo. Ela só é necessária para conexões diretas ao Postgres, que não usaremos, mas perdê-la obriga a redefinir.

> **Projetos gratuitos hibernam.** Depois de uma semana sem uso, o Supabase pausa o projeto, e um botão **Restore project** o reativa em alguns minutos. Se o aplicativo parecer "fora do ar" depois das férias, é isso.

## 2.3 As credenciais: o que pode e o que não pode ir no aplicativo

No painel, abra **Project Settings → API** (ou **API Keys**). Você encontra:

| Credencial | Aparência | Pode ir no aplicativo? |
|---|---|---|
| **Project URL** | `https://abcdefgh.supabase.co` | **sim** |
| Chave **pública** (*publishable* ou *anon*) | `sb_publishable_...` ou um JWT longo | **sim**: é feita para ficar exposta |
| Chave **secreta** (*secret* ou *service_role*) | `sb_secret_...` ou um JWT longo | **NUNCA** |

> **Os nomes mudaram.** O Supabase está trocando as chaves antigas (`anon` e `service_role`) pelas novas (*publishable* e *secret*). Os dois pares funcionam. Neste material, chamamos a primeira de **chave pública** e a segunda de **chave secreta**. Use a que o seu painel mostrar.

**Por que a chave pública pode ser exposta?** Porque ela **não dá poder nenhum além do que o RLS permitir**. Ela apenas identifica o projeto e diz ao banco: "quem está pedindo é um visitante anônimo". O que o visitante pode fazer é decidido pelas regras da Parte 6.

**Por que a chave secreta é perigosa?** Porque ela **ignora o RLS**. Quem a tiver pode ler, alterar e apagar qualquer linha de qualquer tabela. Ela existe para servidores seus, nunca para aplicativos instalados em aparelhos de terceiros.

> **Armadilha clássica:** colocar a chave secreta no código Flutter "só para testar" e enviar para o GitHub. Robôs varrem repositórios públicos em busca de chaves, e o estrago acontece em minutos. Se isso acontecer, gere uma nova chave no painel e revogue a antiga imediatamente.

Anote a **Project URL** e a **chave pública**. Você vai usá-las na Parte 8 e no material seguinte.

---

# Parte 3: SQL mínimo para o CeliLac

O painel tem um **SQL Editor** (menu lateral). É nele que vamos trabalhar. Abra uma nova consulta (*New query*) para cada exercício.

Você precisa de poucos comandos. Eles serão testados na Parte 5, depois que as tabelas existirem; por ora, o objetivo é reconhecê-los.

## 3.1 Ler: `select`

```sql
select name, category, rating
from establishments;
```

Lê as colunas `name`, `category` e `rating` de **todas** as linhas da tabela `establishments`. Para trazer todas as colunas, use `*`:

```sql
select * from establishments;
```

## 3.2 Filtrar: `where`

```sql
select name, neighborhood
from establishments
where category = 'cafe';
```

Operadores úteis:

| Operador | Significado | Exemplo |
|---|---|---|
| `=`, `<>` | igual, diferente | `category = 'bakery'` |
| `>`, `>=`, `<`, `<=` | comparações | `rating >= 4.5` |
| `and`, `or` | combinar condições | `category = 'cafe' and rating > 4.5` |
| `ilike` | texto, ignorando maiúsculas | `name ilike '%café%'` |

O `%` é um curinga: "qualquer sequência de caracteres".

> **Aspas simples para texto.** Em SQL, `'cafe'` é um texto. Aspas duplas servem para nomes de colunas e tabelas, e usá-las para texto é um erro comum.

## 3.3 Ordenar e limitar: `order by` e `limit`

```sql
select name, rating
from establishments
order by rating desc, name
limit 3;
```

`desc` é decrescente; sem ele, a ordem é crescente. O segundo critério (`name`) **desempata**, a mesma ideia do comparador do material de Explorar.

## 3.4 Escrever: `insert`

```sql
insert into establishments (name, category, neighborhood, distance_in_km, rating)
values ('Café de Teste', 'cafe', 'Centro', 1.0, 4.0);
```

Colunas não listadas recebem o valor padrão (`id` ganha um uuid novo, `dietary_options` fica vazio).

## 3.5 Arrays no Postgres

Uma coluna pode guardar uma **lista**. Escrevemos assim:

```sql
select name from establishments
where 'glutenFree' = any(dietary_options);   -- contém "sem glúten"?

select name from establishments
where dietary_options @> array['glutenFree', 'lactoseFree'];   -- contém os DOIS?
```

O operador `@>` significa "contém todos estes". É a mesma lógica do **E** das opções alimentares do material de Explorar.

---

# Parte 4: Modelando o CeliLac em tabelas

## 4.1 O ponto de partida: as entidades do Dart

O domínio do aplicativo (`lib/features/establishments/domain/entities/`) tem **quatro** tipos relevantes:

```text
Establishment                 EstablishmentDetails
  id, name, category            establishmentId, description,
  neighborhood, distanceInKm    address, phone,
  rating, dietaryOptions,       openingHours: List<OpeningHours>
  logoSource                    safetyPractices: Set<SafetyPractice>
                                photos: List<EstablishmentPhoto>
```

A pergunta da modelagem é: **como cada campo vira coluna ou tabela?**

## 4.2 A regra prática

| O campo é… | Vira… | Exemplo |
|---|---|---|
| um valor único (texto, número) | **coluna** | `name`, `rating` |
| uma lista curta de valores simples e fixos | **coluna *array*** | `dietary_options`, `safety_practices` |
| uma lista de **objetos com vários campos** | **tabela filha** | `opening_hours`, `establishment_photos` |

A tabela filha aponta para o pai por uma **chave estrangeira** (*foreign key*): uma coluna `establishment_id` que **só aceita valores que existem** em `establishments.id`.

## 4.3 O diagrama

```text
establishments (1) ──────── (0..1) establishment_details
      │
      ├────────────────────── (0..n) opening_hours
      │
      └────────────────────── (0..n) establishment_photos
```

| Tabela | Relação com `establishments` | Por quê |
|---|---|---|
| `establishment_details` | no máximo **um** por lugar | os detalhes são carregados à parte (`fetchDetails`), só quando a pessoa abre a tela |
| `opening_hours` | **vários** por lugar | um café abre de segunda a sábado e tem outro horário aos domingos |
| `establishment_photos` | **vários** por lugar | o carrossel tem de 0 a N fotos |

## 4.4 Leitura do esquema, linha a linha

O arquivo [`01_schema.sql`](./supabase/sql/01_schema.sql) tem quatro `create table`. Vamos às decisões que não são óbvias.

### Chave primária `uuid`

```sql
id uuid primary key default gen_random_uuid(),
```

- **`primary key`:** identifica a linha de forma única e nunca é nula.
- **`uuid`:** um identificador de 128 bits, como `a0000000-0000-4000-8000-000000000001`. Ao contrário de `1, 2, 3…`, ele pode ser gerado **em qualquer lugar** (inclusive no aplicativo, sem perguntar ao servidor) sem risco de repetir, e não revela quantos registros existem.
- **`default gen_random_uuid()`:** se o `insert` não informar o `id`, o banco cria um.

No Dart, o `id` continua sendo `String`: o uuid chega como texto no JSON.

### Valores fixos com `check`

```sql
category text not null
  check (category in ('restaurant', 'bakery', 'cafe', 'market')),
```

O banco **recusa** qualquer outro valor. O texto guardado é o `name` do `enum` do Dart (`EstablishmentCategory.cafe` vira `'cafe'`), de modo que o aplicativo faz `EstablishmentCategory.values.byName(row['category'])`.

> **Por que não um tipo `enum` do Postgres?** Existe, e é válido. Mas alterar um `enum` do Postgres depois é trabalhoso, e `text` com `check` é mais fácil de evoluir (basta trocar a regra).

### Listas simples com `text[]`

```sql
dietary_options text[] not null default '{}'
  check (dietary_options <@ array['glutenFree', 'lactoseFree']),
```

`<@` significa "está contido em": todos os itens da lista precisam estar entre os permitidos. `'{}'` é a lista vazia.

**Por que não uma tabela de ligação (muitos-para-muitos)?** Porque são só dois valores, fixos, sem dados próprios. Uma tabela extra traria mais código e mais junções sem nenhum ganho. Se cada opção tivesse atributos (por exemplo, uma "certificação" com validade), aí sim valeria a tabela.

### Números com precisão

```sql
distance_in_km numeric(4, 2) not null check (distance_in_km >= 0),
rating         numeric(2, 1) not null check (rating between 0 and 5),
```

`numeric(2, 1)` guarda no máximo **um** dígito antes da vírgula e **um** depois: `4.8` cabe, `48.0` não. O banco recusa uma nota 7.

> **Ficção didática.** A distância em quilômetros está na tabela para o aplicativo funcionar como hoje. Num aplicativo real, ela **não** seria uma coluna: dependeria de onde a pessoa está, e seria calculada a partir de latitude e longitude. Guardar `distance_in_km` fixo significa que "perto de você" é "perto de ninguém em particular". Aceitamos isso para manter o foco.

### Horários com `time`

```sql
weekday   smallint not null check (weekday between 1 and 7),  -- 1 = segunda
opens_at  time not null,
closes_at time not null,
check (closes_at > opens_at),
unique (establishment_id, weekday, opens_at)
```

- A `Duration` do Dart vira `time` no Postgres, e o aplicativo converte de volta.
- `weekday` segue a mesma convenção de `DateTime.weekday` do Dart (1 = segunda, 7 = domingo).
- O `check` impede horário de fechamento antes da abertura, e o `unique` impede lançar o mesmo período duas vezes.

### Segurança dos relacionamentos: `on delete cascade`

```sql
establishment_id uuid not null
  references public.establishments (id) on delete cascade,
```

- **`references`:** a chave estrangeira. Não dá para criar um horário de um lugar que não existe.
- **`on delete cascade`:** ao apagar o estabelecimento, o banco apaga também os horários, fotos e detalhes dele. Sem isso, o `delete` seria recusado enquanto houvesse filhos.

### Caminho, não URL

```sql
logo_path text,   -- 'cafe_aconchego/logo.png'
path      text not null,
```

As imagens ficam no Storage, e guardamos **o caminho do arquivo**, não o endereço completo. A URL pública contém o código do **seu** projeto (`https://abcdefgh.supabase.co/storage/...`), e o código de cada aluno é diferente. Guardando só o caminho, o mesmo seed funciona para todos, e o aplicativo monta a URL na hora com a Project URL.

> **No seu projeto:** guarde o caminho relativo e monte a URL no código quando o endereço-base puder mudar (outro projeto, outro servidor, uma CDN).

---

# Parte 5: Criando as tabelas e os dados

## 5.1 Executar o esquema

1. No painel, abra o **SQL Editor** e clique em **New query**.
2. Copie **todo** o conteúdo de [`01_schema.sql`](./supabase/sql/01_schema.sql) e cole no editor.
3. Clique em **Run**.

O resultado esperado é `Success. No rows returned`. Em seguida, abra **Table Editor**: devem aparecer as tabelas `establishments`, `establishment_details`, `opening_hours` e `establishment_photos`, todas vazias.

> Se aparecer um aviso sobre "RLS" ou "destructive operation", leia-o. O primeiro é esperado (o esquema liga o RLS de propósito). O segundo não deve aparecer neste script.

## 5.2 Carregar os dados

Em uma **nova** consulta, cole [`02_seed.sql`](./supabase/sql/02_seed.sql) e execute. Ele insere 12 estabelecimentos, 12 detalhes, 74 horários e 11 fotos.

Confira com uma consulta de contagem:

```sql
select
  (select count(*) from establishments)         as lugares,
  (select count(*) from establishment_details)  as detalhes,
  (select count(*) from opening_hours)          as horarios,
  (select count(*) from establishment_photos)   as fotos;
```

Esperado: `12 | 12 | 74 | 11`.

## 5.3 Exercícios no SQL Editor

Antes de seguir, escreva e execute estas consultas:

1. Liste o nome e a nota dos estabelecimentos com nota **a partir de 4.6**, do melhor para o pior.
2. Liste os **cafés** do bairro **Zona 7**.
3. Liste os lugares que atendem **sem glúten e sem lactose ao mesmo tempo**.
4. Liste os horários do Café Aconchego. *(Dica: `where establishment_id = 'a0000000-0000-4000-8000-000000000001'`.)*

<details>
<summary>Respostas</summary>

```sql
-- 1
select name, rating from establishments
where rating >= 4.6 order by rating desc, name;

-- 2
select name from establishments
where category = 'cafe' and neighborhood = 'Zona 7';

-- 3
select name from establishments
where dietary_options @> array['glutenFree', 'lactoseFree'];

-- 4
select weekday, opens_at, closes_at from opening_hours
where establishment_id = 'a0000000-0000-4000-8000-000000000001'
order by weekday;
```

Na consulta 2, só "Café Grão Leve" atende ao filtro. Na 3, são cinco lugares.

</details>

## 5.4 Juntando tabelas: `join`

Dados de duas tabelas na mesma resposta usam `join`:

```sql
select e.name, d.address, d.phone
from establishments e
join establishment_details d on d.establishment_id = e.id
where e.category = 'bakery';
```

`e` e `d` são apelidos. A condição `on` diz como as linhas se casam. Veremos na Parte 8 que a API REST faz o equivalente sem que você escreva o `join`.

---

# Parte 6: Segurança — Row Level Security

## 6.1 O problema

A API REST **gera endereços para todas as tabelas** do esquema `public`. E a chave pública está dentro do aplicativo, à vista de quem o desmontar. Se nada mais fosse feito, qualquer pessoa poderia chamar `POST /rest/v1/establishments` e **inserir ou apagar** lugares à vontade.

A defesa não é esconder a chave (impossível), mas **limitar o que ela pode fazer**, e isso é papel do RLS.

## 6.2 O que é

***Row Level Security*** (segurança em nível de linha) é um recurso do Postgres: com ele ligado, **cada linha é filtrada por regras** antes de chegar a quem consultou. As regras se chamam ***policies*** (políticas).

A regra de ouro:

> **Com o RLS ligado e nenhuma política, ninguém acessa nada.**

A tabela nasce **fechada**, e você abre apenas o que faz sentido. É o oposto de "tudo liberado, bloqueie o que for perigoso", e por isso é mais seguro: um esquecimento resulta em acesso negado, não em vazamento.

## 6.3 O que o esquema fez

No fim do [`01_schema.sql`](./supabase/sql/01_schema.sql):

```sql
alter table public.establishments enable row level security;

create policy "leitura publica" on public.establishments
  for select to anon, authenticated using (true);
```

Leitura, parte por parte:

| Trecho | Significado |
|---|---|
| `enable row level security` | fecha a tabela |
| `create policy "leitura publica"` | dá um nome à regra |
| `for select` | vale **só** para leitura. Não há regra para `insert`, `update` ou `delete`, então esses continuam **proibidos** |
| `to anon, authenticated` | vale para visitantes sem login (`anon`) e para pessoas logadas (`authenticated`) |
| `using (true)` | a condição por linha: `true` = **todas** as linhas |

Para um caso real, o `using` teria uma condição. Por exemplo, num futuro perfil sincronizado: `using (auth.uid() = user_id)` ("só a linha cujo dono sou eu").

## 6.4 Ver as políticas no painel

No painel, abra **Authentication → Policies** (ou o ícone de cadeado na tabela, no *Table Editor*). Cada tabela mostra as suas políticas. Confirme que as quatro têm "leitura publica".

## 6.5 A armadilha do RLS ligado sem política

Experimente, para entender o sintoma. No SQL Editor:

```sql
drop policy "leitura publica" on public.establishments;
```

Agora, na Parte 8, a API devolveria `[]` (lista vazia), **sem nenhum erro**. É um dos sintomas mais confusos para quem começa: "a tabela está cheia, mas o aplicativo recebe uma lista vazia". A causa é o RLS filtrando todas as linhas.

Recrie a política antes de continuar:

```sql
create policy "leitura publica" on public.establishments
  for select to anon, authenticated using (true);
```

> **Dica de diagnóstico:** o SQL Editor do painel executa com um papel privilegiado e **ignora o RLS**, então a consulta funciona ali e falha na API. Se "funciona no painel, mas não no aplicativo", suspeite do RLS.

---

# Parte 7: Storage — as imagens

## 7.1 O que é um *bucket*

O Storage organiza arquivos em ***buckets*** ("baldes"), parecidos com pastas de nível superior. O esquema já criou um, `establishments`, marcado como **público**:

```sql
insert into storage.buckets (id, name, public)
values ('establishments', 'establishments', true);
```

**Público** quer dizer que qualquer pessoa com o endereço do arquivo consegue **baixá-lo**, sem login e sem chave. Isso serve para logos e fotos de divulgação. Para documentos pessoais, usaríamos um *bucket* privado com URLs temporárias assinadas.

Mesmo num *bucket* público, **enviar** arquivos exige permissão. Como não criamos nenhuma política de escrita, só você (pelo painel) consegue subir arquivos.

## 7.2 Enviar as imagens

1. No painel, abra **Storage** e clique no *bucket* `establishments`.
2. Crie as pastas (**Create folder**) com os mesmos nomes de `assets/images/establishments/`:
   `cafe_aconchego`, `padaria_leve_grao`, `bistro_bem_estar` e `emporio_natural`.
3. Entre em cada pasta e arraste os arquivos correspondentes:

| Pasta | Arquivos |
|---|---|
| `cafe_aconchego` | `logo.png`, `photo_1.jpg`, `photo_2.jpg`, `photo_3.jpg` |
| `padaria_leve_grao` | `logo.png`, `photo_1.jpg`, `photo_2.jpg`, `photo_3.jpg` |
| `bistro_bem_estar` | `logo.png`, `photo_1.jpg`, `photo_2.jpg`, `photo_3.jpg` |
| `emporio_natural` | `photo_1.jpg`, `photo_2.jpg` |

Os caminhos precisam ser **idênticos** aos que o seed gravou (`cafe_aconchego/logo.png` etc.), com a mesma grafia, inclusive maiúsculas e minúsculas.

## 7.3 A URL pública

O formato é sempre o mesmo:

```text
https://<codigo-do-projeto>.supabase.co/storage/v1/object/public/<bucket>/<caminho>
```

Exemplo:

```text
https://abcdefgh.supabase.co/storage/v1/object/public/establishments/cafe_aconchego/logo.png
```

Cole a sua versão no navegador. A imagem deve abrir. Se aparecer um JSON com `"error": "Bucket not found"` ou `"Object not found"`, o *bucket*, a pasta ou o nome do arquivo estão diferentes do esperado.

> **Os outros oito estabelecimentos continuam sem imagem**, como no aplicativo hoje: o seed deixa `logo_path` nulo e não cria fotos para eles. O aplicativo já sabe desenhar o *fallback* com o ícone da categoria.

---

# Parte 8: Consultando a API REST

Aqui está a recompensa: o JSON que o aplicativo vai ler, visto antes de qualquer Dart.

## 8.1 Anatomia de uma chamada

Todas as chamadas seguem o molde:

```text
GET  <Project URL>/rest/v1/<tabela>?<parâmetros>
Headers:
  apikey: <chave pública>
  Authorization: Bearer <chave pública>
```

Para não repetir a URL e a chave em cada comando, guarde-as em variáveis do terminal (substitua pelos **seus** valores):

```bash
export SUPABASE_URL="https://abcdefgh.supabase.co"
export SUPABASE_KEY="sua-chave-publica"
```

> **Dica:** `curl -s` esconde a barra de progresso; encadear com `| jq` (se tiver o `jq` instalado) ou `| python3 -m json.tool` formata o resultado.

## 8.2 Todos os lugares

```bash
curl -s "$SUPABASE_URL/rest/v1/establishments?select=*" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY"
```

Resposta (resumida):

```json
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
  }
]
```

Compare com a entidade `Establishment`: cada chave do JSON corresponde a um campo, com `snake_case` no lugar de `camelCase`. A tradução entre os dois é o trabalho do material seguinte.

## 8.3 Escolher colunas, filtrar e ordenar

Os parâmetros da URL fazem o papel do SQL:

| Em SQL | Na URL | Exemplo |
|---|---|---|
| `select name, rating` | `select=name,rating` | `?select=name,rating` |
| `where category = 'cafe'` | `category=eq.cafe` | `?category=eq.cafe` |
| `where rating >= 4.6` | `rating=gte.4.6` | `?rating=gte.4.6` |
| `where name ilike '%café%'` | `name=ilike.*café*` | `?name=ilike.*caf*` |
| `where dietary_options @> ...` | `dietary_options=cs.{glutenFree}` | `?dietary_options=cs.{glutenFree,lactoseFree}` |
| `order by rating desc` | `order=rating.desc` | `?order=rating.desc,name` |
| `limit 3` | `limit=3` | `?limit=3` |

Os operadores têm abreviações: `eq` (igual), `neq`, `gt`, `gte`, `lt`, `lte`, `ilike`, `cs` (*contains*, o `@>`), `in`.

Combinando vários, em um só pedido:

```bash
curl -s -G "$SUPABASE_URL/rest/v1/establishments" \
  --data-urlencode "select=name,rating,neighborhood" \
  --data-urlencode "category=eq.cafe" \
  --data-urlencode "order=rating.desc" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY"
```

O `-G` junto de `--data-urlencode` monta a query string codificada (acentos e espaços incluídos).

## 8.4 Dados relacionados em uma chamada

O ponto alto: como as tabelas têm **chaves estrangeiras**, a API entende os relacionamentos e **embute** os filhos na resposta, sem que você escreva um `join`:

```bash
curl -s -G "$SUPABASE_URL/rest/v1/establishments" \
  --data-urlencode "id=eq.a0000000-0000-4000-8000-000000000001" \
  --data-urlencode "select=name,establishment_details(address,phone,safety_practices),opening_hours(weekday,opens_at,closes_at),establishment_photos(position,path,description)" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY"
```

Resposta (resumida):

```json
[
  {
    "name": "Café Aconchego",
    "establishment_details": {
      "address": "Rua das Palmeiras, 120 - Centro",
      "phone": "(44) 0000-0101",
      "safety_practices": ["separateKitchen", "exclusiveUtensils", "trainedStaff", "ingredientList"]
    },
    "opening_hours": [
      { "weekday": 1, "opens_at": "07:00:00", "closes_at": "19:00:00" }
    ],
    "establishment_photos": [
      { "position": 1, "path": "cafe_aconchego/photo_1.jpg", "description": "Salão do café…" }
    ]
  }
]
```

Observe a forma de cada relacionamento:

- `establishment_details` é um **objeto** (relação 1:1, pois a chave primária da tabela filha é a própria chave estrangeira).
- `opening_hours` e `establishment_photos` são **listas** (relação 1:N).

Essa **única** chamada devolve o equivalente ao `EstablishmentDetails` completo. Ela pode ser exatamente o que o `fetchDetails` fará no aplicativo.

> **Horários vêm como texto.** `"07:00:00"` é o jeito do JSON de representar `time`. O aplicativo precisará converter para `Duration`: uma das tarefas do material seguinte.

## 8.5 Provando o RLS

Tente **inserir** um lugar usando só a chave pública:

```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/establishments" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Invasor","category":"cafe","neighborhood":"X","distance_in_km":1,"rating":5}'
```

Resposta esperada:

```json
{
  "code": "42501",
  "message": "new row violates row-level security policy for table \"establishments\""
}
```

O banco **recusou**. A chave pública só tem a política de leitura, e nenhuma de escrita. É exatamente o que queríamos.

Agora uma surpresa: tente **apagar**.

```bash
curl -s -i -X DELETE "$SUPABASE_URL/rest/v1/establishments?name=eq.Caf%C3%A9%20Aconchego" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY"
```

A resposta pode ser um sucesso (`204`), mas confira no painel: **o café continua lá**. Para `update` e `delete`, o RLS não devolve erro: ele simplesmente **filtra as linhas alcançáveis**, e como nenhuma é permitida, **zero** linhas são afetadas. Só o `insert` falha de forma explícita.

> **Lição:** não confie no código HTTP para saber se um `update` ou `delete` valeu. Peça de volta as linhas afetadas (`Prefer: return=representation`) e veja se a lista veio vazia.

## 8.6 Erros comuns na chamada

| Resposta | Causa provável |
|---|---|
| `{"message":"No API key found in request"}` | faltou o cabeçalho `apikey` |
| `{"message":"Invalid API key"}` | chave copiada com espaço sobrando ou de outro projeto |
| `[]` (lista vazia) | tabela vazia **ou** RLS sem política (Parte 6.5) |
| `{"code":"PGRST205", "message":"Could not find the table…"}` | nome da tabela errado, ou o esquema não foi criado |
| `{"code":"PGRST200"}` ao embutir | a relação por chave estrangeira não existe ou o nome está errado |
| `curl: (6) Could not resolve host` | `SUPABASE_URL` vazia ou errada |
| a chamada demora ou falha depois de dias parada | projeto gratuito hibernando (Parte 2.2) |

---

# Parte 9: Revisão

## 9.1 O que construímos

```text
Supabase (seu projeto)
├── Postgres
│   ├── establishments            12 linhas
│   ├── establishment_details     12 linhas (1:1)
│   ├── opening_hours             74 linhas (1:N)
│   └── establishment_photos      11 linhas (1:N)
├── RLS: leitura pública, nenhuma escrita
├── Storage: bucket "establishments" (público) com as imagens
└── API REST: gerada sozinha, testada com curl
```

## 9.2 Resumo das decisões

| Decisão | Motivo |
|---|---|
| Postgres via Supabase | SQL padrão de mercado; dados portáveis |
| `uuid` como chave primária | gerado em qualquer lugar; não revela volume |
| `text[]` para opções e práticas | listas curtas e fixas; sem tabela de ligação |
| Tabelas filhas para horários e fotos | listas de objetos com vários campos |
| `check` em categorias, notas e horários | o banco recusa dado inválido, não só o aplicativo |
| `on delete cascade` | apagar o lugar apaga o que depende dele |
| Caminho, não URL, para imagens | a URL depende do projeto |
| RLS ligado, só `select` liberado | "fechado por padrão" é mais seguro |
| Chave pública no aplicativo, secreta nunca | a pública só pode o que o RLS deixa |

## 9.3 Armadilhas encontradas

| Sintoma | Causa | Correção |
|---|---|---|
| API devolve `[]` com a tabela cheia | RLS ligado sem política de leitura | criar a política `for select` |
| Funciona no SQL Editor, falha na API | o painel ignora o RLS | testar sempre com `curl` e a chave pública |
| `delete` responde sucesso e nada some | RLS filtra linhas silenciosamente | conferir as linhas afetadas |
| Imagem não abre pela URL | caminho do arquivo diferente do gravado no seed | igualar pasta, nome e extensão |
| `violates check constraint` no `insert` | valor fora do permitido (`'Café'` em vez de `'cafe'`) | usar exatamente os nomes dos `enum` |
| Chave secreta no repositório | copiada "para testar" | revogar no painel, gerar outra |
| App parado depois de dias | projeto gratuito hibernou | *Restore project* |

## 9.4 O que ficou de fora

| Assunto | Quando |
|---|---|
| **Auth** (cadastro e login) | para sincronizar o perfil alimentar entre aparelhos, em um material futuro |
| **Realtime** | atualização ao vivo; não é necessária para um catálogo |
| **Edge Functions** | lógica própria no servidor, como cálculo de distância |
| **Migrações versionadas** (`supabase` CLI) | para equipes; aqui rodamos os scripts à mão |
| **Escrita pelo aplicativo** | cadastrar lugares exigiria login e políticas de escrita |

## 9.5 Outras opções do ecossistema

| Necessidade | Opções |
|---|---|
| BaaS com banco relacional | Supabase, Neon + API própria, Appwrite |
| BaaS com documentos | Firebase (Firestore), Appwrite |
| Banco local em arquivo, tudo no aparelho | SQLite (usado nos Favoritos), Drift, Isar |
| API própria | Node/NestJS, Python/FastAPI, .NET, Spring |

---

# Parte 10: Aplicando no seu projeto

## 10.1 Roteiro

1. **Liste as entidades** do domínio do seu aplicativo e os campos de cada uma.
2. Para cada campo, aplique a regra da Parte 4.2: **coluna**, ***array*** ou **tabela filha**.
3. Escolha chaves (`uuid`), restrições (`check`, `not null`, `unique`) e relações (`references … on delete cascade`).
4. Escreva o **esquema** e o **seed** em arquivos `.sql` versionados no repositório, não só no painel: quem clonar o projeto precisa reproduzi-lo.
5. Ligue o **RLS** em todas as tabelas, **antes** de inserir dados reais, e crie só as políticas de que o aplicativo precisa.
6. **Teste a API com `curl`** antes do Flutter: se o JSON está certo ali, qualquer erro depois é do aplicativo.

## 10.2 Adaptando ao tema do seu aplicativo

| Tema | Tabela principal | Tabelas filhas | Arrays |
|---|---|---|---|
| Catálogo de cursos | `courses` | `lessons`, `instructors` | `tags` |
| Imobiliária estudantil | `listings` | `photos`, `visits` | `amenities` |
| Receitas | `recipes` | `ingredients`, `steps` | `diet_labels` |
| Clínicas | `clinics` | `specialties`, `schedules` | `accepted_plans` |
| Vagas de estágio | `jobs` | `requirements`, `benefits` | `skills` |

## 10.3 Checklist

- [ ] **Esquema e seed** em arquivos `.sql` no repositório.
- [ ] **Chaves primárias** `uuid` e chaves estrangeiras com `on delete cascade` onde fizer sentido.
- [ ] **Restrições** (`check`, `not null`, `unique`) para o banco recusar dado inválido.
- [ ] **RLS ligado em todas as tabelas**, com políticas explícitas.
- [ ] **Chave secreta fora** do aplicativo e do Git.
- [ ] **Imagens** no Storage, com **caminhos** no banco, não URLs completas.
- [ ] **Chamadas de teste** com `curl`: lista, filtro, relacionamento, e um `insert` recusado.

## 10.4 Desafios opcionais

1. **Nova tabela:** crie `reviews` (`establishment_id`, `author_name`, `rating`, `comment`, `created_at`), com uma política de leitura pública, e insira três avaliações pelo SQL Editor. Como a API as devolve embutidas em `establishments`?
2. **Restrição nova:** impeça que `rating` seja guardado com mais de uma casa decimal. Qual tipo ou `check` resolve?
3. **Consulta com `join`:** liste, em SQL, o nome e o endereço dos estabelecimentos que abrem **aos domingos**. *(Dica: `opening_hours.weekday = 7`.)*
4. **Equivalente na API:** repita o desafio 3 usando só parâmetros de URL. Quais filtros em tabelas embutidas a API oferece (`opening_hours!inner(...)`)?
5. **Discussão:** o catálogo é público, mas e se cada lugar tivesse um **dono** que edita os próprios dados? Escreva, em português, a política de `update` que seria necessária e o que o aplicativo precisaria ter antes disso.

---

# Apêndice A: Solução de problemas

| Sintoma / mensagem | Causa provável | Como corrigir |
|---|---|---|
| `relation "establishments" does not exist` | o `01_schema.sql` não foi executado, ou foi num projeto diferente | rodar o esquema no projeto certo |
| `relation "establishments" already exists` | o esquema foi executado duas vezes | apagar as tabelas (`drop table … cascade`) e repetir, ou ignorar |
| `duplicate key value violates unique constraint` no seed | o seed foi executado duas vezes | limpar com `truncate establishments cascade;` e repetir |
| `function gen_random_uuid() does not exist` | Postgres muito antigo (raro no Supabase) | habilitar a extensão `pgcrypto` |
| `Invalid API key` | chave copiada com espaço, quebra de linha ou de outro projeto | copiar de novo, entre aspas |
| `[]` na API, dados no painel | RLS sem política de leitura | Parte 6.5 |
| Imagem "Object not found" | pasta ou nome diferente do gravado no seed | conferir a Parte 7.2 |
| `new row violates row-level security policy` | tentativa de escrita sem política | esperado; é a segurança funcionando |
| Projeto "Paused" | inatividade no plano gratuito | *Restore project* |

# Apêndice B: Glossário

- **BaaS (*Backend as a Service*):** serviço que oferece banco, API, autenticação e arquivos prontos para uso.
- **Postgres (PostgreSQL):** banco de dados relacional de código aberto, base do Supabase.
- **Tabela, linha, coluna:** estrutura de armazenamento do banco relacional.
- **Chave primária (*primary key*):** coluna que identifica cada linha de forma única.
- **Chave estrangeira (*foreign key*):** coluna que referencia a chave primária de outra tabela.
- **`uuid`:** identificador universal de 128 bits, gerável sem consultar o servidor.
- **`check`:** restrição que valida o valor de uma coluna a cada gravação.
- **`on delete cascade`:** apagar o registro pai apaga os filhos.
- **API REST:** conjunto de endereços HTTP que leem e gravam recursos.
- **PostgREST:** o componente que gera a API REST a partir das tabelas do Postgres.
- **JSON:** formato de texto para dados estruturados, o que a API devolve.
- **RLS (*Row Level Security*):** filtro por linha aplicado pelo próprio banco.
- **Política (*policy*):** regra de RLS que diz quem pode fazer o quê com quais linhas.
- **`anon` e `authenticated`:** papéis do Postgres para visitantes sem login e pessoas logadas.
- **Chave pública (*publishable* ou *anon*):** chave que identifica o projeto e respeita o RLS; pode ir no aplicativo.
- **Chave secreta (*secret* ou *service_role*):** chave que ignora o RLS; **nunca** vai no aplicativo.
- **Storage / *bucket*:** serviço e "balde" de arquivos do Supabase.
- **Seed:** script que carrega dados iniciais.
- **`join`:** junção de linhas de duas tabelas por uma condição.
- **Embutir (*embedding*):** pedir à API que inclua registros relacionados dentro da resposta.
