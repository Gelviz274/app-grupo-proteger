import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';

class HomeSupervisorScreen extends StatelessWidget {
  const HomeSupervisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            const Text(
              "Bienvenido, Supervisor 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Panel general de Grupo Proteger",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 25),

            // Tarjetas de estadísticas
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  title: "Afiliaciones\npendientes",
                  icon: Icons.pending_actions_rounded,
                  value: "12",
                  color: AppColors.primary,
                ),
                _buildStatCard(
                  title: "Afiliaciones\naprobadas",
                  icon: Icons.check_circle_rounded,
                  value: "48",
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: "Reportes",
                  icon: Icons.bar_chart_rounded,
                  value: "7",
                  color: Colors.orange,
                ),
                _buildStatCard(
                  title: "Usuarios\nregistrados",
                  icon: Icons.people_alt_rounded,
                  value: "152",
                  color: Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Sección de acciones rápidas
            const Text(
              "Acciones rápidas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 15),

            Column(
              children: [
                _buildActionTile(
                  icon: Icons.assignment,
                  title: "Revisar nuevas afiliaciones",
                  subtitle: "Consulta solicitudes pendientes",
                  onTap: () {
                    // Navegar a Afiliaciones
                  },
                ),
                _buildActionTile(
                  icon: Icons.insert_chart,
                  title: "Ver reportes del sistema",
                  subtitle: "Analiza el rendimiento general",
                  onTap: () {
                    // Navegar a Reportes
                  },
                ),
                _buildActionTile(
                  icon: Icons.people,
                  title: "Gestionar usuarios",
                  subtitle: "Supervisa la actividad del personal",
                  onTap: () {
                    // Navegar a Usuarios
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de estadísticas
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 26),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Tile de acción rápida
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textLight),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
