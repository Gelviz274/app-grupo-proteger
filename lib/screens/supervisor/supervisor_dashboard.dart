import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/supabase_client.dart';
import '../../styles/app_colors.dart';
import 'detalles_afiliacion_screen.dart';
import '../../components//supervisor_layout.dart'; // 👈 Asegúrate de importar tu layout

class HomeSupervisorScreen extends StatefulWidget {
  const HomeSupervisorScreen({super.key});

  @override
  State<HomeSupervisorScreen> createState() => _HomeSupervisorScreenState();
}

class _HomeSupervisorScreenState extends State<HomeSupervisorScreen> {
  List<dynamic> _afiliaciones = [];
  String _selectedEstado = "Todos";
  bool _loading = true;

  final List<String> estados = [
    "Todos",
    "Pendiente",
    "En revisión",
    "Aprobado",
    "Rechazado"
  ];

  @override
  void initState() {
    super.initState();
    _loadAfiliaciones();
  }

  Future<void> _loadAfiliaciones() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('Afiliaciones')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() => _afiliaciones = data);
      }
    } catch (e) {
      debugPrint("❌ Error al cargar afiliaciones: $e");
      Fluttertoast.showToast(
        msg: "Error al cargar afiliaciones.",
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return Colors.grey;
      case 'en revisión':
        return AppColors.warning;
      case 'aprobado' || 'aprobada':
        return AppColors.success;
      case 'rechazado':
        return AppColors.danger;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedEstado == "Todos"
        ? _afiliaciones
        : _afiliaciones
        .where((a) =>
    (a['estado'] ?? '').toString().toLowerCase() ==
        _selectedEstado.toLowerCase())
        .toList();

    return SupervisorLayout(
      // 👇 contenido interno sin AppBar
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAfiliaciones,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👋 Bienvenida
                Text(
                  "Bienvenido, Supervisor 👋",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Panel general de Grupo Proteger",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 25),

                // 📊 Estadísticas
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      title: "Pendientes",
                      icon: Icons.pending_actions_rounded,
                      value: _afiliaciones
                          .where((a) =>
                      (a['estado'] ?? '').toString().toLowerCase() ==
                          'pendiente')
                          .length
                          .toString(),
                      color: AppColors.primary,
                    ),
                    _buildStatCard(
                      title: "Aprobadas",
                      icon: Icons.check_circle_rounded,
                      value: _afiliaciones
                          .where((a) =>
                      (a['estado'] ?? '').toString().toLowerCase() ==
                          'aprobado')
                          .length
                          .toString(),
                      color: AppColors.success,
                    ),
                    _buildStatCard(
                      title: "Rechazadas",
                      icon: Icons.cancel_rounded,
                      value: _afiliaciones
                          .where((a) =>
                      (a['estado'] ?? '').toString().toLowerCase() ==
                          'rechazado')
                          .length
                          .toString(),
                      color: AppColors.danger,
                    ),
                    _buildStatCard(
                      title: "Total registros",
                      icon: Icons.people_alt_rounded,
                      value: _afiliaciones.length.toString(),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 🔽 Filtro de estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Afiliaciones (${filteredList.length})",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEstado,
                          items: estados
                              .map((estado) => DropdownMenuItem(
                            value: estado,
                            child: Text(
                              estado,
                              style:
                              GoogleFonts.poppins(fontSize: 14),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedEstado = value);
                            }
                          },
                          icon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 📋 Lista de afiliaciones
                if (_loading)
                  const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 3),
                      ))
                else if (filteredList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            "No hay afiliaciones registradas",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final estado = item['estado'] ?? 'Desconocido';
                      final entidad = item['entidad'] ?? 'Sin entidad';
                      final tipo = item['tipo_afiliacion'] ?? 'Desconocido';
                      final fecha =
                          DateTime.tryParse(item['created_at'] ?? '')
                              ?.toLocal()
                              .toString()
                              .split(' ')
                              .first;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetallesAfiliacionScreen(afiliacion: item),
                            ),
                          );
                          if (result == true) _loadAfiliaciones();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                                color: AppColors.border, width: 0.8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 45,
                                width: 45,
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(estado)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.assignment_rounded,
                                  color: _getEstadoColor(estado),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entidad,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Tipo: $tipo",
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "Fecha: ${fecha ?? 'N/A'}",
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 13,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(estado)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estado.toString().toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: _getEstadoColor(estado),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
