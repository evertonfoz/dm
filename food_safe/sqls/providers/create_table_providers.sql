-- Schema mínimo preparado para sync incremental
create table if not exists public.providers (
  id bigserial primary key,
  name text not null,
  image_url text null, -- URL pública/signed do Storage
  brand_color_hex varchar(9) null, -- ex: #22AA88
  rating numeric(2,1) not null default 0.0, -- 0.0..5.0
  distance_km numeric(6,2) null, -- estimativa
  metadata jsonb null, -- tags, featured, selos, etc.
  updated_at timestamptz not null default now()
);


-- Ajuda no filtro "updated_at > :last_sync"
create index if not exists idx_providers_updated_at on public.providers(updated_at desc);
