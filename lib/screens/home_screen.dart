import 'package:flutter/material.dart';
import 'nueva_carga_screen.dart';
import 'historial_screen.dart';
import 'comerciantes_screen.dart';
import 'reportes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                '🍈 PAPAYAS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Registro de carga y pesaje',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 48),
              _MenuButton(
                icon: Icons.local_shipping_outlined,
                label: 'Nueva carga',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaCargaScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.history,
                label: 'Historial',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistorialScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.people_outline,
                label: 'Comerciantes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComerciantesScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.bar_chart_outlined,
                label: 'Reportes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportesScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
