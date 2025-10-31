import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_client.dart'; // Cliente Supabase para autenticación
import '../../components/dialog_correo.dart'; // Componente para verificación de correo
import 'login_screen.dart'; // Pantalla de login
import '../../styles/app_colors.dart'; // Colores y estilos de la app

/// Pantalla de registro de usuarios
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController(); // Input correo
  final _passwordController = TextEditingController(); // Input contraseña
  final _confirmPasswordController = TextEditingController(); // Input confirmar contraseña

  bool _isLoading = false; // Indica si se está procesando el registro
  bool _obscurePassword = true; // Oculta o muestra la contraseña
  bool _obscureConfirmPassword = true; // Oculta o muestra la confirmación de contraseña

  /// ================== REGISTRO ==================
  /// Función que valida los campos, crea la cuenta en Supabase y redirige
  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validación de campos vacíos
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(
        msg: "Por favor completa todos los campos",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
      return;
    }

    // Validación de coincidencia de contraseñas
    if (password != confirmPassword) {
      Fluttertoast.showToast(
        msg: "Las contraseñas no coinciden",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔑 Registro con Supabase
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'grupoproteger://auth-callback', // Link de verificación
      );

      if (response.user != null) {
        Fluttertoast.showToast(
          msg: "Cuenta creada 🎉 Revisa tu correo para confirmar.",
          backgroundColor: AppColors.success,
          textColor: Colors.white,
        );

        // Navega a pantalla de verificación de correo
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(
                email: email,
                userId: response.user!.id,
                nombre: '',
              ),
            ),
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Error al crear la cuenta. Inténtalo nuevamente.",
          backgroundColor: AppColors.warning,
          textColor: Colors.white,
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌❌ Error de servidor: $e');
      Fluttertoast.showToast(
        msg: e.message,
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } catch (_) {
      Fluttertoast.showToast(
        msg: "Ocurrió un error inesperado. Intenta más tarde.",
        backgroundColor: AppColors.warning,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ================== INTERFAZ ==================
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
                // 🧩 Logo y título
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
                  "Grupo Proteger",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Crea tu cuenta para continuar",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 35),

                // 📩 Campos de entrada
                _buildTextField(
                  controller: _emailController,
                  label: "Correo electrónico",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 18),
                _buildPasswordField(
                  controller: _passwordController,
                  label: "Contraseña",
                  obscure: _obscurePassword,
                  toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 18),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: "Confirmar contraseña",
                  obscure: _obscureConfirmPassword,
                  toggle: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                const SizedBox(height: 35),

                // 🔘 Botón de registro
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
                    onPressed: _isLoading ? null : _register,
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
                      "Registrarse",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Enlace a pantalla de login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes una cuenta? ",
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
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        "Inicia sesión",
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
