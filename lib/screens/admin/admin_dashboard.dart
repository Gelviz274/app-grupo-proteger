import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟦 Encabezado
              Text(
                "Panel de Administración",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Gestiona usuarios, roles y configuraciones del sistema",
                style: GoogleFonts.nunitoSans(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),

              // 🧭 Opciones principales
              _buildSectionTitle("Gestión de usuarios"),
              _buildOptionCard(
                context,
                title: "Administrar usuarios",
                subtitle: "Ver, editar y eliminar cuentas registradas",
                icon: Icons.people_alt_rounded,
                color: Colors.indigoAccent,
                onTap: () {
                  // TODO: Navegar a manage_users_screen
                },
              ),
              _buildOptionCard(
                context,
                title: "Asignar roles",
                subtitle: "Cambiar roles entre usuario, supervisor y admin",
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.amber[700]!,
                onTap: () {
                  // TODO: Navegar a manage_roles_screen
                },
              ),

              const SizedBox(height: 25),

              _buildSectionTitle("Configuraciones"),
              _buildOptionCard(
                context,
                title: "Parámetros del sistema",
                subtitle: "Control de variables globales o ajustes técnicos",
                icon: Icons.settings_applications_rounded,
                color: Colors.teal,
                onTap: () {
                  // TODO: Navegar a system_settings_screen
                },
              ),
              _buildOptionCard(
                context,
                title: "Ver reportes del sistema",
                subtitle: "Resumen de actividad, logs y métricas clave",
                icon: Icons.bar_chart_rounded,
                color: Colors.deepPurpleAccent,
                onTap: () {
                  // TODO: Navegar a reports_screen
                },
              ),

              const SizedBox(height: 40),

              // 🔒 Cerrar sesión
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Supabase.auth.signOut() + redirigir al login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text(
                    "Cerrar sesión",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Componente reutilizable para secciones
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // 🔹 Tarjeta de opción reutilizable
  Widget _buildOptionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
