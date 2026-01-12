import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      body: const Center(
        child: Text('Order Management - Coming Soon\n(Accessible by Admin & Staff)'),
      ),
    );
  }
}
