-- CeliLac: dados fictícios (rode DEPOIS do 01_schema.sql)
-- Reproduz o catálogo do FakeEstablishmentRepository.

-- Para o seed ser repetível, os 12 lugares recebem uuids fixos e legíveis
-- (...0001 a ...0012). Em produção, deixe o banco gerar (gen_random_uuid()).
-- A função abaixo é só um atalho para este arquivo e é apagada no fim.
create function public.seed_id(n int) returns uuid
language sql immutable as $$
  select ('a0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;

insert into public.establishments
  (id, name, category, neighborhood, distance_in_km, rating, dietary_options, logo_path)
values
  (public.seed_id(1),  'Café Aconchego',          'cafe',       'Centro',            0.35, 4.8, '{glutenFree,lactoseFree}', 'cafe_aconchego/logo.png'),
  (public.seed_id(2),  'Padaria Leve Grão',       'bakery',     'Jardim das Flores', 1.20, 4.6, '{glutenFree}',             'padaria_leve_grao/logo.png'),
  (public.seed_id(3),  'Bistrô Bem-Estar',        'restaurant', 'Bela Vista',        2.40, 4.7, '{glutenFree,lactoseFree}', 'bistro_bem_estar/logo.png'),
  (public.seed_id(4),  'Empório Natural',         'market',     'Vila Nova',         3.10, 4.5, '{lactoseFree}',            null),
  (public.seed_id(5),  'Cozinha da Vó Lúcia',     'restaurant', 'Zona 7',            0.80, 4.4, '{glutenFree}',             null),
  (public.seed_id(6),  'Pão de Quinoa',           'bakery',     'Centro',            0.60, 4.9, '{glutenFree,lactoseFree}', null),
  (public.seed_id(7),  'Café Grão Leve',          'cafe',       'Zona 7',            1.90, 4.2, '{lactoseFree}',            null),
  (public.seed_id(8),  'Mercado Vida Simples',    'market',     'Jardim das Flores', 1.50, 4.3, '{glutenFree,lactoseFree}', null),
  (public.seed_id(9),  'Trattoria Sem Trigo',     'restaurant', 'Vila Nova',         2.80, 4.6, '{glutenFree}',             null),
  (public.seed_id(10), 'Doce Pureza Confeitaria', 'bakery',     'Bela Vista',        3.40, 4.7, '{lactoseFree}',            null),
  (public.seed_id(11), 'Café Pé de Serra',        'cafe',       'Bela Vista',        4.20, 4.1, '{glutenFree,lactoseFree}', null),
  (public.seed_id(12), 'Empório da Terra',        'market',     'Zona 7',            5.00, 4.0, '{glutenFree}',             null);


insert into public.establishment_details
  (establishment_id, description, address, phone, safety_practices)
values
  (public.seed_id(1), 'Café de bairro com cardápio próprio sem glúten e sem lactose: pães de fermentação natural, bolos caseiros e bebidas vegetais.',
      'Rua das Palmeiras, 120 - Centro', '(44) 0000-0101',
      '{separateKitchen,exclusiveUtensils,trainedStaff,ingredientList}'),
  (public.seed_id(2), 'Padaria com linha completa sem glúten, produzida em área separada, com pães, salgados e encomendas de bolos.',
      'Avenida das Hortênsias, 455 - Jardim das Flores', '(44) 0000-0202',
      '{separateKitchen,exclusiveUtensils,ingredientList}'),
  (public.seed_id(3), 'Restaurante com pratos do dia adaptáveis no almoço e jantar às sextas e sábados. Avise a equipe sobre a sua restrição ao pedir.',
      'Rua Coronel Silva, 980 - Bela Vista', '(44) 0000-0303',
      '{trainedStaff,ingredientList}'),
  (public.seed_id(4), 'Mercado de produtos naturais com um corredor dedicado a itens sem lactose e bebidas vegetais.',
      'Rua Marechal Deodoro, 31 - Vila Nova', null,
      '{ingredientList}'),
  (public.seed_id(5), 'Cozinha caseira com pratos do dia sem glúten.',
      'Rua Pioneiro, 210 - Zona 7', null, '{trainedStaff}'),
  (public.seed_id(6), 'Padaria especializada em pães sem glúten e sem lactose.',
      'Rua das Acácias, 48 - Centro', null, '{separateKitchen,exclusiveUtensils}'),
  (public.seed_id(7), 'Café com bebidas vegetais e bolos sem lactose.',
      'Avenida Brasil, 1500 - Zona 7', null, '{ingredientList}'),
  (public.seed_id(8), 'Mercado de bairro com seção de alimentos especiais.',
      'Rua das Flores, 77 - Jardim das Flores', null, '{ingredientList}'),
  (public.seed_id(9), 'Massas artesanais feitas sem trigo.',
      'Rua Paraná, 640 - Vila Nova', null, '{separateKitchen,trainedStaff}'),
  (public.seed_id(10), 'Confeitaria de doces sem lactose sob encomenda.',
      'Rua Ipê, 15 - Bela Vista', null, '{ingredientList}'),
  (public.seed_id(11), 'Café de serra com opções sem glúten e sem lactose.',
      'Estrada do Café, 300 - Bela Vista', null, '{exclusiveUtensils}'),
  (public.seed_id(12), 'Empório com grãos, farinhas e snacks sem glúten.',
      'Rua da Colheita, 9 - Zona 7', null, '{ingredientList}');

-- Horários: "unnest" transforma o array de dias em uma linha por dia.
insert into public.opening_hours (establishment_id, weekday, opens_at, closes_at)
select public.seed_id(1), d, '07:00'::time, '19:00'::time from unnest(array[1,2,3,4,5,6]) as d
union all select public.seed_id(1), 7, '08:00', '12:00'
union all select public.seed_id(2), d, '06:30', '13:00' from unnest(array[2,3,4,5,6,7]) as d
union all select public.seed_id(3), d, '11:30', '15:00' from unnest(array[2,3,4,5,6]) as d
union all select public.seed_id(3), d, '19:00', '23:00' from unnest(array[5,6]) as d
union all select public.seed_id(4), d, '09:00', '20:00' from unnest(array[1,2,3,4,5,6]) as d
union all select public.seed_id(e), d, '09:00', '18:00'
          from generate_series(5, 12) as e, unnest(array[1,2,3,4,5,6]) as d;

insert into public.establishment_photos (establishment_id, position, path, description)
values
  (public.seed_id(1), 1, 'cafe_aconchego/photo_1.jpg',     'Salão do café com mesas de madeira e luz natural'),
  (public.seed_id(1), 2, 'cafe_aconchego/photo_2.jpg',     'Vitrine com pães de fermentação natural e bolos caseiros'),
  (public.seed_id(1), 3, 'cafe_aconchego/photo_3.jpg',     'Café com bebida vegetal e uma fatia de bolo'),
  (public.seed_id(2), 1, 'padaria_leve_grao/photo_1.jpg',  'Prateleiras com pães variados'),
  (public.seed_id(2), 2, 'padaria_leve_grao/photo_2.jpg',  'Área de preparo separada com utensílios exclusivos'),
  (public.seed_id(2), 3, 'padaria_leve_grao/photo_3.jpg',  'Bandeja de salgados assados'),
  (public.seed_id(3), 1, 'bistro_bem_estar/photo_1.jpg',   'Salão do bistrô arrumado para o almoço'),
  (public.seed_id(3), 2, 'bistro_bem_estar/photo_2.jpg',   'Prato do dia com frango grelhado, arroz, feijão e salada'),
  (public.seed_id(3), 3, 'bistro_bem_estar/photo_3.jpg',   'Ambiente do jantar, à meia-luz'),
  (public.seed_id(4), 1, 'emporio_natural/photo_1.jpg',    'Corredor de bebidas vegetais'),
  (public.seed_id(4), 2, 'emporio_natural/photo_2.jpg',    'Grãos e castanhas a granel');

drop function public.seed_id(int);
