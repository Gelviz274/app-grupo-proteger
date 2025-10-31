import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_client.dart';
import '../auth/login_screen.dart';

/// Pantalla de configuración de la aplicación.
/// Permite al usuario ver opciones generales, soporte y cerrar sesión.
/// Funciones como cambiar tema, idioma o notificaciones están en desarrollo.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Color principal de la app para la pantalla de configuración
  final Color primaryColor = const Color(0xFF004AAD);

  /// Cierra sesión del usuario usando Supabase Auth
  /// Muestra un Toast de confirmación y redirige a la pantalla de login
  Future<void> _logout() async {
    await supabase.auth.signOut();
    Fluttertoast.showToast(
      msg: "Sesión cerrada correctamente",
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  /// Muestra un mensaje de Toast indicando que la función está en desarrollo
  void _showComingSoon(String feature) {
    Fluttertoast.showToast(
      msg: "$feature: función en desarrollo 🚧",
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Encabezado de la sección
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.settings, color: primaryColor, size: 30),
                ),
                const SizedBox(width: 12),
                Text(
                  "Preferencias y opciones",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Sección General
            _buildSectionTitle("General"),
            _buildOptionTile(
              icon: Icons.dark_mode_rounded,
              label: "Cambiar tema",
              onTap: () => _showComingSoon("Modo oscuro"),
            ),
            _buildOptionTile(
              icon: Icons.notifications_active_rounded,
              label: "Notificaciones",
              onTap: () => _showComingSoon("Notificaciones"),
            ),
            _buildOptionTile(
              icon: Icons.language_rounded,
              label: "Idioma",
              onTap: () => _showComingSoon("Selector de idioma"),
            ),

            const SizedBox(height: 30),
            // Sección Soporte
            _buildSectionTitle("Soporte"),
            _buildOptionTile(
              icon: Icons.description_rounded,
              label: "Términos y condiciones",
              onTap: () => _showComingSoon("Términos y condiciones"),
            ),
            _buildOptionTile(
              icon: Icons.lock_outline_rounded,
              label: "Política de privacidad",
              onTap: () => _showComingSoon("Política de privacidad"),
            ),
            _buildOptionTile(
              icon: Icons.support_agent_rounded,
              label: "Centro de ayuda",
              onTap: () => _showComingSoon("Centro de ayuda"),
            ),

            const SizedBox(height: 30),
            // Sección Cuenta
            _buildSectionTitle("Cuenta"),
            _buildOptionTile(
              icon: Icons.logout_rounded,
              label: "Cerrar sesión",
              color: Colors.redAccent,
              onTap: _logout,
            ),

            const SizedBox(height: 40),
            // Información de la versión de la app
            Center(
              child: Text(
                "Versión 1.0.0",
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título de cada sección de configuración
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  /// Construye una opción dentro de una sección
  /// [icon] → Icono representativo
  /// [label] → Texto de la opción
  /// [onTap] → Acción a ejecutar al presionar
  /// [color] → Color opcional para el icono
  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? primaryColor, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
