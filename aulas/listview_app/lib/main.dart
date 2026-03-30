import 'package:flutter/material.dart';

void main() {
  runApp(const ListViewApp());
}

class ListViewApp extends StatelessWidget {
  const ListViewApp({super.key});

  static const List<String> items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
    'Item 6',
    'Item 7',
    'Item 8',
    'Item 9',
    'Item 10',
    'Item 11',
    'Item 12',
    'Item 13',
    'Item 14',
    'Item 15',
    'Item 16',
    'Item 17',
    'Item 18',
    'Item 19',
    'Item 20',
    'Item 21',
    'Item 22',
    'Item 23',
    'Item 24',
    'Item 25',
    'Item 26',
    'Item 27',
    'Item 28',
    'Item 29',
    'Item 30',
    'Item 31',
    'Item 32',
    'Item 33',
    'Item 34',
    'Item 35',
    'Item 36',
    'Item 37',
    'Item 38',
    'Item 39',
    'Item 40',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ListView Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('ListView Example')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person, color: Colors.blue, size: 48),
                title: Text(
                  items[index],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Subtitle'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on ${items[index]}')),
                  );
                },
              );
              // return Card(
              //   margin: const EdgeInsets.symmetric(vertical: 8.0),
              //   shadowColor: Colors.amber,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   color: Colors.blueAccent,
              //   elevation: 4,
              //   child: Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Text(
              //       items[index],
              //       style: const TextStyle(color: Colors.white),
              //     ),
              //   ),
              // );
            },
          ),
          // child: ListView(
          //   children: [
          //     Text('Item 1'),
          //     Text('Item 2'),
          //     Text('Item 3'),
          //     Text('Item 4'),
          //     Text('Item 5'),
          //     Text('Item 6'),
          //     Text('Item 7'),
          //     Text('Item 8'),
          //     Text('Item 9'),
          //     Text('Item 10'),
          //     Text('Item 11'),
          //     Text('Item 12'),
          //     Text('Item 13'),
          //     Text('Item 14'),
          //     Text('Item 15'),
          //     Text('Item 16'),
          //     Text('Item 17'),
          //     Text('Item 18'),
          //     Text('Item 19'),
          //     Text('Item 20'),
          //     Text('Item 21'),
          //     Text('Item 22'),
          //     Text('Item 23'),
          //     Text('Item 24'),
          //     Text('Item 25'),
          //     Text('Item 26'),
          //     Text('Item 27'),
          //     Text('Item 28'),
          //     Text('Item 29'),
          //     Text('Item 30'),
          //     Text('Item 31'),
          //     Text('Item 32'),
          //     Text('Item 33'),
          //     Text('Item 34'),
          //     Text('Item 35'),
          //     Text('Item 36'),
          //     Text('Item 37'),
          //     Text('Item 38'),
          //     Text('Item 39'),
          //     Text('Item 40'),
          //   ],
          // ),
        ),
      ),
    );
  }
}
