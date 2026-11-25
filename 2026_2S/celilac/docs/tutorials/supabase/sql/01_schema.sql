-- CeliLac: esquema do banco (rode no SQL Editor do Supabase)
-- Os nomes das colunas seguem snake_case; os valores de texto de
-- `category`, `dietary_options` e `safety_practices` são os nomes dos
-- enums do Dart (EstablishmentCategory, DietaryOption, SafetyPractice).

-- 1. Lista: um registro por estabelecimento (entidade Establishment)
create table public.establishments (
  id               uuid primary key default gen_random_uuid(),
  name             text    not null,
  category         text    not null
    check (category in ('restaurant', 'bakery', 'cafe', 'market')),
  neighborhood     text    not null,
  -- Ficção didática: numa API real, a distância seria calculada a partir
  -- de latitude/longitude e da posição de quem consulta.
  distance_in_km   numeric(4, 2) not null check (distance_in_km >= 0),
  rating           numeric(2, 1) not null check (rating between 0 and 5),
  dietary_options  text[]  not null default '{}'
    check (dietary_options <@ array['glutenFree', 'lactoseFree']),
  -- Caminho do arquivo no Storage (bucket "establishments"), não a URL
  -- completa: a URL muda de projeto para projeto.
  logo_path        text
);

-- 2. Detalhe: no máximo um por estabelecimento (EstablishmentDetails)
create table public.establishment_details (
  establishment_id uuid primary key
    references public.establishments (id) on delete cascade,
  description      text   not null,
  address          text   not null,
  phone            text,
  safety_practices text[] not null default '{}'
    check (safety_practices <@ array[
      'separateKitchen', 'exclusiveUtensils',
      'trainedStaff', 'ingredientList'
    ])
);

-- 3. Horários: vários por estabelecimento (OpeningHours)
create table public.opening_hours (
  id               uuid primary key default gen_random_uuid(),
  establishment_id uuid not null
    references public.establishments (id) on delete cascade,
  weekday          smallint not null check (weekday between 1 and 7), -- 1 = segunda
  opens_at         time not null,
  closes_at        time not null,
  check (closes_at > opens_at),
  unique (establishment_id, weekday, opens_at)
);

-- 4. Fotos: várias por estabelecimento (EstablishmentPhoto)
create table public.establishment_photos (
  id               uuid primary key default gen_random_uuid(),
  establishment_id uuid not null
    references public.establishments (id) on delete cascade,
  position         smallint not null,
  path             text not null,   -- caminho no Storage
  description      text not null,
  unique (establishment_id, position)
);

create index on public.opening_hours (establishment_id);
create index on public.establishment_photos (establishment_id);

-- 5. Segurança (RLS): toda tabela nasce FECHADA. Aqui liberamos só a
-- leitura; ninguém, com a chave anon, consegue inserir, alterar ou apagar.
alter table public.establishments         enable row level security;
alter table public.establishment_details  enable row level security;
alter table public.opening_hours          enable row level security;
alter table public.establishment_photos   enable row level security;

create policy "leitura publica" on public.establishments
  for select to anon, authenticated using (true);
create policy "leitura publica" on public.establishment_details
  for select to anon, authenticated using (true);
create policy "leitura publica" on public.opening_hours
  for select to anon, authenticated using (true);
create policy "leitura publica" on public.establishment_photos
  for select to anon, authenticated using (true);

-- 6. Storage: bucket público só para leitura dos arquivos
insert into storage.buckets (id, name, public)
values ('establishments', 'establishments', true)
on conflict (id) do nothing;
