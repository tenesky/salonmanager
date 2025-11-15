import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/connectivity_provider.dart';

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
  );
  // Start listening for connectivity changes.  The offline overlay
  // depends on this to update the UI when the device goes offline.
  ConnectivityProvider.instance.initialize();
  runApp(const MyApp());
}