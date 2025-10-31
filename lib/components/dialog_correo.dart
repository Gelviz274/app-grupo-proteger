import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';
import '../screens/complete_profile_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String userId;
  final String nombre;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.userId,
    required this.nombre,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _checking = false;
  bool _emailConfirmed = false;

  @override
  void initState() {
    super.initState();
    _checkIfVerified(); // Verifica una vez al inicio
    _startEmailCheck(); // Luego cada 5 segundos
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmailCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkIfVerified();
    });
  }

  Future<void> _checkIfVerified() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      // 🔄 Actualiza sesión para obtener el estado más reciente del usuario
      final refreshResponse = await supabase.auth.refreshSession();
      if (refreshResponse.session == null) {
        debugPrint("⚠️ No hay sesión activa.");
        setState(() => _checking = false);
        return;
      }

      // 🔎 Verifica si el correo ya fue confirmado
      final userResponse = await supabase.auth.getUser();
      final user = userResponse.user;

      if (user != null && user.emailConfirmedAt != null) {
        if (!_emailConfirmed) {
          _timer?.cancel();
          setState(() => _emailConfirmed = true);

          Fluttertoast.showToast(
            msg: "Correo verificado ✅",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CompleteProfileScreen(
                  userId: widget.userId,
                  email: widget.email,
                  nombre: widget.nombre,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error al verificar el estado del correo: $e");
    } finally {
      setState(() => _checking = false);
    }
  }

  Future<void> _resendEmail() async {
    try {
      await supabase.auth.signInWithOtp(
        email: widget.email,
        emailRedirectTo: 'afiliateya://auth-callback',
      );

      Fluttertoast.showToast(
        msg: "Correo de verificación reenviado ✉️",
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al reenviar el correo",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      debugPrint("❌ Error reenviando correo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_rounded, size: 100, color: Color(0xFF2B3395)),
            const SizedBox(height: 20),
            Text(
              "Verifica tu correo",
              style: const TextStyle(
                color: Color(0xFF2B3395),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Te hemos enviado un enlace de confirmación a:\n${widget.email}\n\n"
                  "Por favor, revisa tu bandeja de entrada y da clic en el enlace para continuar.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            _checking
                ? const CircularProgressIndicator(color: Color(0xFF2B3395))
                : ElevatedButton.icon(
              onPressed: _resendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B3395),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Reenviar correo",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _emailConfirmed
                  ? "Correo confirmado ✅"
                  : "Esperando confirmación...",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
