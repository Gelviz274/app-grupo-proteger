import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_client.dart';
import '../../styles/app_colors.dart';

/// Pantalla para editar el perfil del usuario.
/// Permite modificar nombres, apellidos, tipo y número de documento,
/// teléfono, dirección y género. El correo electrónico es solo lectura.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  /// Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  /// Controladores de texto para los campos editables
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _numeroDocumentoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  /// Variables para almacenar información no editable o seleccionada
  String? _email;
  String? _tipoDocumento;
  String? _genero;

  /// Estados de la pantalla
  bool _loading = true;   // Indica si se están cargando los datos del perfil
  bool _updating = false; // Indica si se está actualizando el perfil

  /// Listas de opciones para dropdowns
  final List<String> tipoDocumentoList = ['CC', 'TI', 'CE', 'Pasaporte'];
  final List<String> generoList = ['Masculino', 'Femenino', 'Otro'];

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Carga los datos del perfil al iniciar la pantalla
  }

  /// Carga los datos del perfil del usuario desde Supabase
  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: "Sesión expirada. Inicia sesión nuevamente.",
          backgroundColor: AppColors.warning,
        );
        return;
      }

      // Consulta a la tabla 'profiles' para obtener los datos del usuario
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _nombreController.text = response['nombres'] ?? '';
          _apellidoController.text = response['apellidos'] ?? '';
          _numeroDocumentoController.text = response['numero_documento'] ?? '';
          _telefonoController.text = response['telefono'] ?? '';
          _direccionController.text = response['direccion'] ?? '';
          _email = response['email'];

          // Validar que el valor exista en la lista de opciones
          final tipoDoc = response['tipo_documento'];
          final generoVal = response['genero'];
          _tipoDocumento = tipoDocumentoList.contains(tipoDoc) ? tipoDoc : null;
          _genero = generoList.contains(generoVal) ? generoVal : null;
        });
      }
    } catch (error) {
      debugPrint("❌❌ Error al cargar el perfil:$error ");
      Fluttertoast.showToast(
        msg: "Error al cargar perfil",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Actualiza el perfil del usuario en Supabase
  Future<void> _updateProfile() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) return;

    setState(() => _updating = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Actualización en la base de datos
      await supabase.from('profiles').update({
        'nombres': _nombreController.text.trim(),
        'apellidos': _apellidoController.text.trim(),
        'tipo_documento': _tipoDocumento,
        'numero_documento': _numeroDocumentoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'genero': _genero,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      Fluttertoast.showToast(
        msg: "Perfil actualizado correctamente ✅",
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
    } catch (error) {
      debugPrint("❌❌Error al actualizar perfil:$error");
      Fluttertoast.showToast(
        msg: "Error al actualizar perfil.",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loader mientras se cargan los datos
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Form(
        key: _formKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Editar perfil",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Actualiza tu información personal",
                style: GoogleFonts.nunitoSans(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 25),

              // Campos del formulario
              _buildInput("Nombres", _nombreController, Icons.person_outline),
              const SizedBox(height: 15),
              _buildInput("Apellidos", _apellidoController, Icons.person_outline),
              const SizedBox(height: 15),
              _buildDropdown(
                "Tipo de documento",
                _tipoDocumento,
                tipoDocumentoList,
                    (val) => setState(() => _tipoDocumento = val),
                Icons.badge_outlined,
              ),
              const SizedBox(height: 15),
              _buildInput("Número de documento", _numeroDocumentoController, Icons.credit_card),
              const SizedBox(height: 15),
              _buildDisabledInput("Correo electrónico", _email ?? '', Icons.email_outlined),
              const SizedBox(height: 15),
              _buildInput("Teléfono", _telefonoController, Icons.phone_outlined),
              const SizedBox(height: 15),
              _buildInput("Dirección", _direccionController, Icons.home_outlined),
              const SizedBox(height: 15),
              _buildDropdown(
                "Género",
                _genero,
                generoList,
                    (val) => setState(() => _genero = val),
                Icons.wc_outlined,
              ),
              const SizedBox(height: 30),

              // Botón de guardar cambios
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  onPressed: _updating ? null : _updateProfile,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: _updating
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    "Guardar cambios",
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

  /// Crea un campo de texto editable con validación
  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (value) =>
      value == null || value.isEmpty ? 'Campo requerido' : null,
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Crea un campo de texto no editable (solo lectura)
  Widget _buildDisabledInput(String label, String value, IconData icon) {
    return TextFormField(
      enabled: false,
      initialValue: value,
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Crea un dropdown con validación
  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      onChanged: onChanged,
      validator: (val) => val == null ? "Campo requerido" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((e) =>
          DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins(fontSize: 15))))
          .toList(),
    );
  }
}
