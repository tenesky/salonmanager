import 'package:flutter/material.dart';
// Import pages for routing. Using relative imports keeps the package simple
// while it is under local development.
import 'features/auth/pages/welcome_page.dart';
import 'features/auth/pages/login_page.dart';

/// The root widget of the application. This sets up a basic
/// [MaterialApp] with placeholder theming and a placeholder home
/// widget.  Detailed routing, theming and state management will be
/// added as the project progresses.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalonManager',
      // Provide light and dark themes; actual colors are defined in core/theme.dart.
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      // Define the initial route and route table.
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
