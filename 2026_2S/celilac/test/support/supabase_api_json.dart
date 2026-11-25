// Respostas da API REST do Supabase, como texto, do jeito que chegam pela rede.
// Partem do material 7 (Introdução ao Supabase, Parte 8) e dos dados do
// 02_seed.sql. Os testes não acessam a internet: estes textos fazem o papel
// do servidor.

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

/// `GET /rest/v1/establishments?id=eq.{id}&select=id,establishment_details(...),
/// opening_hours(...),establishment_photos(...)`  (Parte 8.4, completa)
const cafeAconchegoDetailsResponseJson = '''
[
  {
    "id": "a0000000-0000-4000-8000-000000000001",
    "establishment_details": {
      "description": "Café de bairro com cardápio próprio sem glúten e sem lactose: pães de fermentação natural, bolos caseiros e bebidas vegetais.",
      "address": "Rua das Palmeiras, 120 - Centro",
      "phone": "(44) 0000-0101",
      "safety_practices": ["separateKitchen", "exclusiveUtensils", "trainedStaff", "ingredientList"]
    },
    "opening_hours": [
      { "weekday": 1, "opens_at": "07:00:00", "closes_at": "19:00:00" },
      { "weekday": 2, "opens_at": "07:00:00", "closes_at": "19:00:00" },
      { "weekday": 3, "opens_at": "07:00:00", "closes_at": "19:00:00" },
      { "weekday": 4, "opens_at": "07:00:00", "closes_at": "19:00:00" },
      { "weekday": 5, "opens_at": "07:00:00", "closes_at": "19:00:00" },
      { "weekday": 6, "opens_at": "07:00:00", "closes_at": "19:00:00" },
      { "weekday": 7, "opens_at": "08:00:00", "closes_at": "12:00:00" }
    ],
    "establishment_photos": [
      { "position": 1, "path": "cafe_aconchego/photo_1.jpg", "description": "Salão do café com mesas de madeira e luz natural" },
      { "position": 2, "path": "cafe_aconchego/photo_2.jpg", "description": "Vitrine com pães de fermentação natural e bolos caseiros" },
      { "position": 3, "path": "cafe_aconchego/photo_3.jpg", "description": "Café com bebida vegetal e uma fatia de bolo" }
    ]
  }
]
''';

/// Um dos oito lugares sem imagens e sem telefone.
const emporioDaTerraDetailsResponseJson = '''
[
  {
    "id": "a0000000-0000-4000-8000-000000000012",
    "establishment_details": {
      "description": "Empório com grãos, farinhas e snacks sem glúten.",
      "address": "Rua da Colheita, 9 - Zona 7",
      "phone": null,
      "safety_practices": ["ingredientList"]
    },
    "opening_hours": [
      { "weekday": 1, "opens_at": "09:00:00", "closes_at": "18:00:00" }
    ],
    "establishment_photos": []
  }
]
''';

/// URL pública que o Storage monta para um caminho do bucket.
String testPublicUrl(String path) =>
    '$testSupabaseUrl/storage/v1/object/public/establishments/$path';
