import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';

/// Pantalla de perfil del supervisor
class PerfilSupervisorScreen extends StatefulWidget {
  const PerfilSupervisorScreen({super.key});

  @override
  State<PerfilSupervisorScreen> createState() => _PerfilSupervisorScreenState();
}

class _PerfilSupervisorScreenState extends State<PerfilSupervisorScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  Map<String, dynamic>? _perfil;

  final TextEditingController _telefonoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  /// 🔹 Carga la información del perfil desde Supabase
  Future<void> _loadPerfil() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      setState(() {
        _perfil = data;
        _telefonoController.text = data['telefono'] ?? '';
        _loading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al cargar perfil: $e',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  /// 🔹 Actualiza el teléfono del supervisor
  Future<void> _actualizarTelefono() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').update({
        'telefono': _telefonoController.text.trim(),
      }).eq('id', user.id);

      Fluttertoast.showToast(
        msg: 'Teléfono actualizado correctamente',
        backgroundColor: AppColors.success,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error al actualizar: $e',
        backgroundColor: AppColors.danger,
      );
    }
  }

  /// 🔹 Cierra sesión del supervisor
  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final perfil = _perfil!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Perfil del Supervisor',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Información Personal',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 15),

            // 🔹 Tarjetas de información
            _infoCard('Nombres', perfil['nombres']),
            _infoCard('Apellidos', perfil['apellidos']),
            _infoCard('Número de documento', perfil['numero_documento']),
            _infoCard('Correo electrónico', perfil['email']),
            _infoCard('Rol', perfil['rol']),
            const SizedBox(height: 20),

            // 🔹 Campo editable: teléfono
            Text(
              'Teléfono',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ingrese su teléfono',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _actualizarTelefono,
              icon: const Icon(Icons.save),
              label: const Text('Actualizar teléfono'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Tarjeta de información para mostrar campos del perfil
  Widget _infoCard(String label, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value ?? 'No disponible',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
