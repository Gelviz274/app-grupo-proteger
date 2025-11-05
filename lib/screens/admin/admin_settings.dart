import 'package:afiliateya/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/app_colors.dart';
import 'ChangePasswordScreen.dart'; // ✅ Import agregado

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Estados realistas para Supabase
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _weeklyReports = false;
  bool _darkMode = false;
  bool _biometricAuth = false;

  // Información del usuario
  Map<String, dynamic>? _userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _userProfile = response;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Intentar cargar configuraciones guardadas
        final settings = await supabase
            .from('user_settings')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (settings != null) {
          setState(() {
            _emailNotifications = settings['email_notifications'] ?? true;
            _pushNotifications = settings['push_notifications'] ?? true;
            _weeklyReports = settings['weekly_reports'] ?? false;
            _darkMode = settings['dark_mode'] ?? false;
            _biometricAuth = settings['biometric_auth'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('user_settings').upsert({
          'user_id': user.id,
          'email_notifications': _emailNotifications,
          'push_notifications': _pushNotifications,
          'weekly_reports': _weeklyReports,
          'dark_mode': _darkMode,
          'biometric_auth': _biometricAuth,
          'updated_at': DateTime.now().toIso8601String(),
        });

        _showSnackBar('Configuraciones guardadas');
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      _showSnackBar('Error al guardar configuraciones', isError: true);
    }
  }

  Future<void> _exportUserData() async {
    try {
      _showSnackBar('Preparando exportación de datos...');

      // Exportar datos del perfil
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', supabase.auth.currentUser!.id)
          .single();

      // Exportar actividad reciente (ejemplo)
      final recentActivity = await supabase
          .from('audit_logs')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50);

      // Simular generación de archivo
      final exportData = {
        'profile': profileData,
        'recent_activity': recentActivity,
        'exported_at': DateTime.now().toIso8601String(),
      };

      // En una app real, aquí guardarías el archivo o lo compartirías
      debugPrint('Datos exportados: $exportData');

      _showSnackBar('Datos exportados correctamente');
    } catch (e) {
      debugPrint('Error exporting data: $e');
      _showSnackBar('Error al exportar datos', isError: true);
    }
  }

  Future<void> _clearCache() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cleaning_services_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              Text(
                'Limpiar Cache',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres limpiar la cache de la aplicación? Esta acción no afectará tus datos en el servidor.',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Limpiar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Simular limpieza de cache
        await Future.delayed(const Duration(seconds: 1));
        _showSnackBar('Cache limpiada correctamente');
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      _showSnackBar('Error al limpiar cache', isError: true);
    }
  }

  // ✅ ACTUALIZADO: Ahora navega a la pantalla de cambiar contraseña con callback
  Future<void> _changePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          onPasswordChanged: () {
            // Este callback se ejecuta cuando la contraseña se cambia exitosamente
            _showSnackBar('✅ Contraseña cambiada exitosamente');
          },
        ),
      ),
    );
  }

  Future<void> _viewPrivacyPolicy() async {
    // En una app real, esto abriría una URL o navegaría a una pantalla
    _showSnackBar('Abriendo política de privacidad...');

    // Ejemplo de cómo abrir una URL:
    // if (await canLaunchUrl(Uri.parse('https://tudominio.com/privacy'))) {
    //   await launchUrl(Uri.parse('https://tudominio.com/privacy'));
    // }
  }

  Future<void> _viewTermsOfService() async {
    // En una app real, esto abriría una URL o navegaría a una pantalla
    _showSnackBar('Abriendo términos de servicio...');

    // Ejemplo de cómo abrir una URL:
    // if (await canLaunchUrl(Uri.parse('https://tudominio.com/terms'))) {
    //   await launchUrl(Uri.parse('https://tudominio.com/terms'));
    // }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al cerrar sesión: $e', isError: true);
      }
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade500),
            const SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión? Tendrás que iniciar sesión nuevamente para acceder a la aplicación.',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade700,
          ),
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
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget trailing,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: itemColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuración',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ajustes de la aplicación y cuenta',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
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

          // Contenido
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // Notificaciones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Notificaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              _buildSettingItem(
                title: 'Notificaciones Push',
                subtitle: 'Recibir notificaciones en la aplicación',
                trailing: Switch.adaptive(
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _saveSettings();
                  },
                  activeColor: AppColors.primary,
                ),
                icon: Icons.notifications_rounded,
              ),

              _buildSettingItem(
                title: 'Notificaciones por Email',
                subtitle: 'Recibir notificaciones por correo electrónico',
                trailing: Switch.adaptive(
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _saveSettings();
                  },
                  activeColor: AppColors.primary,
                ),
                icon: Icons.email_rounded,
              ),

              _buildSettingItem(
                title: 'Reportes Semanales',
                subtitle: 'Recibir reportes de actividad cada semana',
                trailing: Switch.adaptive(
                  value: _weeklyReports,
                  onChanged: (value) {
                    setState(() => _weeklyReports = value);
                    _saveSettings();
                  },
                  activeColor: AppColors.primary,
                ),
                icon: Icons.analytics_rounded,
              ),

              const SizedBox(height: 24),

              // Apariencia y Seguridad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Apariencia y Seguridad',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              _buildSettingItem(
                title: 'Modo Oscuro',
                subtitle: 'Activar el tema oscuro de la aplicación',
                trailing: Switch.adaptive(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    _saveSettings();
                  },
                  activeColor: AppColors.primary,
                ),
                icon: Icons.dark_mode_rounded,
              ),

              _buildSettingItem(
                title: 'Autenticación Biométrica',
                subtitle: 'Usar huella digital o reconocimiento facial',
                trailing: Switch.adaptive(
                  value: _biometricAuth,
                  onChanged: (value) {
                    setState(() => _biometricAuth = value);
                    _saveSettings();
                  },
                  activeColor: AppColors.primary,
                ),
                icon: Icons.fingerprint_rounded,
              ),

              const SizedBox(height: 24),

              // Cuenta
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Cuenta',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ✅ ACTUALIZADO: Ahora usa la nueva función _changePassword
              _buildActionItem(
                title: 'Cambiar Contraseña',
                subtitle: 'Actualizar tu contraseña de acceso',
                icon: Icons.lock_reset_rounded,
                onTap: _changePassword,
                color: Colors.blue.shade600,
              ),

              _buildActionItem(
                title: 'Exportar Mis Datos',
                subtitle: 'Descargar toda tu información',
                icon: Icons.backup_rounded,
                onTap: _exportUserData,
                color: Colors.green.shade600,
              ),

              _buildActionItem(
                title: 'Limpiar Cache',
                subtitle: 'Eliminar datos temporales de la aplicación',
                icon: Icons.cleaning_services_rounded,
                onTap: _clearCache,
                color: Colors.orange.shade600,
              ),

              const SizedBox(height: 24),

              // Legal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Legal',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              _buildActionItem(
                title: 'Política de Privacidad',
                subtitle: 'Cómo manejamos tus datos',
                icon: Icons.privacy_tip_rounded,
                onTap: _viewPrivacyPolicy,
                color: Colors.purple.shade600,
              ),

              _buildActionItem(
                title: 'Términos de Servicio',
                subtitle: 'Términos y condiciones de uso',
                icon: Icons.description_rounded,
                onTap: _viewTermsOfService,
                color: Colors.purple.shade600,
              ),

              // Cerrar Sesión
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showSignOutDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.red.shade500,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cerrar Sesión',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Información de la versión
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Versión 1.0.0 • Grupo Proteger',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}