import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_client.dart';
import '../../styles/app_colors.dart';
import 'package:afiliateya/components/AdminLayout.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  int usuariosTotales = 0;
  int afiliacionesTotales = 0;
  int afiliacionesPendientes = 0;
  int afiliacionesVerificadas = 0;
  Map<int, int> afiliacionesPorMes = {};
  List<Map<String, dynamic>> recientes = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    debugPrint('🟢 initState -> _loadAll()');
    _loadAll();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    debugPrint('🔄 _loadAll started');
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _fetchCounts(),
        _fetchMonthlyAffiliations(),
        _fetchRecentHistory(),
      ]);
      _animationController.forward();
      debugPrint('✅ _loadAll finished successfully');
    } catch (e, st) {
      _error = e.toString();
      debugPrint('❌ Error cargando dashboard: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
      debugPrint('🟢 setState done -> loading=$_loading, error=$_error');
    }
  }

  Future<void> _fetchCounts() async {
    try {
      debugPrint('📊 _fetchCounts START');

      final afiliacionesResp = await supabase.from('Afiliaciones').select();
      final usuariosResp = await supabase.from('profiles').select();

      debugPrint('🔹 Afiliaciones type: ${afiliacionesResp.runtimeType}');
      debugPrint('🔹 Afiliaciones count: ${afiliacionesResp.length}');
      debugPrint('🔹 Profiles count: ${usuariosResp.length}');

      final totalAfiliaciones = afiliacionesResp.length;
      final totalUsuarios = usuariosResp.length;
      final verificadas = afiliacionesResp.where((a) => a['estado'] == 'Verificada').length;
      final pendientes = afiliacionesResp.where((a) => a['estado'] == 'Pendiente').length;

      debugPrint('✅ Counts computed -> Afiliaciones: $totalAfiliaciones, Usuarios: $totalUsuarios, '
          'Verificadas: $verificadas, Pendientes: $pendientes');

      setState(() {
        afiliacionesTotales = totalAfiliaciones;
        usuariosTotales = totalUsuarios;
        afiliacionesVerificadas = verificadas;
        afiliacionesPendientes = pendientes;
      });
    } catch (e) {
      debugPrint('❌ Error en _fetchCounts(): $e');
    }
  }

  Future<void> _fetchMonthlyAffiliations() async {
    try {
      debugPrint('📅 Iniciando _fetchMonthlyAffiliations...');

      final response = await supabase
          .from('Afiliaciones')
          .select('created_at');

      debugPrint('🔹 Tipo de respuesta: ${response.runtimeType}');
      debugPrint('🔹 Registros obtenidos: ${response.length}');

      if (response.isEmpty) {
        debugPrint('⚠️ No hay registros de afiliaciones para graficar.');
        setState(() => afiliacionesPorMes = {});
        return;
      }

      final now = DateTime.now();
      final Map<int, int> monthlyCount = {};

      for (var item in response) {
        final fecha = DateTime.tryParse(item['created_at'] ?? '');
        if (fecha != null) {
          final diff = now.difference(fecha).inDays ~/ 30;
          if (diff <= 5) {
            final mes = fecha.month;
            monthlyCount[mes] = (monthlyCount[mes] ?? 0) + 1;
          }
        }
      }

      debugPrint('📈 Conteo mensual calculado: $monthlyCount');

      setState(() {
        afiliacionesPorMes = monthlyCount;
      });

    } catch (e) {
      debugPrint('❌ Error en _fetchMonthlyAffiliations(): $e');
    }
  }

  Future<void> _fetchRecentHistory() async {
    debugPrint('🕓 _fetchRecentHistory START');
    try {
      final res = await _supabase
          .from('historial_afiliacion')
          .select('id, fecha_cambio, estado_anterior, estado_nuevo, comentario, cambiado_por(id, nombres, apellidos)')
          .order('fecha_cambio', ascending: false)
          .limit(6);
      debugPrint('  historial_afiliacion response type: ${res.runtimeType}');
      final list = (res is List) ? res : <dynamic>[];
      debugPrint('  historial rows fetched: ${list.length}');

      recientes = list.map<Map<String, dynamic>>((r) {
        final cambiadoPor = r['cambiado_por'] as Map<String, dynamic>?;
        final actor = cambiadoPor != null ? '${cambiadoPor['nombres'] ?? ''} ${cambiadoPor['apellidos'] ?? ''}'.trim() : 'Sistema';
        return {
          'id': r['id'],
          'fecha_cambio': r['fecha_cambio'],
          'estado_anterior': r['estado_anterior'],
          'estado_nuevo': r['estado_nuevo'],
          'comentario': r['comentario'],
          'actor': actor.isEmpty ? 'Sistema' : actor,
        };
      }).toList();

      debugPrint('  recientes processed: ${recientes.length}');
    } catch (e) {
      debugPrint('❌ Error in _fetchRecentHistory: $e');
      rethrow;
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    final groups = <BarChartGroupData>[];
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));

    debugPrint('  Building bar groups for months: ${months.map((d) => d.month).toList()}');
    for (int i = 0; i < months.length; i++) {
      final m = months[i].month;
      final value = afiliacionesPorMes[m] ?? 0;
      debugPrint('    month=${m} -> value=$value');
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    debugPrint('  Bar groups created: ${groups.length}');
    return groups;
  }

  List<String> _last6MonthLabels() {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    const names = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final labels = months.map((d) => names[d.month]).toList();
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🧩 build() -> loading=$_loading, error=$_error, usuariosTotales=$usuariosTotales, afiliacionesTotales=$afiliacionesTotales');
    return AdminLayout(
      title: "Panel Principal",
      child: _loading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando dashboard...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Error al cargar',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mejorado
              _buildHeader(),
              const SizedBox(height: 32),

              // Stats cards con nuevo diseño
              _buildStatsGrid(),
              const SizedBox(height: 32),

              // Gráfica mejorada
              _buildChartSection(),
              const SizedBox(height: 32),

              // Historial renovado
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dashboard_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Panel Principal",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Administra y monitorea la plataforma desde un solo lugar.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final columns = isWide ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              icon: Icons.people_rounded,
              label: 'Total Usuarios',
              value: usuariosTotales.toString(),
              color: const Color(0xFF5B7FFF),
              width: width,
              trend: '+12%',
              trendUp: true,
            ),
            _buildStatCard(
              icon: Icons.assignment_rounded,
              label: 'Afiliaciones',
              value: afiliacionesTotales.toString(),
              color: const Color(0xFF00C9A7),
              width: width,
              trend: '+8%',
              trendUp: true,
            ),
            _buildStatCard(
              icon: Icons.verified_rounded,
              label: 'Verificadas',
              value: afiliacionesVerificadas.toString(),
              color: const Color(0xFF845EC2),
              width: width,
              trend: '+15%',
              trendUp: true,
            ),
            _buildStatCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pendientes',
              value: afiliacionesPendientes.toString(),
              color: const Color(0xFFFF6F91),
              width: width,
              trend: '-5%',
              trendUp: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double width,
    String? trend,
    bool trendUp = true,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (trendUp ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trendUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
            label,
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

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tendencia de Afiliaciones',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Últimos 6 meses',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: math.max(4, (afiliacionesPorMes.values.isEmpty ? 0 : afiliacionesPorMes.values.reduce((a, b) => math.max(a, b))).toDouble() + 2),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.primary,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} afiliaciones',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final labels = _last6MonthLabels();
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad Reciente',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Últimas ${recientes.length} acciones',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
              ],
            ),
          ),
          if (recientes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: AppColors.textLight.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No hay actividad reciente',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: recientes.length,
              separatorBuilder: (_, __) => Divider(
                color: AppColors.border,
                height: 1,
                indent: 24,
                endIndent: 24,
              ),
              itemBuilder: (context, i) {
                final r = recientes[i];
                final fecha = r['fecha_cambio'] != null ? DateTime.tryParse(r['fecha_cambio'].toString()) : null;
                final fechaStr = fecha != null ? _formatDateTime(fecha) : '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(r['estado_nuevo']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(r['estado_nuevo']),
                      color: _getStatusColor(r['estado_nuevo']),
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          r['actor'] ?? 'Sistema',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(r['estado_nuevo']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r['estado_nuevo'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(r['estado_nuevo']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        r['comentario'] ?? 'Sin comentarios',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            fechaStr,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getStatusColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'verificada':
      case 'aprobada':
      case 'aprobado':
        return const Color(0xFF10B981); // Verde
      case 'pendiente':
        return const Color(0xFF6366F1); // Índigo
      case 'rechazada':
      case 'rechazado':
        return const Color(0xFFEF4444); // Rojo
      case 'en revisión':
      case 'en revision':
        return const Color(0xFFF59E0B); // Naranja/Amarillo
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'verificada':
      case 'aprobada':
      case 'aprobado':
        return Icons.check_circle_rounded;
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'rechazada':
      case 'rechazado':
        return Icons.cancel_rounded;
      case 'en revisión':
      case 'en revision':
        return Icons.pending_actions_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}