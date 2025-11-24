import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/supabase_client.dart';
import '../../styles/app_colors.dart';
import '../supervisor/detalles_afiliacion_screen.dart';

class AdminAfiliacionesScreen extends StatefulWidget {
  const AdminAfiliacionesScreen({super.key});

  @override
  State<AdminAfiliacionesScreen> createState() => _AdminAfiliacionesScreenState();
}

class _AdminAfiliacionesScreenState extends State<AdminAfiliacionesScreen> {
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

    return RefreshIndicator(
      onRefresh: _loadAfiliaciones,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 Estadísticas
            _buildStatsGrid(),
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
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEstado,
                      items: estados
                          .map((estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(
                                  estado,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedEstado = value);
                        }
                      },
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📋 Lista de afiliaciones
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
              )
            else if (filteredList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 64, color: AppColors.textLight.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "No hay afiliaciones registradas",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.textLight,
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  final estado = item['estado'] ?? 'Desconocido';
                  final entidad = item['entidad'] ?? 'Sin entidad';
                  final tipo = item['tipo_afiliacion'] ?? 'Desconocido';
                  final fecha = DateTime.tryParse(item['created_at'] ?? '')
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: _getEstadoColor(estado).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.assignment_rounded,
                              color: _getEstadoColor(estado),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entidad,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tipo: $tipo",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  "Fecha: ${fecha ?? 'N/A'}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(estado).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado.toString().toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _getEstadoColor(estado),
                                fontSize: 11,
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
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final columns = isWide ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              title: "Total",
              icon: Icons.assignment_rounded,
              value: _afiliaciones.length.toString(),
              color: AppColors.primary,
              width: width,
            ),
            _buildStatCard(
              title: "Pendientes",
              icon: Icons.pending_actions_rounded,
              value: _afiliaciones
                  .where((a) =>
                      (a['estado'] ?? '').toString().toLowerCase() == 'pendiente')
                  .length
                  .toString(),
              color: Colors.grey,
              width: width,
            ),
            _buildStatCard(
              title: "Aprobadas",
              icon: Icons.check_circle_rounded,
              value: _afiliaciones
                  .where((a) =>
                      (a['estado'] ?? '').toString().toLowerCase() == 'aprobado')
                  .length
                  .toString(),
              color: AppColors.success,
              width: width,
            ),
            _buildStatCard(
              title: "Rechazadas",
              icon: Icons.cancel_rounded,
              value: _afiliaciones
                  .where((a) =>
                      (a['estado'] ?? '').toString().toLowerCase() == 'rechazado')
                  .length
                  .toString(),
              color: AppColors.danger,
              width: width,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
