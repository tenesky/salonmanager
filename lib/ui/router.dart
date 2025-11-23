import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multiplat/core/util/platform_util.dart';
import 'package:multiplat/ui/view/chart_view.dart';
import 'package:multiplat/ui/view/combined_view.dart';
import 'package:multiplat/ui/view/item_detail_view.dart';
import 'package:multiplat/ui/view/items_view.dart';
import 'package:multiplat/ui/view/login_selection_view.dart';
import 'package:multiplat/ui/view/login_form_view.dart';
import 'package:multiplat/ui/view/register_view.dart';
import 'package:multiplat/ui/view/customer_home_view.dart';
import 'package:multiplat/ui/view/customer_book_service_view.dart';
import 'package:multiplat/ui/view/customer_appointments_view.dart';
import 'package:multiplat/ui/view/employee_home_view.dart';
import 'package:multiplat/ui/view/employee_overview_view.dart';
import 'package:multiplat/ui/view/employee_schedule_view.dart';
import 'package:multiplat/ui/view/employee_time_tracking_view.dart';
import 'package:multiplat/ui/view/employee_leave_request_view.dart';
import 'package:multiplat/ui/view/owner_home_view.dart';
import 'package:multiplat/ui/view/owner_manage_employees_view.dart';
import 'package:multiplat/ui/view/owner_manage_services_view.dart';
import 'package:multiplat/ui/view/owner_manage_schedule_view.dart';
import 'package:multiplat/ui/view/owner_manage_bookings_view.dart';
import 'package:multiplat/ui/view/owner_manage_leave_requests_view.dart';
import 'package:multiplat/ui/view/owner_view_attendance_view.dart';
import 'package:multiplat/ui/view/owner_reports_view.dart';

// The initial route for the application. We direct users to the login flow
// where they can choose to log in as a customer or an employee and register a new account.
const String initialRoute = 'login';

class MultiPlatRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'login':
        return _platformRoute(() => const LoginSelectionView());
      case 'loginForm':
        // Expect a role argument (customer or employee). If none provided, default to customer.
        final role = settings.arguments as String? ?? 'customer';
        return _platformRoute(() => LoginFormView(role: role));
      case 'register':
        return _platformRoute(() => const RegisterView());
      case 'home':
        return _platformRoute(() => const ItemsView());
      case 'chart':
        return _platformRoute(() => const ChartView());
      case 'detail':
        return _platformRoute(() => const ItemDetailView());
      case 'combined':
        return _platformRoute(() => const CombinedView());
      case 'customer_home':
        return _platformRoute(() => const CustomerHomeView());
      case 'customer_book_service':
        return _platformRoute(() => const CustomerBookServiceView());
      case 'customer_appointments':
        return _platformRoute(() => const CustomerAppointmentsView());
      case 'employee_home':
        return _platformRoute(() => const EmployeeHomeView());
      case 'employee_overview':
        return _platformRoute(() => const EmployeeOverviewView());
      case 'employee_schedule':
        return _platformRoute(() => const EmployeeScheduleView());
      case 'employee_time_tracking':
        return _platformRoute(() => const EmployeeTimeTrackingView());
      case 'employee_leave_request':
        return _platformRoute(() => const EmployeeLeaveRequestView());
      case 'owner_home':
        return _platformRoute(() => const OwnerHomeView());
      case 'owner_manage_employees':
        return _platformRoute(() => const OwnerManageEmployeesView());
      case 'owner_manage_services':
        return _platformRoute(() => const OwnerManageServicesView());
      case 'owner_manage_schedule':
        return _platformRoute(() => const OwnerManageScheduleView());
      case 'owner_manage_bookings':
        return _platformRoute(() => const OwnerManageBookingsView());
      case 'owner_manage_leave_requests':
        return _platformRoute(() => const OwnerManageLeaveRequestsView());
      case 'owner_view_attendance':
        return _platformRoute(() => const OwnerViewAttendanceView());
      case 'owner_reports':
        return _platformRoute(() => const OwnerReportsView());
      default:
        return _platformRoute(() => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ));
    }
  }

  static Route<dynamic> _platformRoute(Function builderCallback) {
    if (isCupertino()) {
      return CupertinoPageRoute(builder: (_) => builderCallback());
    }
    return MaterialPageRoute(builder: (_) => builderCallback());
  }
}
