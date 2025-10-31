import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/supabase_client.dart';
import '../../styles/app_colors.dart';
import '../auth/login_screen.dart';

/// Pantalla principal del usuario.
/// Muestra información del perfil y lista de afiliaciones registradas.
/// Permite refrescar la lista de afiliaciones con un swipe hacia abajo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// ID del usuario actual
  String? userId;

  /// Nombre completo del usuario
  String? userName;

  /// Correo electrónico del usuario
  String? userEmail;

  /// Estado de carga de la pantalla
  bool loading = true;

  /// Lista de afiliaciones del usuario
  List<Map<String, dynamic>> afiliaciones = [];

  @override
  void initState() {
    super.initState();
    _loadUser(); // Carga información del usuario al iniciar
  }

  /// Obtiene los datos del usuario actual desde Supabase.
  /// Si no hay usuario activo, redirige a la pantalla de login.
  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      Fluttertoast.showToast(
        msg: "No se encontró usuario activo. Inicia sesión nuevamente.",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    try {
      // Obtener información básica del usuario
      final response = await supabase
          .from('profiles')
          .select('nombres, apellidos, email')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        Fluttertoast.showToast(
          msg: "No se encontraron datos del usuario.",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
        if (mounted) setState(() => loading = false);
        return;
      }

      final nombres = response['nombres'] ?? '';
      final apellidos = response['apellidos'] ?? '';

      setState(() {
        userId = user.id;
        userEmail = response['email'] ?? user.email;
        userName = "$nombres $apellidos".trim();
      });

      // Cargar afiliaciones del usuario
      await _loadAfiliaciones(user.id);
    } catch (e) {
      debugPrint('⚠️ Error al cargar usuario: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  /// Carga las afiliaciones del usuario desde la tabla 'Afiliaciones'
  /// Incluye historial de comentarios de supervisores
  Future<void> _loadAfiliaciones(String uid) async {
    setState(() => loading = true);

    try {
      final data = await supabase
          .from('Afiliaciones')
          .select(
          '''
      entidad,
      tipo_afiliacion,
      estado,
      created_at,
      observaciones,
      historial_afiliacion(
        comentario,
        created_at
      )
      '''
      )
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = (data is List)
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          afiliaciones = list;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar afiliaciones: $e');
      Fluttertoast.showToast(
        msg: "Error al cargar afiliaciones.",
        backgroundColor: Colors.redAccent,
      );
      if (mounted) setState(() => loading = false);
    }
  }

  /// Devuelve un color según el estado de la afiliación
  Color _getEstadoColor(String estado) {
    final lower = estado.toLowerCase();
    if (lower.contains('pendiente')) return Colors.grey.shade400;
    if (lower.contains('revisión') || lower.contains('revision')) return Colors.orangeAccent;
    if (lower.contains('apro')) return Colors.green;
    if (lower.contains('rechaz')) return Colors.redAccent;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carga mientras se obtienen datos
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = userId ?? supabase.auth.currentUser?.id;
          if (uid != null) await _loadAfiliaciones(uid);
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(), // Encabezado de bienvenida
              const SizedBox(height: 25),
              _buildUserCard(), // Tarjeta con información del usuario
              const SizedBox(height: 30),
              Text(
                "Mis afiliaciones",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 15),
              afiliaciones.isEmpty ? _emptyState() : _buildAfiliacionesList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget mostrado cuando no hay afiliaciones registradas
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          "No tienes afiliaciones registradas aún.",
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Encabezado de bienvenida con ícono representativo
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              "Bienvenido a Grupo Proteger.\nGestiona tus afiliaciones fácilmente.",
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta que muestra información básica del usuario
  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            radius: 28,
            child: Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Hola 👋!', style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  userName ?? "Usuario",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail ?? '',
                  style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de afiliaciones del usuario
  Widget _buildAfiliacionesList() {
    return Column(
      children: afiliaciones.map((af) {
        final estado = (af['estado'] ?? 'Pendiente').toString();
        final observaciones = af['observaciones']?.toString() ?? '-';

        // Formatear fecha de creación
        DateTime? fecha;
        if (af['created_at'] != null) {
          try {
            fecha = DateTime.parse(af['created_at'].toString());
          } catch (_) {
            fecha = null;
          }
        }
        final fechaFormatted = fecha != null ? "${fecha.day}/${fecha.month}/${fecha.year}" : "-";

        // Historial de comentarios del supervisor
        final comentarioSupervisorList = (af['historial_afiliacion'] as List<dynamic>?) ?? [];

        // Ordenar comentarios por fecha descendente
        comentarioSupervisorList.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        final comentarioSupervisorText = comentarioSupervisorList.isNotEmpty
            ? comentarioSupervisorList[0]['comentario'] ?? '-'
            : '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de afiliación con estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    af['entidad'] ?? '-',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(estado).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado,
                      style: GoogleFonts.poppins(
                        color: _getEstadoColor(estado),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                af['tipo_afiliacion'] ?? '-',
                style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(fechaFormatted, style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Tu comentario: $observaciones",
                style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                "Comentario supervisor: $comentarioSupervisorText",
                style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black87),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
