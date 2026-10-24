import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/domain/entities/dietary_option.dart';
import '../dietary_option_labels.dart';

class RestrictionsField extends FormField<Set<DietaryOption>> {
  RestrictionsField({
    super.key,
    required Set<DietaryOption> super.initialValue,
    required ValueChanged<Set<DietaryOption>> onChanged,
  }) : super(
         validator: (value) => (value == null || value.isEmpty)
             ? 'Escolha pelo menos uma opção.'
             : null,
         builder: (state) {
           final selected = state.value ?? const <DietaryOption>{};
           final error = state.errorText;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               for (final option in DietaryOption.values)
                 CheckboxListTile(
                   value: selected.contains(option),
                   title: Text(option.avoidLabel),
                   controlAffinity: ListTileControlAffinity.leading,
                   contentPadding: EdgeInsets.zero,
                   onChanged: (checked) {
                     final next = {...selected};
                     if (checked ?? false) {
                       next.add(option);
                     } else {
                       next.remove(option);
                     }
                     state.didChange(next);
                     onChanged(next);
                   },
                 ),
               if (error != null)
                 Padding(
                   padding: const EdgeInsets.only(top: AppSpacing.xs),
                   // liveRegion: o leitor de tela anuncia o erro quando ele
                   // aparece, sem a pessoa precisar procurá-lo.
                   child: Semantics(
                     liveRegion: true,
                     child: Text(
                       error,
                       style: Theme.of(state.context).textTheme.bodySmall
                           ?.copyWith(
                             color: Theme.of(state.context).colorScheme.error,
                           ),
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
