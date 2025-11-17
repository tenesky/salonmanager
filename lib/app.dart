import 'package:flutter/material.dart';
// Import pages for routing. Using relative imports keeps the package simple
// while it is under local development.
import 'features/auth/pages/welcome_page.dart';
import 'features/auth/pages/login_page.dart';
// Import the splash page to display on app startup. This simple
// introductory screen shows the logo and a loading indicator before
// navigating to the welcome page.
import 'features/auth/pages/splash_page.dart';
// Import newly created authentication and onboarding pages.
import 'features/auth/pages/two_factor_page.dart';
import 'features/auth/pages/register_customer_page.dart';
import 'features/auth/pages/register_salon_page.dart';
import 'features/auth/pages/register_admin_page.dart';
import 'features/auth/pages/forgot_password_page.dart';
import 'features/auth/pages/reset_password_page.dart';
// Import home and salon pages
import 'features/home/pages/home_page.dart';
import 'features/salon/pages/salon_list_page.dart';
import 'features/salon/pages/salon_detail_page.dart';
import 'features/salon/pages/salon_apply_page.dart';
import 'features/salon/models/salon.dart';
import 'features/onboarding/pages/onboarding_customer_page.dart';
import 'features/onboarding/pages/onboarding_salon_page.dart';
// Import map page for interactive map & filter. This page displays
// a Leaflet map with gold markers and a filter drawer according to
// the screen specification for the interactive map (Modul B)【522868310347694†L209-L214】.
import 'features/map/pages/salons_map_page.dart';
// Import the full screen home map page for the mini map. This page
// replicates the interactive map design shown in the UI specification
// when customers tap the mini map on the home page. It includes a
// map/list toggle, search bar, filter button and bottom salon
// preview cards.
import 'features/home/pages/home_map_page.dart';
import 'features/salon/pages/customer_salon_detail_page.dart';
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
// Import the loyalty overview page. This page shows the customer's points,
// level and available rewards. It implements Screen 53 (Treue‑Übersicht).
import 'features/loyalty/pages/loyalty_overview_page.dart';
import 'features/loyalty/pages/loyalty_rules_page.dart';
import 'features/loyalty/pages/loyalty_rules_page.dart';
// Import service setup page for configuring price and duration per stylist
// per service. This page shows a matrix of services and stylists with
// editable cells for price, duration and activation state【73678961014422†L1515-L1519】.
import 'features/staff/pages/service_setup_page.dart';
import 'features/staff/pages/assign_services_page.dart';
// Import the team management page. This screen lists salon
// members, allows role assignment and activation toggling, and can
// invite new members via email.
import 'features/staff/pages/team_page.dart';
import 'features/customer/pages/customer_list_page.dart';
import 'features/customer/pages/customer_profile_page.dart';
import 'features/settings/pages/impressum_page.dart';
// Inventory pages
import 'features/inventory/pages/product_list_page.dart';
import 'features/search/pages/global_search_page.dart';
// Gallery pages
import 'features/gallery/pages/gallery_page.dart';
import 'features/gallery/pages/gallery_detail_page.dart';
import 'features/gallery/pages/gallery_upload_page.dart';
import 'features/gallery/pages/gallery_profile_page.dart';
// Import pages for salon profile editor and service catalogue editor.  These
// pages allow salon owners to manage their branding and offerings.  They
// are conditionally shown to authorised users (e.g. salon owners) via
// navigation.
import 'features/salon/pages/salon_profile_page.dart';
import 'features/salon/pages/services_editor_page.dart';
// Import reports page for analytics.  This dashboard displays
// revenue, utilisation, top services and other KPIs.
import 'features/reports/pages/reports_page.dart';
// Import the inbox page for the messaging centre. This page displays
// system, customer and team messages in separate tabs and allows
// sending team messages.
import 'features/inbox/pages/inbox_page.dart';
// Import day calendar page for daily schedule. This page displays a timeline
// with columns per stylist and supports drag‑and‑drop to move bookings,
// matching Screen 36 of the calendar module【73678961014422†L1528-L1532】.
import 'features/calendar/pages/day_calendar_page.dart';
import 'features/calendar/pages/week_calendar_page.dart';
import 'features/calendar/pages/month_calendar_page.dart';
// Import the schedule board page. This page shows a drag‑and‑drop
// shift plan with rows per stylist and columns per day. Managers can
// add, move, duplicate or delete shifts on this board.
import 'features/schedule/pages/board_page.dart';
// Import the shift swap page. This screen allows stylists to
// request shift swaps with colleagues and managers to review
// requests.
import 'features/schedule/pages/swap_page.dart';
// Import the leave management page. This page provides a calendar view
// for selecting vacation days and lists all leave requests with
// approval controls.
import 'features/schedule/pages/leave_page.dart';
// Import the timesheet page. This page provides start/stop tracking
// buttons and lists recorded time blocks grouped by day.
import 'features/schedule/pages/timesheet_page.dart';
import 'features/booking/pages/booking_professional_detail_page.dart';
import 'features/settings/pages/notification_settings_page.dart';
// Import the user preferences page for editing onboarding details in the profile.
import 'features/settings/pages/user_preferences_page.dart';
import 'features/settings/pages/profile_settings_page.dart';
import 'features/settings/pages/appearance_settings_page.dart';
import 'features/settings/pages/language_settings_page.dart';
import 'features/settings/pages/privacy_settings_page.dart';
import 'features/pos/pages/pos_page.dart';

