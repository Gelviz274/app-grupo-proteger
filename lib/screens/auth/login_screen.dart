import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_client.dart'; // Cliente Supabase para autenticación
import '../../styles/app_colors.dart'; // Colores y estilos de la app
import 'register_screen.dart'; // Pantalla de registro
import '../../components/layout.dart'; // Layout principal de usuario normal
import '../supervisor/supervisor_dashboard.dart'; // Dashboard de supervisor
import '../admin/admin_dashboard.dart'; // Dashboard de admin

/// Pantalla de inicio de sesión de la aplicación
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(); // Controlador del input de correo
  final _passwordController = TextEditingController(); // Controlador del input de contraseña

  bool _isLoading = false; // Indica si se está procesando el login
  bool _obscurePassword = true; // Oculta o muestra la contraseña

  /// 🔹 Función principal para iniciar sesión
  /// Valida campos, llama a Supabase y redirige según el rol
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validación básica de campos
    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: "Por favor completa todos los campos",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔑 Intento de inicio de sesión con Supabase
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      // Validación del usuario
      if (user == null || user.id.isEmpty) {
        Fluttertoast.showToast(
          msg: "Credenciales incorrectas o usuario no encontrado",
          backgroundColor: AppColors.warning,
          textColor: Colors.white,
        );
        return;
      }

      // 🔍 Obtiene el rol desde la tabla profiles
      final profile = await supabase
          .from('profiles')
          .select('rol')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        Fluttertoast.showToast(
          msg: "No se encontró información de tu perfil. Contacta al administrador.",
          backgroundColor: AppColors.warning,
          textColor: Colors.white,
        );
        return;
      }

      final String rol = profile['rol'] ?? 'user';

      // 🔀 Determina la pantalla siguiente según el rol
      Widget nextScreen;
      switch (rol) {
        case 'admin':
          nextScreen = const AdminDashboard();
          break;
        case 'supervisor':
          nextScreen = const HomeSupervisorScreen();
          break;
        default:
          nextScreen = AppLayout(userId: user.id);
      }

      // Mensaje de éxito
      Fluttertoast.showToast(
        msg: "Inicio de sesión exitoso 🎉",
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

      // Navega a la pantalla correspondiente reemplazando la actual
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } on AuthException catch (e) {
      // Manejo de errores de autenticación
      Fluttertoast.showToast(
        msg: e.message,
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } catch (e) {
      // Errores inesperados
      debugPrint("❌ Error inesperado: $e");
      Fluttertoast.showToast(
        msg: "Error al iniciar sesión",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🧩 Logo de la app
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.primary,
                    size: 70,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "Bienvenido a Grupo Proteger",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Accede a tu cuenta para continuar",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 35),

                // Campo de correo
                _buildTextField(
                  controller: _emailController,
                  label: "Correo electrónico",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 18),
                // Campo de contraseña
                _buildPasswordField(
                  controller: _passwordController,
                  label: "Contraseña",
                  obscure: _obscurePassword,
                  toggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 35),

                // Botón de login
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      "Iniciar sesión",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Enlace a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No tienes una cuenta? ",
                      style: GoogleFonts.nunitoSans(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        "Regístrate aquí",
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
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

  /// ================== COMPONENTES ==================
  /// Campo de texto genérico
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primary),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  /// Campo de contraseña con toggle para mostrar/ocultar
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey.shade600,
          ),
          onPressed: toggle,
        ),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
