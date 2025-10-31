import 'dart:io';
import 'package:afiliateya/screens/user/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../components/Layout.dart';
import '../../styles/app_colors.dart'; // ✅ Importamos la paleta global

final supabase = Supabase.instance.client;
final uuid = Uuid();

class CreateAffiliationScreen extends StatefulWidget {
  const CreateAffiliationScreen({super.key});

  @override
  State<CreateAffiliationScreen> createState() => _CreateAffiliationScreenState();
}

class _CreateAffiliationScreenState extends State<CreateAffiliationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _ingresoController = TextEditingController();

  String? _tipoAfiliacion;
  String? _tipoPlan;
  String? _entidad;
  bool _saving = false;
  bool _isFormatting = false;

  File? _cedulaFile;

  final List<String> tiposAfiliacion = ['Dependiente', 'Independiente', 'Voluntario'];
  final List<String> tiposPlan = ['Salud', 'Pensión', 'Riesgos Laborales', 'Caja de Compensación'];
  final List<String> entidades = [
    'Nueva EPS',
    'Colpensiones',
    'Sura',
    'Sanitas',
    'Compensar',
    'AXA Colpatria',
    'Coomeva',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _ingresoController.addListener(_formatCurrency);
  }

  void _formatCurrency() {
    if (_isFormatting) return;
    _isFormatting = true;

    String text = _ingresoController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      _ingresoController.value = const TextEditingValue(text: '');
      _isFormatting = false;
      return;
    }

    final buffer = StringBuffer();
    int count = 0;
    for (int i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    final formatted = buffer.toString().split('').reversed.join();
    final formattedText = "\$ $formatted";

    _ingresoController.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );

    _isFormatting = false;
  }

  Future<void> _pickFile(Function(File) onSelected) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'], // ✅ Solo PDF y DOC
    );

    if (result != null && result.files.single.path != null) {
      onSelected(File(result.files.single.path!));
    }
  }

  Future<String?> _uploadFile(File file, String bucket) async {
    final user = supabase.auth.currentUser!;
    final ext = file.path.split('.').last;
    final objectName = '${uuid.v4()}.$ext';
    final path = 'user/${user.id}/$objectName';

    try {
      await supabase.storage.from(bucket).upload(path, file);
      return supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('❌ Error subiendo archivo: $e');
      return null;
    }
  }

  Future<void> _crearAfiliacion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cedulaFile == null) {
      Fluttertoast.showToast(
        msg: "Debes adjuntar la copia de la cédula.",
        backgroundColor: Colors.orangeAccent,
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "Debes iniciar sesión.", backgroundColor: Colors.red);
      return;
    }

    setState(() => _saving = true);
    final bucketId = 'bucked_documents';
    final userId = user.id;
    final now = DateTime.now().toUtc();
    final afiliacionId = uuid.v4();

    try {
      final cedulaUrl = await _uploadFile(_cedulaFile!, bucketId);
      if (cedulaUrl == null) {
        Fluttertoast.showToast(
          msg: "Error al subir la cédula.",
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      final ingresoLimpio = _ingresoController.text.replaceAll(RegExp(r'[^0-9]'), '');

      await supabase.from('Afiliaciones').insert({
        'id': afiliacionId,
        'user_id': userId,
        'tipo_plan': _tipoPlan,
        'entidad': _entidad,
        'tipo_afiliacion': _tipoAfiliacion,
        'estado': 'Pendiente',
        'ingreso': double.tryParse(ingresoLimpio) ?? 0,
        'observaciones': _observacionesController.text.trim(),
        'copia_cedula': cedulaUrl,
        'created_at': now.toIso8601String(),
        'verificado_supervisor': 'FALSE'
      });

      Fluttertoast.showToast(
        msg: "Afiliación creada con éxito ✅",
        backgroundColor: Colors.green,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppLayout()),
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
      Fluttertoast.showToast(
        msg: "Error al crear afiliación.",
        backgroundColor: Colors.redAccent,
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildDropdown("Tipo de afiliación", _tipoAfiliacion, tiposAfiliacion,
                      (val) => setState(() => _tipoAfiliacion = val)),
              const SizedBox(height: 15),
              _buildDropdown("Tipo de plan", _tipoPlan, tiposPlan,
                      (val) => setState(() => _tipoPlan = val)),
              const SizedBox(height: 15),
              _buildDropdown("Entidad", _entidad, entidades,
                      (val) => setState(() => _entidad = val)),
              const SizedBox(height: 20),
              _buildInput("Ingreso mensual (COP)", _ingresoController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildInput("Observaciones (opcional)", _observacionesController, maxLines: 3),
              const SizedBox(height: 25),
              _buildFilePicker("Copia de la cédula *", _cedulaFile,
                      () => _pickFile((file) => setState(() => _cedulaFile = file))),
              const SizedBox(height: 35),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in_rounded,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Completa los datos de tu afiliación y adjunta la copia de tu cédula.",
              style: GoogleFonts.nunitoSans(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? "Campo requerido" : null,
      decoration: _inputDecoration(label),
      items: items
          .map((e) => DropdownMenuItem(
          value: e, child: Text(e, style: GoogleFonts.poppins(fontSize: 15))))
          .toList(),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (label.contains("opcional")) return null;
        return value == null || value.isEmpty ? "Campo requerido" : null;
      },
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppColors.textPrimary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    );
  }

  Widget _buildFilePicker(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: file != null ? AppColors.secondary : AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                if (file != null)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file_rounded,
                    color: file != null ? AppColors.secondary : Colors.grey, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file != null
                        ? file.path.split('/').last
                        : "Seleccionar archivo .pdf o .doc",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15,
                      color: file != null ? AppColors.secondary : Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _crearAfiliacion,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        label: _saving
            ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        )
            : Text(
          "Registrar afiliación",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}
