import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiplat/core/model/booking.dart';
import 'package:multiplat/core/util/multiplat_shared_prefs.dart';
import 'package:multiplat/core/enum/viewstate.dart';
import 'package:multiplat/core/viewmodel/bookings_viewmodel.dart';
import 'package:multiplat/ui/view/base_view.dart';
import 'package:multiplat/locator.dart';

/// View that lists all upcoming and past appointments of the current
/// customer. It fetches bookings from the backend using
/// [BookingsViewModel] and displays them in chronological order.
class CustomerAppointmentsView extends StatelessWidget {
  const CustomerAppointmentsView({super.key});

  Future<void> _loadBookings(BookingsViewModel model) async {
    final prefs = locator<MultiplatSharedPrefs>();
    final userIdStr = await prefs.getUserId();
    if (userIdStr != null) {
      final id = int.tryParse(userIdStr) ?? 0;
      if (id > 0) {
        await model.fetchCustomerBookings(id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BookingsViewModel>(
      onModelReady: (model) => _loadBookings(model),
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Meine Termine'),
          ),
          body: _buildBody(context, model),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BookingsViewModel model) {
    if (model.state == ViewState.Busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.error != null) {
      return Center(child: Text(model.error!));
    }
    final bookings = model.bookings;
    if (bookings.isEmpty) {
      return const Center(child: Text('Keine Termine vorhanden'));
    }
    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return ListTile(
          title: Text(booking.serviceName ?? 'Service #${booking.serviceId}'),
          subtitle: Text(
            '${booking.employeeName ?? 'Stylist #${booking.employeeId}'}\n'
            '${DateFormat('dd.MM.yyyy HH:mm').format(booking.startDateTime)} – '
            '${DateFormat('HH:mm').format(booking.endDateTime)}\n'
            'Status: ${_translateStatus(booking.status)}',
          ),
        );
      },
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'Bestätigt';
      case 'cancelled_by_customer':
        return 'Vom Kunden storniert';
      case 'cancelled_by_salon':
        return 'Vom Salon storniert';
      case 'rescheduled':
        return 'Verschoben';
      default:
        return status;
    }
  }
}