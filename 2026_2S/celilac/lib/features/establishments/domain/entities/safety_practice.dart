enum SafetyPractice {
  separateKitchen('Área de preparo separada para itens sem glúten'),
  exclusiveUtensils('Utensílios exclusivos para itens sem glúten'),
  trainedStaff('Equipe treinada em restrições alimentares'),
  ingredientList('Lista de ingredientes disponível para consulta');

  const SafetyPractice(this.label);

  final String label;
}
