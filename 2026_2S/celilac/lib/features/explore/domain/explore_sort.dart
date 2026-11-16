enum ExploreSort {
  distance('Mais perto'),
  rating('Melhor nota'),
  name('Nome (A–Z)');

  const ExploreSort(this.label);

  final String label;
}
