import 'package:flutter/material.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/edit_user_screen.dart';
import '../screens/user/create_solicitud.dart';
import '../screens/user/settings_screen.dart';
import '../styles/app_colors.dart';

/// Layout principal de la aplicación para usuarios
/// Incluye navegación inferior y AppBar dinámico según la pantalla seleccionada
class AppLayout extends StatefulWidget {
  final String? userId; // ID opcional del usuario logueado

  const AppLayout({super.key, this.userId});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _currentIndex = 0; // Índice de la pantalla actual

  late final List<Widget> _screens; // Lista de pantallas

  @override
  void initState() {
    super.initState();

    // Inicializamos las pantallas del usuario
    _screens = [
      const HomeScreen(), // Pantalla de inicio
      EditProfileScreen(), // Pantalla de edición de perfil
      const CreateAffiliationScreen(), // Pantalla para crear nueva afiliación
      const SettingsScreen(), // Pantalla de configuración
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,

      // ================== APPBAR ==================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        centerTitle: true,
        title: Text(
          _getTitleForIndex(_currentIndex), // Título dinámico según pantalla
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.surface,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ================== CUERPO ==================
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex, // Mantiene el estado de cada pantalla
          children: _screens,
        ),
      ),

      // ================== NAVEGACIÓN INFERIOR ==================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            currentIndex: _currentIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            showUnselectedLabels: true,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12.5,
            ),
            onTap: (index) {
              // Actualiza la pantalla seleccionada
              setState(() => _currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Nueva Afiliación',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Devuelve el título del AppBar según la pantalla actual
  String _getTitleForIndex(int index) {
    switch (index) {
      case 1:
        return "Mi perfil";
      case 2:
        return "Nueva Afiliación";
      case 3:
        return "Configuración";
      default:
        return "Inicio";
    }
  }
}
