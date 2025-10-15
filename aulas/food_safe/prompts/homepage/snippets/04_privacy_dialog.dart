// // Snippet: 04_privacy_dialog.dart
// // Função que cria o diálogo de privacidade; cole em HomePage ou extraia para widget

// void showPrivacyDialog(
//   BuildContext context, {
//   required Future<void> Function() onRevokeMarketing,
//   required Future<void> Function() onDeletePersonal,
// }) {
//   showDialog<void>(
//     context: context,
//     builder: (context) {
//       bool deletePersonal = false;
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: const Text('Privacidade & Consentimentos'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Gerencie suas concessões e dados pessoais.'),
//                 const SizedBox(height: 12),
//                 CheckboxListTile(
//                   value: deletePersonal,
//                   onChanged: (v) => setState(() => deletePersonal = v ?? false),
//                   title: const Text('Apagar nome e e-mail locais (opcional)'),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancelar'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.of(context).pop();
//                   // Sempre revoga marketing
//                   await onRevokeMarketing();
//                   if (deletePersonal) await onDeletePersonal();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Alterações aplicadas.')),
//                   );
//                 },
//                 child: const Text('Confirmar'),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }
