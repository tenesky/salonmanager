import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

/// Entry point of the SalonManager Flutter application.
///
/// This method initializes the Supabase client before running the app.
/// Replace the `supabaseUrl` and `supabaseAnonKey` with your own
/// Supabase project URL and anonymous public key. The initialization
/// is asynchronous, so we ensure that Flutter bindings are ready
/// before awaiting the call.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Replace with your own Supabase credentials.  The URL
  // should follow the pattern https://xxxx.supabase.co and the
  // anonymous key can be found in your Supabase project settings.
  const supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
  const supabaseAnonKey = 'YOUR-ANON-KEY';
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}