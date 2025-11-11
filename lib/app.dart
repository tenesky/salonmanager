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
import 'features/salon/pages/salon_detail_page.dart';
import 'features/salon/models/salon.dart';
import 'features/onboarding/pages/onboarding_customer_page.dart';
import 'features/onboarding/pages/onboarding_salon_page.dart';
// Import map page for interactive map & filter. This page displays
// a Leaflet map with gold markers and a filter drawer according to
// the screen specification for the interactive map (Modul B)【522868310347694†L209-L214】.
import 'features/map/pages/salons_map_page.dart';
// Booking wizard step 1 placeholder
import 'features/booking/pages/booking_select_salon_page.dart';
import 'features/booking/pages/booking_select_service_page.dart';
import 'features/booking/pages/booking_select_stylist_page.dart';
import 'features/booking/pages/booking_select_date_page.dart';
import 'features/booking/pages/booking_select_time_page.dart';
import 'features/booking/pages/booking_additional_info_page.dart';
import 'features/booking/pages/booking_payment_page.dart';
import 'features/booking/pages/booking_summary_page.dart';
import 'features/booking/pages/booking_success_page.dart';
import 'features/booking/pages/bookings_list_page.dart';
import 'features/booking/pages/booking_detail_page.dart';
// Import the new incoming bookings page. This page shows pending
// booking requests for stylists or managers and allows them to
// accept or decline requests (Screen 28).
import 'features/booking/pages/incoming_bookings_page.dart';
import 'features/booking/pages/today_upcoming_bookings_page.dart';
// Import the cancel bookings page for mass cancellation. This page allows
// stylists or managers to select multiple appointments, specify a reason
// (e.g. sickness or overbooking) and send cancellations with a unified
// notification. It implements Screens 32–33 from the Realisierungsplan【73678961014422†L393-L398】.
import 'features/booking/pages/cancel_bookings_page.dart';
// Import the reminder settings page. This page lets stylists and managers
// configure appointment reminder timings (in hours or days) and enable or
// disable notification channels (Push/E‑Mail) as described in the
// Reminder‑Konfiguration specification【73678961014422†L1444-L1447】.
import 'features/settings/pages/reminder_settings_page.dart';
// Import service setup page for configuring price and duration per stylist
// per service. This page shows a matrix of services and stylists with
// editable cells for price, duration and activation state【73678961014422†L1515-L1519】.
import 'features/staff/pages/service_setup_page.dart';
// Import day calendar page for daily schedule. This page displays a timeline
// with columns per stylist and supports drag‑and‑drop to move bookings,
// matching Screen 36 of the calendar module【73678961014422†L1528-L1532】.
import 'features/calendar/pages/day_calendar_page.dart';
import 'features/calendar/pages/month_calendar_page.dart';
import 'features/booking/pages/booking_professional_detail_page.dart';
import 'features/settings/pages/notification_settings_page.dart';

