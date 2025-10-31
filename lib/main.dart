import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';

// 🔹 Importaciones del proyecto
import 'services/supabase_client.dart'; // Cliente Supabase para autenticación y queries
import 'components/Layout.dart'; // Layout principal de la app
import 'screens/auth/register_screen.dart'; // Pantalla de registro
import 'screens/supervisor/supervisor_dashboard.dart'; // Dashboard de supervisor
import 'screens/admin/admin_dashboard.dart'; // Dashboard de admin
import 'styles/app_colors.dart'; // Colores y temas de la app

/// Punto de entrada de la aplicación Flutter
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura inicialización de Flutter antes de usar plugins

  try {
    await initSupabase(); // Inicializa Supabase
    debugPrint("✅ Conectado correctamente a Supabase");
  } catch (e) {
    debugPrint("❌ Error al conectar con Supabase: $e");
  }

  runApp(const GrupoProtegerApp()); // Corre la app
}

/// Clase principal de la aplicación
class GrupoProtegerApp extends StatelessWidget {
  const GrupoProtegerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grupo Proteger', // Nombre de la app
      debugShowCheckedModeBanner: false, // Oculta el banner de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background, // Fondo de pantallas
        useMaterial3: true, // Habilita Material 3
        textTheme: TextTheme(
          titleLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          bodyMedium: GoogleFonts.nunitoSans(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
      home: const SplashScreen(), // Pantalla inicial
      routes: {
        '/register': (context) => const RegisterScreen(), // Ruta a pantalla de registro
        '/home': (context) => const AppLayout(), // Ruta al layout principal
      },
    );
  }
}

/// SplashScreen: muestra el logo y verifica si el usuario tiene sesión activa
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AppLinks _appLinks; // Maneja deep links
  StreamSubscription<Uri>? _linkSub; // Suscripción a los enlaces entrantes

  @override
  void initState() {
    super.initState();
    _initializeAppLinks(); // Inicializa deep links
    _checkSession(); // Verifica si el usuario ya tiene sesión activa
  }

  /// 🔗 Inicializa AppLinks para manejar deep links (grupoproteger://auth-callback)
  Future<void> _initializeAppLinks() async {
    _appLinks = AppLinks();

    try {
      // Obtiene enlace inicial si la app fue abierta mediante deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleIncomingLink(initialUri);

      // Escucha enlaces entrantes mientras la app está abierta
      _linkSub = _appLinks.uriLinkStream.listen(
        _handleIncomingLink,
        onError: (err) => debugPrint("❌ Error en AppLinks: $err"),
      );
    } catch (e) {
      debugPrint("❌ Error al inicializar AppLinks: $e");
    }
  }

  /// Maneja los enlaces entrantes
  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'grupoproteger' && uri.host == 'auth-callback') {
      Fluttertoast.showToast(
        msg: "Correo confirmado ✅",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pushReplacementNamed(context, '/home'); // Redirige a home
    }
  }

  /// 🔐 Verifica la sesión y redirige según el rol del usuario
  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2)); // Simula splash

    final session = supabase.auth.currentSession; // Obtiene sesión actual

    if (session == null) {
      Navigator.pushReplacementNamed(context, '/register'); // Redirige a registro si no hay sesión
      return;
    }

    try {
      final user = session.user;

      if (user == null) {
        Navigator.pushReplacementNamed(context, '/register'); // Redirige si no hay usuario
        return;
      }

      // Consulta el rol del usuario en Supabase
      final profile = await supabase
          .from('profiles')
          .select('rol')
          .eq('id', user.id)
          .maybeSingle();

      final rol = profile?['rol'] ?? 'user'; // Default: usuario normal

      // Decide la pantalla según el rol
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al verificar sesión: $e");
      Fluttertoast.showToast(
        msg: "Error al verificar sesión.",
        backgroundColor: Colors.redAccent,
      );
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel(); // Cancela suscripción a enlaces
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Color de fondo del splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety_rounded,
                size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "Grupo Proteger", // Nombre de la app
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
