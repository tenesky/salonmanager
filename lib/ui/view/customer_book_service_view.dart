import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiplat/core/model/service.dart';
import 'package:multiplat/core/model/employee.dart';
import 'package:multiplat/core/service/service_service.dart';
import 'package:multiplat/core/service/employee_service.dart';
import 'package:multiplat/core/service/booking_service.dart';
import 'package:multiplat/core/util/multiplat_shared_prefs.dart';
import 'package:multiplat/locator.dart';

/// View where a customer can select a service, stylist, date and time
/// to book a new appointment. This widget fetches available
/// services and employees from the backend, then loads free slots for
/// the chosen day and service. On booking, the customer is
/// redirected to the list of their appointments.
class CustomerBookServiceView extends StatefulWidget {
  const CustomerBookServiceView({super.key});

  @override
  State<CustomerBookServiceView> createState() => _CustomerBookServiceViewState();
}

class _CustomerBookServiceViewState extends State<CustomerBookServiceView> {
  final ServiceService _serviceService = locator<ServiceService>();
  final EmployeeService _employeeService = locator<EmployeeService>();
  final BookingService _bookingService = locator<BookingService>();
  final MultiplatSharedPrefs _prefs = locator<MultiplatSharedPrefs>();

  List<Service> _services = [];
  List<Employee> _employees = [];
  Service? _selectedService;
  Employee? _selectedEmployee;
  DateTime? _selectedDate;
  List<String> _availableSlots = [];
  bool _loadingServices = true;
  bool _loadingSlots = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServicesAndEmployees();
  }

  Future<void> _loadServicesAndEmployees() async {
    try {
      final services = await _serviceService.fetchServices();
      final employees = await _employeeService.fetchEmployees();
      setState(() {
        _services = services;
        _employees = employees;
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
        _error = 'Fehler beim Laden der Services und Mitarbeiter';
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedService == null || _selectedEmployee == null || _selectedDate == null) {
      return;
    }
    setState(() {
      _loadingSlots = true;
      _error = null;
      _availableSlots = [];
    });
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    try {
      final slots = await _bookingService.getAvailableSlots(
          _selectedService!.id, _selectedEmployee!.id, dateStr);
      setState(() {
        _availableSlots = slots;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der freien Zeiten';
        _availableSlots = [];
      });
    } finally {
      setState(() {
        _loadingSlots = false;
      });
    }
  }

  Future<void> _bookSlot(String slot) async {
    final userIdStr = await _prefs.getUserId();
    if (userIdStr == null) {
      setState(() {
        _error = 'Benutzer-ID nicht gefunden. Bitte erneut einloggen.';
      });
      return;
    }
    final customerId = int.tryParse(userIdStr) ?? 0;
    if (customerId == 0) {
      setState(() {
        _error = 'Ungültige Benutzer-ID.';
      });
      return;
    }
    if (_selectedService == null || _selectedEmployee == null || _selectedDate == null) {
      return;
    }
    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(slot.split(':')[0]),
      int.parse(slot.split(':')[1]),
    );
    final duration = _selectedService!.durationMinutes;
    final buffer = _selectedService!.bufferMinutes;
    final end = start.add(Duration(minutes: duration + buffer));

    final success = await _bookingService.createBooking(
      customerId: customerId,
      employeeId: _selectedEmployee!.id,
      serviceId: _selectedService!.id,
      startDateTime: start,
      endDateTime: end,
    );
    if (success) {
      if (!mounted) return;
      // Navigate to the appointments overview and show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termin wurde erfolgreich gebucht.')),
      );
      Navigator.pushReplacementNamed(context, 'customer_appointments');
    } else {
      setState(() {
        _error = 'Buchung fehlgeschlagen. Vielleicht ist der Termin nicht mehr verfügbar.';
      });
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadAvailableSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termin buchen'),
      ),
      body: _loadingServices
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  // Service selection
                  DropdownButton<Service>(
                    isExpanded: true,
                    hint: const Text('Service wählen'),
                    value: _selectedService,
                    items: _services
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('${s.name} (${s.durationMinutes} Min.)'),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedService = value;
                      });
                      await _loadAvailableSlots();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Employee selection
                  DropdownButton<Employee>(
                    isExpanded: true,
                    hint: const Text('Stylist wählen'),
                    value: _selectedEmployee,
                    items: _employees
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedEmployee = value;
                      });
                      await _loadAvailableSlots();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Date selection
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? 'Datum: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}'
                              : 'Datum wählen',
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Datum wählen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Time slots
                  if (_loadingSlots) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_selectedDate == null || _selectedService == null || _selectedEmployee == null) ...[
                    const Text('Bitte wählen Sie Service, Stylist und Datum aus.'),
                  ] else if (_availableSlots.isEmpty) ...[
                    const Text('Keine freien Zeiten verfügbar. Bitte wählen Sie ein anderes Datum oder einen anderen Stylist.'),
                  ] else ...[
                    const Text('Freie Zeiten:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableSlots
                          .map((slot) => ElevatedButton(
                                onPressed: () => _bookSlot(slot),
                                child: Text(slot),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}