import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/connectivity_provider.dart';
import 'app.dart';

/// Entry point of the SalonManager Flutter application.
///
/// Initializes the Supabase client before running the app. Supabase provides
/// authentication, realtime database and Postgres access without the need
/// for a dedicated backend. The URL and anon/publishable key must be
/// replaced with your Supabase project details. You can find them in the
/// Supabase Dashboard under Project Settings → API. Use the **public
/// client key** (also called “anon” or “publishable” key) here; do not
/// embed your service role key in the client. See documentation:
/// https://supabase.com/docs/guides/with-flutter
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase with the provided project URL and anon (publishable) key.
  // These values are specific to your Supabase project and should be kept
  // confidential. Do not include any service role key here.
  await Supabase.initialize(
    url: 'https://tojygtbhddmlgyilgcyj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRvanlndGJoZGRtbGd5aWxnY3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDA2MDksImV4cCI6MjA3ODQ3NjYwOX0.j0IoIRZZQfX_FS0lHd1xOpE5pUfEQ9lsKi5sX2vtIJg',
    // Sessions persist across app launches and tokens refresh automatically by default
    // in supabase_flutter v2.x, so explicit AuthOptions are not required.
  );
  // Initialize connectivity monitoring so the offline overlay works from
  // the very start of the app.
  ConnectivityProvider.instance.initialize();
  runApp(const MyApp());
}