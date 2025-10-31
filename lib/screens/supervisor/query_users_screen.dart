import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/supabase_client.dart';
import '../../styles/app_colors.dart';

/// Pantalla para mostrar los usuarios registrados en la aplicación.
/// Permite buscar y filtrar usuarios por nombre o correo.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = []; // Lista completa de usuarios
  List<dynamic> _filteredUsuarios = []; // Lista filtrada según búsqueda
  bool _loading = true; // Estado de carga
  String _query = ""; // Texto de búsqueda actual

  @override
  void initState() {
    super.initState();
    _loadUsuarios(); // Carga inicial de usuarios al iniciar la pantalla
  }

  /// 🔹 Carga usuarios desde Supabase
  Future<void> _loadUsuarios() async {
    setState(() => _loading = true);
    try {
      debugPrint("🔹 Iniciando carga de usuarios...");
      final data = await supabase
          .from('profiles')
          .select('id, nombres, apellidos, numero_documento, email');
      debugPrint("🔹 Usuarios cargados: ${data.length}");

      setState(() {
        _usuarios = data;
        _filteredUsuarios = data;
      });
      debugPrint("🔹 Estado actualizado con usuarios");
    } catch (e) {
      debugPrint("❌ Error al cargar usuarios: $e");
      Fluttertoast.showToast(
        msg: "Error al cargar usuarios: $e",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _loading = false);
      debugPrint("🔹 Carga finalizada, loading = $_loading");
    }
  }

  /// 🔍 Filtra la lista de usuarios según la consulta
  void _filterUsuarios(String query) {
    debugPrint("🔍 Filtrando usuarios con query: $query");
    setState(() {
      _query = query.toLowerCase();
      _filteredUsuarios = _usuarios.where((u) {
        final nombre = (u['nombres'] ?? '').toLowerCase();
        final apellido = (u['apellidos'] ?? '').toLowerCase();
        final correo = (u['email'] ?? '').toLowerCase();
        final match = nombre.contains(_query) ||
            apellido.contains(_query) ||
            correo.contains(_query);
        if (match) debugPrint("✅ Coincidencia encontrada: $nombre $apellido");
        return match;
      }).toList();
      debugPrint("🔹 Total usuarios filtrados: ${_filteredUsuarios.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🖥️ Construyendo UI UsuariosScreen, loading=$_loading");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Usuarios registrados",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Buscador de usuarios
            TextField(
              onChanged: _filterUsuarios,
              decoration: InputDecoration(
                hintText: "Buscar por nombre o correo",
                hintStyle: GoogleFonts.nunitoSans(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Tabla de usuarios
            Expanded(
              child: _filteredUsuarios.isEmpty
                  ? Center(
                child: Text(
                  "No se encontraron usuarios",
                  style: GoogleFonts.nunitoSans(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              )
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: MaterialStateProperty.all(
                      AppColors.primary.withOpacity(0.1)),
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        "Nombre completo",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Documento",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Correo",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                  ],
                  rows: _filteredUsuarios.map((u) {
                    final nombreCompleto =
                        "${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}";
                    debugPrint("📌 Mostrando usuario: $nombreCompleto");
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          nombreCompleto,
                          style: GoogleFonts.nunitoSans(fontSize: 14),
                        )),
                        DataCell(Text(
                          u['numero_documento'] ?? '—',
                          style: GoogleFonts.nunitoSans(fontSize: 14),
                        )),
                        DataCell(Text(
                          u['email'] ?? '—',
                          style: GoogleFonts.nunitoSans(fontSize: 14),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
