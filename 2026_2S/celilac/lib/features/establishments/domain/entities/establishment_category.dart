enum EstablishmentCategory {
  restaurant('Restaurante'),
  bakery('Padaria'),
  cafe('Café'),
  market('Mercado');

  const EstablishmentCategory(this.label);

  final String label;
}
