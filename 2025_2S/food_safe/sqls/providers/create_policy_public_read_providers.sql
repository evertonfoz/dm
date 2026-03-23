-- Habilita Row Level Security e cria policy de leitura pública para providers
alter table public.providers enable row level security;

create policy "public read providers"
  on public.providers
  for select
  to anon
  using (true);
