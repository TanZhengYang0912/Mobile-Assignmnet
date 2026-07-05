import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionScreen({
    super.key,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'mySumber',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role to continue',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 280,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => onRoleSelected('admin'),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 280,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => onRoleSelected('consumer'),
                icon: const Icon(Icons.person),
                label: const Text('Consumer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
