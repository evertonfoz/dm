import 'package:flutter/material.dart';

import '../models/pet_entity.dart';

class PetCard extends StatelessWidget {
  final PetEntity pet;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;
  final Widget? trailing;

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.onInfoTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(child: Text(pet.name[0])),
        title: Text(pet.name),
        subtitle: Text('${pet.specie.name} - ${pet.age} anos'),
        trailing:
            trailing ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pet.isPriority)
                  const Icon(Icons.priority_high, color: Colors.red),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: onInfoTap,
                ),
              ],
            ),
        onTap: onTap,
      ),
    );
  }
}
