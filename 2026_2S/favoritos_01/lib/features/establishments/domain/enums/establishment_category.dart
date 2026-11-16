enum EstablishmentCategory {
  restaurant('Restaurante'),
  cafe('Café'),
  bakery('Padaria'),
  market('Mercado');

  const EstablishmentCategory(this.displayName);

  final String displayName;
}
