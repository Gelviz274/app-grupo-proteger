import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';

class DetallesAfiliacionScreen extends StatefulWidget {
  final Map<String, dynamic> afiliacion;

  const DetallesAfiliacionScreen({Key? key, required this.afiliacion})
      : super(key: key);

  @override
  State<DetallesAfiliacionScreen> createState() =>
      _DetallesAfiliacionScreenState();
}

class _DetallesAfiliacionScreenState extends State<DetallesAfiliacionScreen> {
  final _comentarioController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _loading = false;
  Map<String, dynamic>? _usuario;
  List<Map<String, dynamic>> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarHistorial();
  }

  Future<void> _cargarUsuario() async {
    try {
      final userId = widget.afiliacion['user_id'];
      debugPrint('🧩 Iniciando búsqueda de usuario...');

      final response = await supabase
          .from('profiles')
          .select('nombres, apellidos, numero_documento, email, telefono')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() => _usuario = response);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al cargar usuario',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _cargarHistorial() async {
    try {
      final idAfiliacion = widget.afiliacion['id'];
      final response = await supabase
          .from('historial_afiliacion')
          .select(
          'estado_anterior, estado_nuevo, comentario, fecha_cambio, cambiado_por')
          .eq('afiliacion_id', idAfiliacion)
          .order('fecha_cambio', ascending: false);

      setState(() {
        _historial = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al cargar historial',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    if (_comentarioController.text.trim().isEmpty &&
        nuevoEstado == 'rechazada') {
      Fluttertoast.showToast(
        msg: 'Por favor ingresa el motivo del rechazo.',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      final idAfiliacion = widget.afiliacion['id'];

      await supabase.from('Afiliaciones').update({
        'estado': nuevoEstado,
      }).eq('id', idAfiliacion);

      await supabase.from('historial_afiliacion').insert({
        'afiliacion_id': idAfiliacion,
        'estado_anterior': widget.afiliacion['estado'],
        'estado_nuevo': nuevoEstado,
        'cambiado_por': user?.id,
        'fecha_cambio': DateTime.now().toIso8601String(),
        'comentario': _comentarioController.text.trim(),
      });

      Fluttertoast.showToast(
        msg: 'Estado actualizado correctamente',
        backgroundColor: Colors.green,
      );

      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al actualizar estado',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final afiliacion = widget.afiliacion;
    final usuario = _usuario;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Detalles de Afiliación',
            style: TextStyle(fontWeight: FontWeight.bold,
            color: Colors.white)),
        centerTitle: true,
        elevation: 4,
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserCard(usuario, afiliacion),
            const SizedBox(height: 20),
            _buildComentarioInput(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 30),
            _buildHistorialSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> usuario, Map<String, dynamic> afiliacion) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.9), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: const Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            '${usuario['nombres']} ${usuario['apellidos']}',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(usuario['email'] ?? 'Sin correo',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          _infoRow('Documento', 'Documento adjunto'), // solo texto informativo
          _infoRow('Teléfono', usuario['telefono']),
          _infoRow('Estado actual', afiliacion['estado'].toUpperCase()),
          const SizedBox(height: 10),
          if (afiliacion['copia_cedula'] != null && afiliacion['copia_cedula'].toString().isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Ver documento'),
              onPressed: () async {
                try {
                  final urlString = afiliacion['copia_cedula'];
                  final url = Uri.parse(urlString);

                  // Abrir en navegador externo
                  final launched = await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!launched) {
                    Fluttertoast.showToast(msg: 'No se pudo abrir el documento');
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Error al abrir el documento');
                }
              },
            ),
        ],
      ),
    );
  }



  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value ?? 'Sin datos',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildComentarioInput() {
    return TextField(
      controller: _comentarioController,
      decoration: InputDecoration(
        labelText: 'Comentario o motivo del cambio',
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: 3,
    );
  }

  Widget _buildActionButtons() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _actualizarEstado('Aprobado'),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text('Aprobar',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _actualizarEstado('En revisión'),
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            label: const Text('En revisión',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _actualizarEstado('Rechazado'),
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            label: const Text('Rechazar',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Historial de cambios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _historial.isEmpty
            ? Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.history, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('No hay registros en el historial.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        )
            : Column(
          children: _historial.asMap().entries.map((entry) {
            final index = entry.key;
            final h = entry.value;
            final fecha = DateTime.parse(h['fecha_cambio']).toLocal();

            final estado = (h['estado_nuevo']?.toString().toLowerCase() ?? '');
            final esAprobado = estado.contains('aprob');
            final esRechazado = estado.contains('rechaz');
            final esRevision = estado.contains('revisión');

            final colorEstado = esAprobado
                ? AppColors.success
                : esRechazado
                ? AppColors.danger
                : esRevision
                ? Colors.amber
                : AppColors.primary;

            final icono = esAprobado
                ? Icons.check_circle
                : esRechazado
                ? Icons.cancel
                : esRevision
                ? Icons.pending_actions
                : Icons.info;

            return Stack(
              children: [
                // Línea vertical coloreada según el estado
                if (index < _historial.length - 1)
                  Positioned(
                    left: 20,
                    top: 40,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: colorEstado.withOpacity(0.5),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono circular del evento
                      Container(
                        decoration: BoxDecoration(
                          color: colorEstado.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: colorEstado, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(icono, color: colorEstado, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Contenido de la tarjeta
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado: ${h['estado_anterior']} → ${h['estado_nuevo']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorEstado,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                h['comentario']?.isNotEmpty == true
                                    ? h['comentario']
                                    : 'Sin comentario',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '📅 ${fecha.day}/${fecha.month}/${fecha.year}  ⏰ ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }


}
