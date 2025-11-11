import 'package:flutter/material.dart';
// Import pages for routing. Using relative imports keeps the package simple
// while it is under local development.
import 'features/auth/pages/welcome_page.dart';
import 'features/auth/pages/login_page.dart';
// Import newly created authentication and onboarding pages.
import 'features/auth/pages/two_factor_page.dart';
import 'features/auth/pages/register_customer_page.dart';
import 'features/auth/pages/register_salon_page.dart';
import 'features/auth/pages/forgot_password_page.dart';
import 'features/auth/pages/reset_password_page.dart';
// Import home and salon pages
import 'features/home/pages/home_page.dart';
import 'features/salon/pages/salon_list_page.dart';

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
        '/two-factor': (context) => const TwoFactorPage(),
        '/register-customer': (context) => const RegisterCustomerPage(),
        '/register-salon': (context) => const RegisterSalonPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/salon-list': (context) => const SalonListPage(),
      },
    );
  }
}