// Import theme
import 'core/theme.dart';

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
      // Use the predefined light and dark themes from core/theme.dart. These define
      // primary and secondary colors (black and gold) and ensure consistent
      // styling across the app.
      theme: lightTheme,
      darkTheme: darkTheme,
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
        '/salon-detail': (context) {
          // Retrieve the Salon passed through the arguments. If none is
          // provided, fall back to a generic salon with example details.
          final args = ModalRoute.of(context)?.settings.arguments;
          Salon? salon;
          if (args is Salon) {
            salon = args;
          }
          salon ??= const Salon(
            name: 'Salonname',
            coverImage: 'assets/background_dark.png',
            logoImage: 'assets/logo_full.png',
            address: 'Musterstraße 1, 12345 Musterstadt',
            openingHours: 'Mo–Sa 09:00–18:00',
            phone: '+49 123 4567890',
          );
          return SalonDetailPage(salon: salon);
        },
        '/onboarding-customer': (context) => const OnboardingCustomerPage(),
        '/onboarding-salon': (context) => const OnboardingSalonPage(),
        // Interactive map view. Users can explore salons on a map and
        // refine their search using a filter drawer. This route
        // corresponds to Screen 11/12 in the screen specification.
        '/salons/map': (context) => const SalonsMapPage(),
        // Placeholder for the first step of the booking wizard. When the
        // quick booking bottom sheet is used on the salon detail page,
        // this route is opened. A full implementation of the wizard
        // will follow in later steps.
        '/booking/select-salon': (context) => const BookingSelectSalonPage(),
        '/booking/select-service': (context) => const BookingSelectServicePage(),
        '/booking/select-stylist': (context) => const BookingSelectStylistPage(),
        '/booking/select-date': (context) => const BookingSelectDatePage(),
        '/booking/select-time': (context) => const BookingSelectTimePage(),
        '/booking/additional-info': (context) => const BookingAdditionalInfoPage(),
        '/booking/payment': (context) => const BookingPaymentPage(),
        '/booking/summary': (context) => const BookingSummaryPage(),
        '/booking/success': (context) => const BookingSuccessPage(),
        '/bookings': (context) => const BookingsListPage(),
        '/bookings/detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return BookingDetailPage(booking: args);
          }
          return const Scaffold(
            body: Center(child: Text('Keine Details verfügbar.')),
          );
        },
        // Route for stylists to view and edit booking details. This
        // professional detail page allows adjusting price/duration per
        // service, adding notes and uploading images (Screen 30).
        '/bookings/pro-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return BookingProfessionalDetailPage(booking: args);
          }
          return const Scaffold(
            body: Center(child: Text('Keine Details verfügbar.')),
          );
        },
        // Route to the incoming bookings screen. This route is used by
        // stylists or managers to review new booking requests and
        // decide whether to accept or decline them.
        '/bookings/incoming': (context) => const IncomingBookingsPage(),
        // Display today's and upcoming bookings for stylists and
        // managers. This page implements Screen 29 (Heute / Nächste
        // Termine) with sectioned lists for the current day and
        // subsequent days.
        '/bookings/today-next': (context) => TodayUpcomingBookingsPage(),
        // Route to cancel one or multiple appointments. Stylists or
        // managers can select several upcoming bookings, choose a reason
        // and optionally add a custom message before sending a unified
        // cancellation notification to customers. This implements the
        // cancellation with reason and mass action described in
        // Screens 32–33【73678961014422†L393-L398】.
        '/bookings/cancel': (context) => const CancelBookingsPage(),
        '/settings/notifications': (context) => const NotificationSettingsPage(),
        // Route to configure reminder timings and channels. This settings
        // page allows selection of how many hours/days before an
        // appointment a reminder should be sent and whether Push and
        // E‑Mail notifications are enabled【73678961014422†L1502-L1505】.
        '/settings/reminder': (context) => const ReminderSettingsPage(),
        // Route to the service setup page. This screen presents a matrix
        // view where managers can configure for each stylist which
        // services are offered, override price and duration, and activate
        // or deactivate services【73678961014422†L1515-L1519】.
        '/staff/service-setup': (context) => const ServiceSetupPage(),
        // Route to the calendar day view. This screen shows a horizontal
        // timeline with one column per stylist and supports drag‑&‑drop
        // rescheduling and a floating action button to create new bookings.
        '/calendar/day': (context) => const DayCalendarPage(),
        // Route to the monthly calendar. This screen shows a month grid
        // with mini‑dots per day to represent appointments per stylist and
        // opens a modal day view when tapped (Screen 38)【73678961014422†L1528-L1532】.
        '/calendar/month': (context) => const MonthCalendarPage(),
        // Route used for demo login. Without a backend this simply opens the
        // Home page to allow testing of navigation and UI flows without
        // authentication.
        '/demo': (context) => const HomePage(),
      },
    );
  }
}
