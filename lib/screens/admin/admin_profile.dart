import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/app_colors.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, dynamic>? _adminProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controladores para el formulario de edición
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _adminProfile = response;
          _nombresController.text = response['nombres'] ?? '';
          _apellidosController.text = response['apellidos'] ?? '';
          _emailController.text = response['email'] ?? '';
          _telefonoController.text = response['telefono'] ?? '';
          _cargoController.text = response['cargo'] ?? 'Administrador';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final updateData = {
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'cargo': _cargoController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      setState(() {
        _isEditing = false;
        _adminProfile = {...?_adminProfile, ...updateData};
      });

      _showSnackBar('Perfil actualizado exitosamente');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _showSnackBar('Error al actualizar perfil', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getIniciales(String nombres, String apellidos) {
    String iniciales = '';
    if (nombres.isNotEmpty) iniciales += nombres[0];
    if (apellidos.isNotEmpty) iniciales += apellidos[0];
    return iniciales.isNotEmpty ? iniciales.toUpperCase() : 'A';
  }

  String _getNombreCompleto() {
    if (_adminProfile == null) return 'Administrador';

    final nombres = _adminProfile?['nombres']?.toString().trim() ?? '';
    final apellidos = _adminProfile?['apellidos']?.toString().trim() ?? '';

    if (nombres.isEmpty && apellidos.isEmpty) return 'Administrador';
    if (apellidos.isEmpty) return nombres;
    if (nombres.isEmpty) return apellidos;

    return '$nombres $apellidos';
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    bool isEditable = false,
    TextEditingController? controller,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: _isEditing && isEditable && controller != null
                ? TextField(
              controller: controller,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                suffixIcon: icon != null
                    ? Icon(icon, size: 20, color: Colors.grey.shade400)
                    : null,
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? value : 'No especificado',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: value.isNotEmpty
                            ? Colors.grey.shade800
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      margin: const EdgeInsets.only(top: 16, right: 20),
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isEditing = !_isEditing;
              if (!_isEditing) {
                _loadAdminProfile(); // Recargar datos originales
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isEditing ? Colors.grey.shade100 : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isEditing ? Colors.grey.shade300 : AppColors.primary,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                  size: 18,
                  color: _isEditing ? Colors.grey.shade600 : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _isEditing ? 'Cancelar' : 'Editar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isEditing ? Colors.grey.shade600 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final nombres = _adminProfile?['nombres']?.toString().trim() ?? '';
    final apellidos = _adminProfile?['apellidos']?.toString().trim() ?? '';
    final iniciales = _getIniciales(nombres, apellidos);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            const SizedBox(height: 40), // Espacio para el status bar

            // Header con botón de editar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Avatar e información
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            iniciales,
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Información del usuario
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getNombreCompleto(),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _adminProfile?['cargo'] ?? 'Administrador',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verificado',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Botón de editar (debajo de la información)
                  _buildEditButton(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Información Personal
            _buildInfoField(
              label: 'NOMBRES',
              value: _adminProfile?['nombres'] ?? '',
              isEditable: true,
              controller: _nombresController,
              icon: Icons.person_rounded,
            ),

            _buildInfoField(
              label: 'APELLIDOS',
              value: _adminProfile?['apellidos'] ?? '',
              isEditable: true,
              controller: _apellidosController,
              icon: Icons.person_outline_rounded,
            ),

            _buildInfoField(
              label: 'CORREO ELECTRÓNICO',
              value: _adminProfile?['email'] ?? '',
              icon: Icons.email_rounded,
            ),

            _buildInfoField(
              label: 'TELÉFONO',
              value: _adminProfile?['telefono'] ?? '',
              isEditable: true,
              controller: _telefonoController,
              icon: Icons.phone_rounded,
            ),

            _buildInfoField(
              label: 'CARGO',
              value: _adminProfile?['cargo'] ?? 'Administrador',
              isEditable: true,
              controller: _cargoController,
              icon: Icons.work_rounded,
            ),

            // Botón de guardar (solo en modo edición)
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Guardar Cambios',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _cargoController.dispose();
    super.dispose();
  }
}