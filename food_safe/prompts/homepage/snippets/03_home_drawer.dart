// Snippet: 03_home_drawer.dart
// Cole no build do Scaffold da HomePage (ou adapte para seu código)

// Drawer(
//   child: SafeArea(
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         UserAccountsDrawerHeader(
//           accountName: Text(userName ?? 'Usuário não registrado'),
//           accountEmail: Text(userEmail ?? ''),
//           currentAccountPicture: CircleAvatar(
//             child: Text(userName != null && userName!.isNotEmpty ? userName!.split(' ').map((e)=>e.isNotEmpty?e[0]:'').take(2).join() : '?'),
//           ),
//         ),
//         ListTile(
//           leading: const Icon(Icons.person),
//           title: const Text('Editar perfil'),
//           onTap: () async {
//             Navigator.of(context).pop();
//             final result = await Navigator.of(context).pushNamed('/profile');
//             if (result == true) {
//               // recarregue estado do usuário
//               _loadUser();
//             }
//           },
//         ),
//         ListTile(
//           leading: const Icon(Icons.privacy_tip),
//           title: const Text('Privacidade & consentimentos'),
//           onTap: () {
//             Navigator.of(context).pop();
//             _openPrivacyDialog();
//           },
//         ),
//       ],
//     ),
//   ),
// )
