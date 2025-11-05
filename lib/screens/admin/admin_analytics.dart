import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../../styles/app_colors.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  int _afiliacionesTotales = 0;
  Map<String, int> _afiliacionesPorEstado = {};
  Map<String, int> _afiliacionesPorMes = {};

  // Colores fijos para cada estado
  final Map<String, Color> _estadoColors = {
    'Activo': Colors.green.shade400,
    'Pendiente': Colors.orange.shade400,
    'Inactivo': Colors.red.shade400,
    'Aprobado': Colors.blue.shade400,
    'Rechazado': Colors.purple.shade400,
    'En revisión': Colors.amber.shade400,
    'Suspendido': Colors.grey.shade400,
    'Completado': Colors.teal.shade400,
  };

  // Colores de respaldo para estados no definidos
  final List<Color> _pieChartColorsBackup = [
    Colors.orange.shade400,
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.amber.shade400,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await supabase.from('Afiliaciones').select('id, estado, created_at');
      final afList = (response is List) ? response : [];

      final total = afList.length;
      final porEstado = <String, int>{};
      final porMes = <String, int>{};

      // Procesar datos por estado
      for (final afiliacion in afList) {
        final estado = (afiliacion['estado']?.toString() ?? 'Sin Estado');
        porEstado[estado] = (porEstado[estado] ?? 0) + 1;
      }

      // Inicializar últimos 6 meses
      final now = DateTime.now();
      final monthlyCount = <String, int>{};
      for (int i = 0; i < 6; i++) {
        final date = DateTime(now.year, now.month - 5 + i, 1);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyCount[key] = 0;
      }

      // Contar afiliaciones por mes
      for (final afiliacion in afList) {
        final createdStr = afiliacion['created_at']?.toString();
        if (createdStr != null && createdStr.isNotEmpty) {
          final created = DateTime.tryParse(createdStr);
          if (created != null) {
            final startDate = DateTime(now.year, now.month - 5, 1);
            if (created.isAfter(startDate.subtract(const Duration(days: 1))) &&
                created.isBefore(now.add(const Duration(days: 1)))) {
              final key = '${created.year}-${created.month.toString().padLeft(2, '0')}';
              monthlyCount[key] = (monthlyCount[key] ?? 0) + 1;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _afiliacionesTotales = total;
          _afiliacionesPorEstado = porEstado;
          _afiliacionesPorMes = monthlyCount;
        });
      }

    } catch (e) {
      debugPrint('Error en _loadData: $e');
      if (mounted) {
        setState(() {
          _error = 'Hubo un problema al conectar con la base de datos o procesar datos.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    final keys = _afiliacionesPorMes.keys.toList()..sort();
    if (keys.isEmpty) {
      return List.generate(6, (i) => BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
                toY: 0,
                width: 20,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6)
                ),
                color: Colors.grey.shade300
            )
          ]
      ));
    }

    return List.generate(keys.length, (i) {
      final key = keys[i];
      final value = _afiliacionesPorMes[key] ?? 0;
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            width: 20,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6)
            ),
            color: AppColors.primary,
            gradient: _createBarGradient(),
          ),
        ],
      );
    });
  }

  LinearGradient _createBarGradient() {
    return LinearGradient(
      colors: [
        AppColors.primary,
        AppColors.primary.withOpacity(0.7)
      ],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  List<String> _getMonthLabels() {
    final now = DateTime.now();
    const monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return List.generate(6, (i) {
      final date = DateTime(now.year, now.month - 5 + i, 1);
      return '${monthNames[date.month - 1]}\n\'${date.year.toString().substring(2)}';
    });
  }

  Color _getColorForEstado(String estado, int index) {
    // Buscar color predefinido para el estado
    final normalizedEstado = estado.toLowerCase();
    for (final entry in _estadoColors.entries) {
      if (normalizedEstado.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Si no encuentra un color predefinido, usar color de respaldo
    return _pieChartColorsBackup[index % _pieChartColorsBackup.length];
  }

  List<PieChartSectionData> _buildPieSections() {
    if (_afiliacionesPorEstado.isEmpty) {
      return [
        PieChartSectionData(
            value: 1,
            color: Colors.grey.shade300,
            title: 'Sin datos',
            radius: 60,
            titleStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white
            )
        )
      ];
    }

    final total = _afiliacionesTotales.toDouble();
    int index = 0;

    return _afiliacionesPorEstado.entries.map((entry) {
      final porcentaje = (entry.value / total * 100).toStringAsFixed(1);
      final color = _getColorForEstado(entry.key, index);
      index++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        title: '$porcentaje%',
        radius: 60,
        titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              const Shadow(
                  color: Colors.black54,
                  blurRadius: 2
              )
            ]
        ),
        badgeWidget: _buildBadge(entry.key, entry.value),
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  Widget _buildBadge(String estado, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1)
          )
        ],
      ),
      child: Text(
          '$count',
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87
          )
      ),
    );
  }

  Widget _buildPieLegend() {
    if (_afiliacionesPorEstado.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Text(
            'No hay estados para mostrar',
            style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic
            )
        ),
      );
    }

    int index = 0;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _afiliacionesPorEstado.entries.map((entry) {
          final color = _getColorForEstado(entry.key, index);
          index++;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco para los contenedores
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle
                    )
                ),
                const SizedBox(width: 6),
                Text(
                    '${entry.key} (${entry.value})',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight
                    )
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco sólido
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2)
                    )
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        title,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary
                        )
                    )
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingShimmer();
    if (_error != null) return _buildErrorState();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildTotalAfiliacionesCard(),
            const SizedBox(height: 32),
            _buildCard(
              title: 'Tendencia Mensual (Últimos 6 Meses)',
              child: SizedBox(
                  height: 280,
                  child: _buildBarChart()
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              title: 'Distribución por Estado',
              child: Column(
                  children: [
                    SizedBox(
                        height: 280,
                        child: PieChart(
                            PieChartData(
                              sections: _buildPieSections(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 70,
                              startDegreeOffset: -90,
                            )
                        )
                    ),
                    _buildPieLegend()
                  ]
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh_rounded),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
              Icons.analytics,
              color: AppColors.primary,
              size: 24
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Estadísticas de Afiliaciones',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary
                  )
              ),
              const SizedBox(height: 4),
              Text(
                  'Resumen general y tendencias clave de los últimos 6 meses',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textLight,
                      height: 1.4
                  )
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAfiliacionesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco sólido
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle
              ),
              child: Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primary,
                  size: 28
              )
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'TOTAL DE AFILIACIONES',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withOpacity(0.8),
                        letterSpacing: 0.5
                    )
                ),
                const SizedBox(height: 4),
                Text(
                    '$_afiliacionesTotales',
                    style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxYValue = _afiliacionesPorMes.values.isEmpty
        ? 5
        : _afiliacionesPorMes.values.reduce((a, b) => math.max(a, b));

    return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: math.max(5, maxYValue * 1.25).toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.primary.withOpacity(0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final labels = _getMonthLabels();
                final monthLabel = group.x.toInt() < labels.length
                    ? labels[group.x.toInt()]
                    : 'Mes ${group.x}';
                return BarTooltipItem(
                    '$monthLabel\n${rod.toY.toInt()} Afiliaciones',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    )
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    interval: math.max(1, (_afiliacionesTotales / 5).ceil()).toDouble(),
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500
                        )
                    )
                )
            ),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final labels = _getMonthLabels();
                      if (value.toInt() < 0 || value.toInt() >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              labels[value.toInt()],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500
                              )
                          )
                      );
                    }
                )
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)
            ),
          ),
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.textLight.withOpacity(0.1),
                  strokeWidth: 1
              ),
              checkToShowHorizontalLine: (value) => value % 5 == 0
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1
              )
          ),
          barGroups: _buildBarGroups(),
        )
    );
  }

  Widget _buildLoadingShimmer() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 200,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8)
                )
            ),
            const SizedBox(height: 8),
            Container(
                width: 300,
                height: 20,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6)
                )
            ),
            const SizedBox(height: 32),
            Expanded(
                child: ListView(
                    children: [
                      _buildShimmerCard(),
                      const SizedBox(height: 24),
                      _buildShimmerCard()
                    ]
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
        height: 300,
        decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4)
              )
            ]
        ),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2
            )
        )
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white, // Fondo blanco
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 40
                  )
              ),
              const SizedBox(height: 24),
              Text(
                  'Error al cargar datos',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade600
                  )
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5
                    )
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                    'Reintentar',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600
                    )
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                    elevation: 2
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}