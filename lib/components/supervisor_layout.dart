import 'package:flutter/material.dart';
import 'package:afiliateya/styles/app_colors.dart';
import 'package:afiliateya/screens/auth/login_screen.dart';
import 'package:afiliateya/screens/supervisor/perfil_supervisor_screen.dart';
import 'package:afiliateya/screens/supervisor/query_users_screen.dart';

/// Layout principal para el panel del supervisor.
/// Contiene Drawer, AppBar y el área principal de contenido [body].
class SupervisorLayout extends StatelessWidget {
  final Widget body; // Contenido principal que se mostrará en la pantalla
  final String? title; // Título del AppBar

  const SupervisorLayout({
    Key? key,
    required this.body,
    this.title,
  }) : super(key: key);

  /// 🔹 Cierra sesión y redirige a la pantalla de login
  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// Drawer lateral del supervisor
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Supervisor',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Panel de control',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context), // Solo cierra el drawer
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PerfilSupervisorScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_rounded),
              title: const Text('Ver usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),

      /// AppBar del layout
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title ?? 'Panel del Supervisor',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// Área principal donde se muestra el contenido dinámico
      body: body,
    );
  }
}