// Import theme
import 'core/theme.dart';

// Import connectivity provider and system pages for offline, maintenance
// and error handling.  These provide overlays and fallback screens
// when the device is offline, the backend is under maintenance, a route
// is forbidden or not found.
import 'core/connectivity_provider.dart';
import 'features/system/pages/offline_page.dart';
import 'features/system/pages/maintenance_page.dart';
import 'features/system/pages/not_found_page.dart';
import 'features/system/pages/forbidden_page.dart';

/// The root widget of the application. This sets up a basic
/// [MaterialApp] with placeholder theming and a placeholder home
/// widget.  Detailed routing, theming and state management will be
/// added as the project progresses.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to connectivity changes and overlay an offline page when
    // the device is offline.  The MaterialApp is wrapped in a Stack
    // so the OfflinePage can sit on top of the entire UI.
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityProvider.instance.isOffline,
      builder: (context, offline, child) {
        return Stack(
          children: [
            MaterialApp(
              title: 'SalonManager',
              // Use the predefined light and dark themes from core/theme.dart. These define
              // primary and secondary colors (black and gold) and ensure consistent
              // styling across the app.
              theme: lightTheme,
              darkTheme: darkTheme,
              // Define the initial route and route table. Use the splash
              // page as the first screen so users see the loading
              // animation before landing on the welcome page. The splash
              // page will navigate to '/' (WelcomePage) after a
              // short delay.
              initialRoute: '/splash',
              routes: {
        // Splash screen shown on app launch. It displays the app logo
        // with a loading indicator and automatically navigates to
        // the welcome page after a brief delay.
        '/splash': (context) => const SplashPage(),
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/two-factor': (context) => const TwoFactorPage(),
        '/register-customer': (context) => const RegisterCustomerPage(),
        '/register-salon': (context) => const RegisterSalonPage(),
        '/register-admin': (context) => RegisterAdminPage(),
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
        // Route for salon applications. Salon owners can submit their
        // business for approval using a form. After submission a
        // confirmation message is shown. The actual record creation
        // happens server‑side (table `salon_applications`).
        '/salons/apply': (context) => const SalonApplyPage(),
        // Inventory product list page. Shows a simple table of products with
        // search and category filters.
        '/inventory/products': (context) => const ProductListPage(),
        // Global search page showing results in tabs for salons, services and stylists.
        '/search': (context) => const GlobalSearchPage(),
        '/inbox': (context) => InboxPage(),
        '/onboarding-customer': (context) => const OnboardingCustomerPage(),
        '/onboarding-salon': (context) => const OnboardingSalonPage(),
        // Interactive map view. Users can explore salons on a map and
        // refine their search using a filter drawer. This route
        // corresponds to Screen 11/12 in the screen specification.
        '/salons/map': (context) => const SalonsMapPage(),
        // Route for full screen home map view.  When the user taps
        // the mini map on the home page this page is opened.  It
        // displays a large map with nearby salons, a search field,
        // filter controls, a map/list toggle and preview cards when
        // tapping a marker.
        '/home/map': (context) => const HomeMapPage(),
        // Displays detailed information about a single salon.  Expects
        // a Map<String, dynamic> with salon details passed via
        // Navigator.pushNamed(context, '/salon-info', arguments: {...}).
        '/salon-info': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return CustomerSalonDetailPage(salon: args);
          }
          return const Scaffold(
            body: Center(child: Text('Keine Details verfügbar.')),
          );
        },
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
        '/booking/success': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int? bookingId;
          if (args is int) {
            bookingId = args;
          }
          return BookingSuccessPage(bookingId: bookingId);
        },
        '/profile/bookings': (context) => const BookingsListPage(),
        '/bookings/detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          // If args is a map, decide whether to pass id or full booking
          if (args is Map<String, dynamic>) {
            if (args.containsKey('id')) {
              final idVal = args['id'];
              if (idVal is int) {
                return BookingDetailPage(bookingId: idVal);
              }
            }
            // treat as a full booking map
            return BookingDetailPage(booking: args);
          }
          // If args is a simple integer, treat as booking id
          if (args is int) {
            return BookingDetailPage(bookingId: args);
          }
          return const Scaffold(
            body: Center(child: Text('Keine Details verfügbar.')),
          );
        },
        // Route to update personal onboarding preferences.  This page allows
        // users to modify gender, language and hair characteristics.
        '/profile/preferences': (context) => const UserPreferencesPage(),
        // Route for stylists to view and edit booking details. This
        // professional detail page allows adjusting price/duration per
        // service, adding notes and uploading images (Screen 30).
        '/bookings/pro-detail': (context) {
          // Expect a map containing the booking id. The professional
          // detail page will load the booking data from the database.
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> && args.containsKey('id')) {
            return BookingProfessionalDetailPage(bookingId: args['id'] as int);
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
        // Route to the main profile settings page for normal users. This
        // screen displays the user's avatar, name and handle along
        // with common settings options.  It is used for customers
        // and non‑admin users; salon owners and admins will have a
        // different settings page.
        '/settings/profile': (context) => const ProfileSettingsPage(),
        // Route to the appearance settings placeholder.  Allows users
        // to modify theme preferences (dark mode, colours) in future.
        '/settings/appearance': (context) => const AppearanceSettingsPage(),
        // Route to the language settings placeholder.  Provides
        // language selection once localisation is implemented.
        '/settings/language': (context) => const LanguageSettingsPage(),
        // Route to the privacy and security settings placeholder.
        '/settings/privacy': (context) => const PrivacySettingsPage(),
        // Route to the loyalty overview page for customers. Displays
        // current points, level and rewards. Implements Screen 53
        // (Treue‑Übersicht) with static demo data for now.
        '/loyalty': (context) => const LoyaltyOverviewPage(),
        // Route to configure loyalty thresholds and rewards.  Allows
        // salon owners to manage level thresholds and reward definitions.
        '/loyalty/rules': (context) => LoyaltyRulesPage(),
        // Legal notice page. Displays company information required by law.
        '/impressum': (context) => const ImpressumPage(),
        // Route to the service setup page. This screen presents a matrix
        // view where managers can configure for each stylist which
        // services are offered, override price and duration, and activate
        // or deactivate services【73678961014422†L1515-L1519】.
        '/staff/service-setup': (context) => const ServiceSetupPage(),
        // Route to assign services to stylists. This screen displays a
        // matrix of services and stylists with checkboxes to toggle
        // assignments. Managers can set whether a stylist is allowed to
        // perform a service. Implements Screen 43 of the schedule module.
        '/staff/assign-services': (context) => const AssignServicesPage(),
        // Route to the team management page. Shows all members of the
        // salon with controls to change role, toggle activation and
        // invite new users. Implements the team administration
        // specification in Modul M.
        '/staff/team': (context) => const TeamPage(),
        // Route to the customers list. Displays a searchable list of
        // customers with filters and sorting. Implements Screen 44 of
        // the CRM module.
        '/crm/customers': (context) => const CustomerListPage(),
        // Route to the customer profile. Expects an argument 'id' specifying
        // which customer's details to show. This screen displays basic
        // information and provides tabs for history, notes and images.
        '/crm/customer': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> && args.containsKey('id')) {
            final id = args['id'];
            if (id is int) {
              return CustomerProfilePage(customerId: id);
            }
          }
          return const Scaffold(
            body: Center(child: Text('Kunde nicht gefunden.')),
          );
        },
        // Route to the calendar day view. This screen shows a horizontal
        // timeline with one column per stylist and supports drag‑&‑drop
        // rescheduling and a floating action button to create new bookings.
        '/calendar/day': (context) => const DayCalendarPage(),
        '/calendar/week': (context) => const WeekCalendarPage(),
        // Route to the monthly calendar. This screen shows a month grid
        // with mini‑dots per day to represent appointments per stylist and
        // opens a modal day view when tapped (Screen 38)【73678961014422†L1528-L1532】.
        '/calendar/month': (context) => const MonthCalendarPage(),
        // Route to the shift plan (Dienstplan). This screen presents a
        // drag‑and‑drop board with rows per stylist and columns per day
        // of the current week. Shifts appear as coloured blocks that
        // managers can reposition, duplicate or delete. Overlapping
        // shifts display a warning icon. This implements Screen 39 of
        // the schedule module.
        '/schedule/board': (context) => const ScheduleBoardPage(),
        // Route to the shift swap screen. This page displays a list of
        // the current user's shifts with a button to request a swap. A
        // dialog prompts for a target stylist and an optional message.
        // Managers see a list of pending requests and can approve or
        // decline them. Implements Screen 40 of the schedule module.
        '/schedule/swap': (context) => const ShiftSwapPage(),
        // Route to the leave management page. This screen allows stylists
        // to select vacation days, submit leave requests and view the
        // status of existing requests. Managers can approve or decline
        // requests and see conflicts with scheduled shifts. Implements
        // Screen 41 of the schedule module.
        '/schedule/leave': (context) => const LeaveManagementPage(),
        // Route to the timesheet page. Users can start and stop
        // recordings and view their daily time blocks. Managers can
        // correct entries. Implements Screen 42 of the schedule module.
        '/schedule/timesheet': (context) => const TimeSheetPage(),
        // Route used for demo login. Without a backend this simply opens the
        // Home page to allow testing of navigation and UI flows without
        // authentication.
        '/demo': (context) => const HomePage(),
        // Point‑of‑Sale (Kasse) route. This page allows selecting
        // customers, adding services/products to a cart and completing
        // transactions. Implements Screen 76 of the POS module.
        '/pos': (context) => const PosPage(),
        // Public gallery routes. The main gallery shows a grid of
        // images with filters; the detail page displays a larger view
        // and allows booking. These implement Screens 59–61 of the
        // gallery module.
        '/gallery': (context) => const GalleryPage(),
        '/gallery/detail': (context) => const GalleryDetailPage(),
        '/gallery/upload': (context) => const GalleryUploadPage(),
        '/gallery/profile': (context) => const GalleryProfilePage(),
        // Analytics dashboard. Provides an overview of revenue, utilisation,
        // top services, no‑show rates, loyalty and inventory KPIs.
        '/reports': (context) => ReportsPage(),

        // Routes for salon profile editing and service catalogue editing.
        // The SalonProfilePage allows salon owners to change branding
        // colours, upload a logo, configure opening hours and reorder
        // page sections.  The ServicesEditorPage lets owners or
        // managers add, edit and remove services from the salon's
        // catalogue.  These pages implement the "Salon‑Profil‑Editor"
        // and "Service‑Katalog" requirements from the Pflichtenheft.
        '/salon/profile': (context) => const SalonProfilePage(),
        '/salon/services': (context) => const ServicesEditorPage(),
        // System pages for maintenance, forbidden, offline and not‑found.
        '/offline': (context) => const OfflinePage(),
        '/maintenance': (context) => const MaintenancePage(),
        '/403': (context) => const ForbiddenPage(),
        '/404': (context) => const NotFoundPage(),
      },
              onUnknownRoute: (settings) =>
                  MaterialPageRoute(builder: (context) => const NotFoundPage()),
            ),
            if (offline) const OfflinePage(),
          ],
        );
      },
    );
  }
}
