import 'package:multiplat/core/model/booking.dart';
import 'package:multiplat/core/service/booking_service.dart';
import 'package:multiplat/core/viewmodel/base_viewmodel.dart';
import 'package:multiplat/locator.dart';

/// ViewModel that manages a list of bookings for a customer.
///
/// This view model fetches the bookings from the backend via
/// [BookingService] and exposes loading and error state. It's
/// intended for use in views like CustomerAppointmentsView. It can
/// easily be extended later to support filtering by status or date.
class BookingsViewModel extends BaseViewModel {
  final BookingService _bookingService = locator<BookingService>();

  List<Booking> _bookings = [];
  String? _error;

  List<Booking> get bookings => _bookings;
  String? get error => _error;

  /// Loads all bookings for the given customer ID. Sets the state
  /// accordingly to indicate progress. On success, the [bookings]
  /// property will contain a list of [Booking] objects. On error,
  /// [error] will be set and the [bookings] list will be empty.
  Future<void> fetchCustomerBookings(int customerId) async {
    setBusy();
    _error = null;
    try {
      final list = await _bookingService.fetchCustomerBookings(customerId);
      _bookings = list;
    } catch (e) {
      _bookings = [];
      _error = 'Konnte Termine nicht laden';
    } finally {
      setIdle();
    }
  }
}