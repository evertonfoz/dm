enum ExploreSort {
  rating('Melhor nota'),
  distance('Distância'),
  name('Nome (A-Z)');

  const ExploreSort(this.displayName);

  final String displayName;
}
