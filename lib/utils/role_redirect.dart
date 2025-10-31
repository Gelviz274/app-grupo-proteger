import 'package:flutter/material.dart';
import '../screens/user/home_screen.dart';
import '../screens/supervisor/supervisor_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';

/// 🔹 Navega a la pantalla correspondiente según el rol del usuario.
///
/// [context] -> Contexto de la aplicación para la navegación.
/// [role] -> Rol del usuario (ej: "supervisor", "administrador", "usuario").
///
/// - 'supervisor' -> redirige a [HomeSupervisorScreen].
/// - 'administrador' -> redirige a [AdminDashboard].
/// - cualquier otro valor o valor nulo -> redirige a [HomeScreen] (usuario normal).
///
/// Usa [Navigator.pushReplacement] para reemplazar la pantalla actual
/// (evita que el usuario pueda regresar a la pantalla de login).
void navigateByRole(BuildContext context, String? role) {
  // 🔹 Normaliza el rol (minúsculas y manejo de null)
  final normalizedRole = role?.toLowerCase() ?? '';
  debugPrint('Navegando según rol: $normalizedRole');

  Widget destination;

  // 🔹 Selección de pantalla según el rol
  switch (normalizedRole) {
    case 'supervisor':
      destination = const HomeSupervisorScreen();
      break;
    case 'administrador':
      destination = const AdminDashboard();
      break;
    default:
      destination = const HomeScreen(); // Usuario normal por defecto
  }

  // 🔹 Ejecuta la navegación reemplazando la pantalla actual
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => destination),
  );
}
