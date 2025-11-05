import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/app_colors.dart';

class AdminProfilesScreen extends StatefulWidget {
  const AdminProfilesScreen({super.key});

  @override
  State<AdminProfilesScreen> createState() => _AdminProfilesScreenState();
}

class _AdminProfilesScreenState extends State<AdminProfilesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> profiles = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProfiles = [];

  @override
  void initState() {
    super.initState();
    fetchProfiles();
    _searchController.addListener(_filterProfiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProfiles() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredProfiles = profiles;
      });
    } else {
      setState(() {
        filteredProfiles = profiles.where((profile) {
          final nombres = profile['nombres']?.toString().toLowerCase() ?? '';
          final apellidos = profile['apellidos']?.toString().toLowerCase() ?? '';
          final email = profile['email']?.toString().toLowerCase() ?? '';
          final university = profile['university']?.toString().toLowerCase() ?? '';

          return nombres.contains(query) ||
              apellidos.contains(query) ||
              email.contains(query) ||
              university.contains(query);
        }).toList();
      });
    }
  }

  Future<void> fetchProfiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await supabase.from('profiles').select();
      setState(() {
        profiles = (data as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
        filteredProfiles = profiles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfiles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteProfile(String id, String nombreCompleto) async {
    try {
      await supabase.from('profiles').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil de $nombreCompleto eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
      fetchProfiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getNombreCompleto(Map<String, dynamic> profile) {
    final nombres = profile['nombres']?.toString().trim() ?? '';
    final apellidos = profile['apellidos']?.toString().trim() ?? '';

    if (nombres.isEmpty && apellidos.isEmpty) return 'Usuario sin nombre';
    if (apellidos.isEmpty) return nombres;
    if (nombres.isEmpty) return apellidos;

    return '$nombres $apellidos';
  }

  String _getIniciales(Map<String, dynamic> profile) {
    final nombres = profile['nombres']?.toString().trim() ?? '';
    final apellidos = profile['apellidos']?.toString().trim() ?? '';

    String iniciales = '';
    if (nombres.isNotEmpty) iniciales += nombres[0];
    if (apellidos.isNotEmpty) iniciales += apellidos[0];

    return iniciales.isNotEmpty ? iniciales.toUpperCase() : 'U';
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    final nombreCompleto = _getNombreCompleto(profile);
    final iniciales = _getIniciales(profile);
    final email = profile['email'] ?? 'Sin correo';
    final university = profile['university'];
    final createdAt = profile['created_at'];

    // Colores para el avatar
    final colors = [
      Colors.blue.shade500,
      Colors.green.shade500,
      Colors.orange.shade500,
      Colors.purple.shade500,
      Colors.red.shade500,
      Colors.teal.shade500,
    ];
    final avatarColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Podrías agregar navegación a detalles del perfil aquí
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar con iniciales
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        avatarColor,
                        avatarColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      iniciales,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Información del perfil
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreCompleto,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Universidad
                      if (university != null && university.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                university,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      // Fecha de creación
                      if (createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Registrado: ${_formatDate(createdAt)}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Botón de eliminar
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(profile, nombreCompleto);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  void _showDeleteDialog(Map<String, dynamic> profile, String nombreCompleto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400),
            const SizedBox(width: 12),
            Text(
              'Eliminar Perfil',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar el perfil de:',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nombreCompleto,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProfile(profile['id'].toString(), nombreCompleto);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, email o universidad...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
          ),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${filteredProfiles.length} perfil${filteredProfiles.length != 1 ? 'es' : ''} encontrado${filteredProfiles.length != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de perfiles
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : filteredProfiles.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  profiles.isEmpty
                      ? 'No hay perfiles registrados'
                      : 'No se encontraron resultados',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                ),
                if (profiles.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    child: Text(
                      'Limpiar búsqueda',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            )
                : RefreshIndicator(
              onRefresh: fetchProfiles,
              color: AppColors.primary,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredProfiles.length,
                itemBuilder: (context, index) {
                  return _buildProfileCard(filteredProfiles[index], index);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchProfiles,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}