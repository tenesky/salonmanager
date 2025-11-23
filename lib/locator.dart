import 'package:get_it/get_it.dart';
import 'package:multiplat/core/service/data_item_service.dart';
import 'package:multiplat/core/service/pane_interaction_service.dart';
import 'package:multiplat/core/service/auth_service.dart';
import 'package:multiplat/core/service/employee_service.dart';
import 'package:multiplat/core/service/service_service.dart';
import 'package:multiplat/core/service/booking_service.dart';
import 'package:multiplat/core/util/multiplat_shared_prefs.dart';
import 'package:multiplat/core/viewmodel/chart_viewmodel.dart';
import 'package:multiplat/core/viewmodel/item_detail_viewmodel.dart';
import 'package:multiplat/core/viewmodel/items_viewmodel.dart';
import 'package:multiplat/core/viewmodel/login_viewmodel.dart';
import 'package:multiplat/core/viewmodel/register_viewmodel.dart';
import 'package:multiplat/core/viewmodel/employees_viewmodel.dart';
import 'package:multiplat/core/viewmodel/services_viewmodel.dart';
import 'package:multiplat/core/viewmodel/bookings_viewmodel.dart';

GetIt locator = GetIt.instance;

void setupLocator() {

  // Utilities
  locator.registerSingleton(MultiplatSharedPrefs());

  // Services
  locator.registerSingleton(DataItemService());
  locator.registerSingleton(PaneInteractionService());

  // Authentication service
  locator.registerSingleton(AuthService());

  // Employee service
  locator.registerSingleton(EmployeeService());

  // Service management service
  locator.registerSingleton(ServiceService());

  // Booking service
  locator.registerSingleton(BookingService());

  // View models
  locator.registerFactory(() => ItemsViewModel());
  locator.registerFactory(() => ChartViewModel());
  locator.registerFactory(() => ItemDetailViewModel());

  // Auth related view models
  locator.registerFactory(() => LoginViewModel());
  locator.registerFactory(() => RegisterViewModel());

  // Employee related view models
  locator.registerFactory(() => EmployeesViewModel());

  // Service related view models
  locator.registerFactory(() => ServicesViewModel());

  // Bookings view models
  locator.registerFactory(() => BookingsViewModel());
}
