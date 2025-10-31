//  Codigo de conexion con supabase

import 'package:supabase_flutter/supabase_flutter.dart';
    
final supabase = Supabase.instance.client;

// Iniciar servicio

Future<void> initSupabase() async{
  await Supabase.initialize(
      url: 'https://nbutzolexcfxilqvgbdy.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5idXR6b2xleGNmeGlscXZnYmR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMzczMDYsImV4cCI6MjA3NjgxMzMwNn0.btzx7wy76krZ4FHK_SVBjB8uq_ldd3eSgOi2lqZZEPw'
  );
}