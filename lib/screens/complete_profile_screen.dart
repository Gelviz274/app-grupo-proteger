import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/Layout.dart';
import '../services/supabase_client.dart';
import 'user/home_screen.dart';

/// 🔹 Pantalla para completar el perfil del usuario después del registro.
///
/// Recibe los datos básicos desde el registro: [userId], [email] y [nombre].
/// Permite al usuario ingresar información adicional, como:
/// - Apellidos
/// - Número y tipo de documento
/// - Teléfono
/// - Dirección
/// - Fecha de nacimiento
/// - Género
///
/// Al guardar, se inserta la información en la tabla `profiles` de Supabase
/// y se redirige al usuario a la pantalla principal [AppLayout].
class CompleteProfileScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String nombre;

  const CompleteProfileScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.nombre,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🔹 Controladores de los campos del formulario
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  // 🔹 Variables de selección
  DateTime? _fechaNacimiento;
  String? _tipoDocumento;
  String? _genero;

  bool _isSaving = false; // 🔹 Estado para mostrar indicador de carga

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.nombre; // Prellenar nombre desde registro
  }

  @override
  void dispose() {
    // 🔹 Liberar recursos de los controladores
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  /// 🔹 Guarda la información del perfil en Supabase
  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = supabase.auth.currentUser!;
      final Map<String, dynamic> newProfile = {
        'id': user.id,
        'email': widget.email,
        'nombres': _nombreController.text,
        'apellidos': _apellidoController.text,
        'numero_documento': _documentoController.text,
        'tipo_documento': _tipoDocumento,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
        'fecha_de_nacimiento': _fechaNacimiento != null
            ? _fechaNacimiento!.toIso8601String().split('T').first
            : null,
        'genero': _genero,
        'rol': 'user', // 🔹 Todos los perfiles completos son "user"
      };

      // 🔹 Elimina campos vacíos o nulos antes de insertar
      newProfile.removeWhere((k, v) => v == null || (v is String && v.isEmpty));

      // 🔹 Inserta el perfil en Supabase
      final response = await supabase.from('profiles').insert(newProfile).select();

      if (response.isEmpty) {
        Fluttertoast.showToast(
          msg: "Error al registrar perfil.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Perfil completado con éxito 🎉",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // 🔹 Redirige al layout principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AppLayout(userId: user.id)),
        );
      }
    } on PostgrestException catch (e) {
      debugPrint("ERROR: ${e.message}");
      Fluttertoast.showToast(
        msg: "Error al guardar perfil.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint("ERROR inesperado: $e");
      Fluttertoast.showToast(
        msg: "Error inesperado.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// 🔹 Muestra un selector de fecha para la fecha de nacimiento
  Future<void> _pickFecha(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF2B2F92);
    final Color lightBg = const Color(0xFFF6F8FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text("Completar Perfil"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🧩 Encabezado visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person_outline, size: 64, color: Color(0xFF2B2F92)),
                    const SizedBox(height: 12),
                    Text(
                      "Completa tu información personal",
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Estos datos ayudarán a personalizar tu experiencia.",
                      style: TextStyle(
                        color: Color(0xFF5F5F7E),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 📝 Campos del formulario
              _buildReadOnlyEmailField("Correo electrónico", widget.email),
              _buildInput("Nombres", _nombreController),
              _buildInput("Apellidos", _apellidoController),
              _buildDropdown(
                label: "Tipo de documento",
                value: _tipoDocumento,
                items: const {
                  "CC": "Cédula de ciudadanía",
                  "TI": "Tarjeta de identidad",
                  "CE": "Cédula de extranjería",
                },
                onChanged: (v) => setState(() => _tipoDocumento = v),
              ),
              _buildInput("Número de documento", _documentoController,
                  keyboard: TextInputType.number),
              _buildInput("Teléfono", _telefonoController,
                  keyboard: TextInputType.phone),
              _buildInput("Dirección", _direccionController),
              _buildDatePicker(context),
              _buildDropdown(
                label: "Género",
                value: _genero,
                items: const {
                  "Masculino": "Masculino",
                  "Femenino": "Femenino",
                  "Otro": "Otro"
                },
                onChanged: (v) => setState(() => _genero = v),
              ),
              const SizedBox(height: 30),

              // 🌈 Botón guardar perfil
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2B2F92), Color(0xFF00B2FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Guardar perfil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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

  /// 🔹 Campo de texto genérico
  Widget _buildInput(String label, TextEditingController controller,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
      ),
    );
  }

  /// 🔹 Campo de correo solo lectura
  Widget _buildReadOnlyEmailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        readOnly: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFEFF1FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// 🔹 Dropdown genérico
  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Selecciona una opción" : null,
      ),
    );
  }

  /// 🔹 Selector de fecha de nacimiento
  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _pickFecha(context),
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Fecha de nacimiento",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fechaNacimiento == null
                    ? "Seleccionar fecha"
                    : _fechaNacimiento!.toIso8601String().split('T').first,
                style: const TextStyle(color: Colors.black87),
              ),
              const Icon(Icons.calendar_today, color: Color(0xFF2B2F92)),
            ],
          ),
        ),
      ),
    );
  }
}
