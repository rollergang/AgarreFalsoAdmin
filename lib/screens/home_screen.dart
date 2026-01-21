import 'package:agarre_admin/screens/exercises/exercises_screen.dart';
import 'package:agarre_admin/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agarre_admin/screens/students/students_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Profesor', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Salir',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "¿Qué quieres gestionar hoy?",
              style: TextStyle(fontSize: 22, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            
            // Botón ALUMNOS
            Expanded(
              child: _buildBigCard(
                context,
                title: "ALUMNOS",
                subtitle: "Asignar rutinas y ver progresos",
                icon: Icons.people_alt_rounded,
                color: Colors.blue.shade700,
                onTap: () {
                  // ✅ NAVEGACIÓN REAL AHORA
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentsScreen()),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),

            // Botón EJERCICIOS
            Expanded(
              child: _buildBigCard(
                context,
                title: "EJERCICIOS",
                subtitle: "Crear y editar el catálogo",
                icon: Icons.fitness_center_rounded,
                color: Colors.orange.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExercisesScreen()),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBigCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}