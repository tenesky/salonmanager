import 'package:supabase_flutter/supabase_flutter.dart';
// The PostgREST classes are used for compatibility extensions below.
import 'package:postgrest/postgrest.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// A lightweight data service that wraps Supabase operations.  This
/// service exposes high‑level methods used throughout the app to
/// interact with the Supabase PostgREST API.  It replaces the
/// previous `mysql1` implementation.  All queries are executed
/// against the Supabase client configured at app startup.
class DbService {
  /// Returns the global Supabase client instance.  The client is
  /// initialised in `main.dart` via [Supabase.initialize].
  static final SupabaseClient _client = Supabase.instance.client;

  /// Retrieves all stylists from the database.  Stylists are ordered
  /// by their `id`.  Each returned map contains the fields
  /// `id`, `name` and `color`.
  static Future<List<Map<String, dynamic>>> getStylists() async {
    final response = await _client
        .from('stylists')
        .select('id, name, color')
        .order('id')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Retrieves customers with optional filters and sorting.  If
  /// [regular] is true, only customers marked as regular are
  /// returned.  If [noShow] is true, only customers with at least
  /// one no‑show are returned.  The [searchQuery] performs a
  /// case‑insensitive search on the `name` field.  Results can be
  /// sorted by any column using [sortBy] and [ascending].
  static Future<List<Map<String, dynamic>>> getCustomers({
    bool? regular,
    bool? noShow,
    String? searchQuery,
    String sortBy = 'name',
    bool ascending = true,
  }) async {
    dynamic query = _client.from('customers').select(
        'id, name, last_visit_date, no_show_count, is_regular');
    if (regular == true) {
      query = query.eq('is_regular', true);
    }
    if (noShow == true) {
      query = query.gt('no_show_count', 0);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitized = searchQuery.trim();
      query = query.ilike('name', '%$sanitized%');
    }
    query = query.order(sortBy, ascending: ascending);
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Fetches a single customer by [id].  Returns `null` if no
  /// matching record is found.
  static Future<Map<String, dynamic>?> getCustomerById(int id) async {
    // Fetch the customer record.  Include marketing_opt_in so that
    // the contact/opt-in tab can display the current opt-in status.
    final response = await _client
        .from('customers')
        .select(
            'id, name, email, phone, photo_url, last_visit_date, is_regular, no_show_count, marketing_opt_in')
        .eq('id', id)
        .single()
        .execute();
    if (response.error != null) {
      // A 404/406 status indicates no row was found; return null in that case
      if (response.status == 404 || response.status == 406) {
        return null;
      }
      throw response.error!;
    }
    final data = response.data;
    if (data == null) {
      return null;
    }
    return Map<String, dynamic>.from(data);
  }

  /// Retrieves all bookings for a customer.  Each returned map
  /// contains booking data along with nested service and stylist
  /// objects (id and name).  Results are ordered with the most
  /// recent booking first.
  static Future<List<Map<String, dynamic>>> getCustomerBookings(
      int customerId) async {
    final response = await _client
        .from('bookings')
        .select(
            'id, start_datetime, duration, price, notes, status, services(id, name), stylists(id, name)')
        .eq('customer_id', customerId)
        .order('start_datetime', ascending: false)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Retrieves notes associated with a customer.  Notes are returned in
  /// descending order by creation time.  Each map contains `id`,
  /// `content`, `author` and `created_at`.
  static Future<List<Map<String, dynamic>>> getCustomerNotes(
      int customerId) async {
    final response = await _client
        .from('notes')
        .select('id, content, author, created_at')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Inserts a new note for a customer and returns the newly created
  /// note id.  The [author] should typically be the current user's
  /// email or name.
  static Future<int> addCustomerNote({
    required int customerId,
    required String author,
    required String content,
  }) async {
    final response = await _client
        .from('notes')
        .insert({
          'customer_id': customerId,
          'author': author,
          'content': content,
        })
        .select('id')
        .single()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data ?? {});
    return data['id'] as int;
  }

  /// Updates an existing note.  Only the `content` field can be
  /// modified via this method.
  static Future<void> updateCustomerNote({
    required int id,
    required String content,
  }) async {
    final response = await _client
        .from('notes')
        .update({'content': content})
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Deletes a note given its [id].
  static Future<void> deleteCustomerNote(int id) async {
    final response = await _client
        .from('notes')
        .delete()
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Updates contact details for a customer.  Any of the fields
  /// [email], [phone] or [marketingOptIn] may be provided.  Fields
  /// that are null are not modified.  Throws an error if the update
  /// fails.
  static Future<void> updateCustomerContact({
    required int id,
    String? email,
    String? phone,
    bool? marketingOptIn,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (email != null) {
      updateData['email'] = email;
    }
    if (phone != null) {
      updateData['phone'] = phone;
    }
    if (marketingOptIn != null) {
      updateData['marketing_opt_in'] = marketingOptIn;
    }
    if (updateData.isEmpty) {
      return;
    }
    final response = await _client
        .from('customers')
        .update(updateData)
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Creates a transaction record along with optional transaction items.
  /// Returns the newly created transaction id. The [paymentMethod] must
  /// be one of 'cash', 'card' or 'wallet'. The [items] list may
  /// contain maps with keys `product_id`, `service_id`, `name`,
  /// `quantity`, `unit_price` and `total_price`. Items are inserted
  /// into the `transaction_items` table after the transaction is
  /// created. If insertion fails, the error is propagated.
  static Future<int> createTransaction({
    required String paymentMethod,
    required num totalAmount,
    int? customerId,
    String? salonId,
    required List<Map<String, dynamic>> items,
  }) async {
    // Insert the transaction and get its id
    final txResponse = await _client
        .from('transactions')
        .insert({
          if (salonId != null) 'salon_id': salonId,
          if (customerId != null) 'customer_id': customerId,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
        })
        .select('id')
        .single()
        .execute();
    if (txResponse.error != null) {
      throw txResponse.error!;
    }
    final txData = txResponse.data as Map<String, dynamic>?;
    if (txData == null || !txData.containsKey('id')) {
      throw Exception('Transaction ID missing');
    }
    final int transactionId = txData['id'] as int;
    // Insert transaction items if any
    for (final item in items) {
      final Map<String, dynamic> itemRow = {
        'transaction_id': transactionId,
        'name': item['name'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total_price': item['total_price'],
        'product_id': item['product_id'],
        'service_id': item['service_id'],
      };
      final itemResponse = await _client
          .from('transaction_items')
          .insert(itemRow)
          .execute();
      if (itemResponse.error != null) {
        throw itemResponse.error!;
      }
    }
    return transactionId;
  }

  /// Returns the list of services available in the salon.  Fields
  /// include `id`, `name`, `duration`, `price` and `description`.
  static Future<List<Map<String, dynamic>>> getServices() async {
    final response = await _client
        .from('services')
        .select()
        .order('id')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Retrieves products from the database with optional search and category
  /// filtering. Returns a list of maps with keys `id`, `name`, `sku`,
  /// `category`, `price` and `quantity`. Results are ordered by
  /// [sortBy] (default `name`).
  static Future<List<Map<String, dynamic>>> getProducts({
    String? searchQuery,
    String? categoryFilter,
    String sortBy = 'name',
    bool ascending = true,
  }) async {
    dynamic query = _client.from('products').select('id, name, sku, category, price, quantity');
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitized = searchQuery.trim();
      query = query.ilike('name', '%$sanitized%');
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.eq('category', categoryFilter);
    }
    query = query.order(sortBy, ascending: ascending);
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Returns a set of dates for which there is at least one shift for the
  /// given stylist (or any stylist if [stylistId] is null) between
  /// [from] and [to] inclusive.  The dates are returned as UTC DateTime
  /// objects with the time components set to midnight.  This helper
  /// simplifies availability calculations for the booking wizard when
  /// determining which days should be enabled in the date picker.
  static Future<Set<DateTime>> getAvailableDates({
    required DateTime from,
    required DateTime to,
    int? stylistId,
  }) async {
    // Construct a query on the `shifts` table.  We select only the
    // `date` column to minimise data transfer.  Dates are returned as
    // strings in ISO format which we parse into DateTime objects.
    var query = _client
        .from('shifts')
        .select('date')
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String());
    if (stylistId != null) {
      query = query.eq('stylist_id', stylistId);
    }
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final Set<DateTime> dates = {};
    for (final item in data) {
      // Supabase returns date strings in the form YYYY-MM-DD.  We parse
      // them to DateTime and normalise to local timezone for
      // convenience.
      final dateStr = item['date'] as String?;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        // Strip any time component (should be 00:00 anyway) and set to
        // local time for consistent comparisons on the client.
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }
    return dates;
  }

  /// Retrieves all shifts for a given [date].  If [stylistId] is
  /// provided, only shifts for that stylist are returned.  Each
  /// returned map contains the start and end times (as DateTime
  /// objects) and the stylist id.  Times are calculated by adding
  /// the duration (in minutes) to the start time.  This helper is
  /// used when determining time slot availability for the selected
  /// date.
  static Future<List<Map<String, dynamic>>> getShiftsForDate(
      DateTime date, {
      int? stylistId,
    }) async {
    // Supabase stores the date column as DATE and start_time as TIME.
    // We query for the specific date and parse the times into DateTime
    // objects with the provided date components.
    var query = _client
        .from('shifts')
        .select('start_time, duration, stylist_id')
        .eq('date', DateFormat('yyyy-MM-dd').format(date));
    if (stylistId != null) {
      query = query.eq('stylist_id', stylistId);
    }
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> shifts = [];
    for (final item in data) {
      final startTimeStr = item['start_time'] as String?;
      final duration = (item['duration'] as int?) ?? 0;
      final sid = item['stylist_id'] as int?;
      if (startTimeStr != null) {
        // Parse HH:MM:SS string into components
        final timeParts = startTimeStr.split(":");
        if (timeParts.length >= 2) {
          final startHour = int.parse(timeParts[0]);
          final startMinute = int.parse(timeParts[1]);
          final start = DateTime(date.year, date.month, date.day, startHour, startMinute);
          final end = start.add(Duration(minutes: duration));
          shifts.add({
            'start': start,
            'end': end,
            'stylist_id': sid,
          });
        }
      }
    }
    return shifts;
  }

  /// Retrieves all bookings for a given [date].  If [stylistId] is
  /// provided, bookings are filtered by that stylist.  Only bookings
  /// whose status is not 'cancelled' or 'declined' (if such statuses
  /// exist) are returned.  Each map contains the start and end
  /// DateTime and the stylist id.  The end time is derived by
  /// adding the duration to the start_datetime.
  static Future<List<Map<String, dynamic>>> getBookingsForDate(
      DateTime date, {
      int? stylistId,
    }) async {
    // Determine the start and end of the day in UTC to query bookings
    // between 00:00 and 23:59 on the selected date.
    final dayStart = DateTime(date.year, date.month, date.day);
    final nextDay = dayStart.add(const Duration(days: 1));
    var query = _client
        .from('bookings')
        .select('start_datetime, duration, stylist_id, status')
        .gte('start_datetime', dayStart.toIso8601String())
        .lt('start_datetime', nextDay.toIso8601String());
    if (stylistId != null) {
      query = query.eq('stylist_id', stylistId);
    }
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> bookings = [];
    for (final item in data) {
      final status = (item['status'] as String?) ?? '';
      // Skip bookings that are cancelled or declined
      if (status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'declined') {
        continue;
      }
      final startStr = item['start_datetime'] as String?;
      final dur = (item['duration'] as int?) ?? 0;
      final sid = item['stylist_id'] as int?;
      if (startStr != null) {
        final start = DateTime.parse(startStr);
        final end = start.add(Duration(minutes: dur));
        bookings.add({
          'start': start,
          'end': end,
          'stylist_id': sid,
        });
      }
    }
    return bookings;
  }

  /// Retrieves all entries from the `employee_service` table.  Each
  /// returned map contains `id`, `stylist_id`, `service_id`,
  /// `active`, `price_override` and `duration_override`.
  static Future<List<Map<String, dynamic>>> getEmployeeServices() async {
    final response = await _client
        .from('employee_service')
        .select(
            'id, stylist_id, service_id, active, price_override, duration_override')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Inserts or updates an employee's service mapping.  Records are
  /// matched by the composite key `(stylist_id, service_id)`.  If a
  /// matching row exists, it will be updated; otherwise, a new row
  /// will be inserted.  This method is used in the service assignment
  /// page.
  static Future<void> upsertEmployeeService({
    required int stylistId,
    required int serviceId,
    required bool active,
    num? priceOverride,
    int? durationOverride,
  }) async {
    final response = await _client
        .from('employee_service')
        .upsert(
          {
            'stylist_id': stylistId,
            'service_id': serviceId,
            'active': active,
            'price_override': priceOverride,
            'duration_override': durationOverride,
          },
          onConflict: 'stylist_id,service_id',
        )
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Retrieves time entries for a given stylist.  Results are ordered
  /// by `start_time` descending.  Each map contains `id`,
  /// `start_time`, `end_time` and `created_at`.
  static Future<List<Map<String, dynamic>>> getTimeEntries(int stylistId) async {
    final response = await _client
        .from('time_entries')
        .select('id, start_time, end_time, created_at')
        .eq('stylist_id', stylistId)
        .order('start_time', ascending: false)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Adds a new time entry for a stylist and returns the new id.
  static Future<int> addTimeEntry({
    required int stylistId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    final response = await _client
        .from('time_entries')
        .insert({
          'stylist_id': stylistId,
          'start_time': startTime.toIso8601String(),
          if (endTime != null) 'end_time': endTime.toIso8601String(),
        })
        .select('id')
        .single()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data ?? {});
    return data['id'] as int;
  }

  /// Updates an existing time entry.  If [startTime] or [endTime] is
  /// null, that field will not be updated.
  static Future<void> updateTimeEntry({
    required int id,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final Map<String, dynamic> update = {};
    if (startTime != null) {
      update['start_time'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      update['end_time'] = endTime.toIso8601String();
    }
    if (update.isEmpty) {
      return;
    }
    final response = await _client
        .from('time_entries')
        .update(update)
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Deletes a time entry by id.
  static Future<void> deleteTimeEntry(int id) async {
    final response = await _client
        .from('time_entries')
        .delete()
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  // ---------------------------------------------------------------------------
  // Salon management
  // ---------------------------------------------------------------------------

  /// Retrieves a list of salons from the database.  Each salon map
  /// contains `id`, `name`, `rating`, `price_level`, `next_slot`,
  /// `has_free`, `latitude` and `longitude`.  Optional [searchQuery]
  /// performs a case‑insensitive search on the salon name.  Filters
  /// can be applied by specifying a set of price levels in
  /// [selectedPrices], a minimum rating in [minRating], and whether
  /// only salons with free slots should be returned via [onlyFree].
  static Future<List<Map<String, dynamic>>> getSalons({
    String? searchQuery,
    Set<String>? selectedPrices,
    double? minRating,
    bool onlyFree = false,
  }) async {
    dynamic query = _client.from('salons').select(
        'id, name, rating, price_level, next_slot, has_free, latitude, longitude');
    // Apply filters
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitized = searchQuery.trim();
      query = query.ilike('name', '%$sanitized%');
    }
    if (selectedPrices != null && selectedPrices.isNotEmpty) {
      query = query.in_('price_level', selectedPrices.toList());
    }
    if (minRating != null) {
      query = query.gte('rating', minRating);
    }
    if (onlyFree) {
      query = query.eq('has_free', true);
    }
    // Sort by rating descending and then name
    query = query.order('rating', ascending: false).order('name');
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Booking management (incoming, cancel, today/upcoming)
  // ---------------------------------------------------------------------------

  /// Retrieves all bookings with status `pending`.  Each booking
  /// returned contains the booking id, the combined customer name,
  /// the service name and the start datetime as a DateTime.
  static Future<List<Map<String, dynamic>>> getPendingBookings() async {
    final response = await _client
        .from('bookings')
        .select(
            'id, start_datetime, status, customers(name), services(name)')
        .eq('status', 'pending')
        .order('start_datetime')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> bookings = [];
    for (final row in data) {
      final map = Map<String, dynamic>.from(row);
      final customer = map['customers'] as Map<String, dynamic>?;
      final service = map['services'] as Map<String, dynamic>?;
      final dynamic dtVal = map['start_datetime'];
      DateTime dt;
      if (dtVal is String) {
        dt = DateTime.parse(dtVal).toLocal();
      } else if (dtVal is DateTime) {
        dt = dtVal.toLocal();
      } else {
        dt = DateTime.now();
      }
      bookings.add({
        'id': map['id'],
        'customer': customer != null ? customer['name'] : null,
        'service': service != null ? service['name'] : null,
        'datetime': dt,
      });
    }
    return bookings;
  }

  /// Updates the status of a booking to 'confirmed'.  Throws an
  /// exception on error.
  static Future<void> confirmBooking(int bookingId) async {
    final response = await _client
        .from('bookings')
        .update({'status': 'confirmed'})
        .eq('id', bookingId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Inserts a list of reschedule suggestions for a given booking.
  /// Each suggestion datetime is converted to UTC before insertion.
  static Future<void> addRescheduleSuggestions(
      int bookingId, List<DateTime> suggestions) async {
    if (suggestions.isEmpty) return;
    final List<Map<String, dynamic>> rows = suggestions
        .map((dt) => {
              'booking_id': bookingId,
              'suggestion_datetime': dt.toUtc().toIso8601String(),
            })
        .toList();
    final response = await _client
        .from('reschedule_suggestions')
        .insert(rows)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Retrieves a list of appointments that can be cancelled.
  /// Returns bookings with status 'pending' or 'confirmed' whose start
  /// datetime is on or after the current time.  Each entry contains
  /// id, datetime, customer, service, stylist and status.
  static Future<List<Map<String, dynamic>>> getCancellableAppointments() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('bookings')
        .select(
            'id, start_datetime, status, customers(name), services(name), stylists(name)')
        .in_('status', ['pending', 'confirmed'])
        .gte('start_datetime', nowIso)
        .order('start_datetime')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> appts = [];
    for (final row in data) {
      final map = Map<String, dynamic>.from(row);
      final customer = map['customers'] as Map<String, dynamic>?;
      final service = map['services'] as Map<String, dynamic>?;
      final stylist = map['stylists'] as Map<String, dynamic>?;
      final dynamic dtVal = map['start_datetime'];
      DateTime dt;
      if (dtVal is String) {
        dt = DateTime.parse(dtVal).toLocal();
      } else if (dtVal is DateTime) {
        dt = dtVal.toLocal();
      } else {
        dt = DateTime.now();
      }
      appts.add({
        'id': map['id'],
        'datetime': dt,
        'customer': customer != null ? customer['name'] : null,
        'service': service != null ? service['name'] : null,
        'stylist': stylist != null ? stylist['name'] : null,
        'status': map['status'],
      });
    }
    return appts;
  }

  // -------------------------------------------------------------------------
  // Booking creation and lookup helpers
  // -------------------------------------------------------------------------

  /// Retrieves a single customer by email.  Returns `null` if no
  /// matching record is found.  This helper is used when creating
  /// bookings from the wizard where only the authenticated user's
  /// email is known.  The returned map includes the same fields as
  /// [getCustomerById].
  static Future<Map<String, dynamic>?> getCustomerByEmail(String email) async {
    final response = await _client
        .from('customers')
        .select(
            'id, name, email, phone, photo_url, last_visit_date, is_regular, no_show_count')
        .eq('email', email)
        .single()
        .execute();
    if (response.error != null) {
      // A 404/406 status indicates no row was found; return null in that case
      if (response.status == 404 || response.status == 406) {
        return null;
      }
      throw response.error!;
    }
    final data = response.data;
    if (data == null) {
      return null;
    }
    return Map<String, dynamic>.from(data);
  }

  /// Retrieves a salon by id.  Returns null if no matching record is
  /// found.  This helper is used in the booking summary to look up
  /// the salon name for display.
  static Future<Map<String, dynamic>?> getSalonById(int id) async {
    final response = await _client
        .from('salons')
        .select(
            'id, name, rating, price_level, next_slot, has_free, latitude, longitude')
        .eq('id', id)
        .single()
        .execute();
    if (response.error != null) {
      if (response.status == 404 || response.status == 406) {
        return null;
      }
      throw response.error!;
    }
    final data = response.data;
    if (data == null) {
      return null;
    }
    return Map<String, dynamic>.from(data);
  }

  /// Creates a booking in the database and returns the generated
  /// booking id.  The booking must include a [startDateTime], a
  /// [duration] in minutes and a [price].  The [serviceId] refers to
  /// the primary service chosen in the wizard; if multiple services
  /// were selected, use the first one.  The [stylistId] is nullable
  /// when the user chose the "Beliebig" option.  The [customerId]
  /// can also be null when no customer record exists yet (e.g. guest
  /// users).  The [status] defaults to 'pending'.
  static Future<int> createBooking({
    int? customerId,
    int? stylistId,
    required int serviceId,
    required DateTime startDateTime,
    required int duration,
    required num price,
    String? notes,
    String status = 'pending',
  }) async {
    final Map<String, dynamic> row = {
      'start_datetime': startDateTime.toUtc().toIso8601String(),
      'duration': duration,
      'price': price,
      'status': status,
    };
    // Include optional fields only when provided
    if (customerId != null) row['customer_id'] = customerId;
    if (stylistId != null) row['stylist_id'] = stylistId;
    row['service_id'] = serviceId;
    if (notes != null && notes.isNotEmpty) row['notes'] = notes;
    final response = await _client
        .from('bookings')
        .insert(row)
        .select('id')
        .single()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data ?? {});
    return data['id'] as int;
  }

  /// Inserts a new customer into the `customers` table and returns
  /// the generated id.  Only the `first_name` and `last_name` fields
  /// are required; other fields such as email or phone may be added
  /// later via separate update methods.  When an error occurs, a
  /// [PostgrestException] is thrown.
  static Future<int> createCustomer({
    required String firstName,
    required String lastName,
  }) async {
    final response = await _client
        .from('customers')
        .insert({
          'first_name': firstName,
          'last_name': lastName,
        })
        .select('id')
        .single()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data ?? {});
    return data['id'] as int;
  }

  /// Retrieves all bookings on a given [date] with joined customer
  /// and service names.  Only bookings whose status is either
  /// `pending` or `confirmed` are returned.  Each map in the
  /// returned list contains the following keys:
  ///
  /// * `id` – the booking id
  /// * `firstName` – the customer's first name
  /// * `lastName` – the customer's last name
  /// * `serviceName` – the service name
  /// * `stylist_id` – the stylist id
  /// * `start_datetime` – a UTC ISO8601 string for the start time
  /// * `duration` – the booking duration in minutes
  ///
  /// This helper is used by the day calendar to populate the
  /// timeline.  Join syntax in the select clause automatically
  /// retrieves fields from the related `customers` and `services`
  /// tables based on foreign keys.  If no bookings are found, an
  /// empty list is returned.
  static Future<List<Map<String, dynamic>>> getDetailedBookingsForDate(
      DateTime date) async {
    // Determine the UTC start of the selected day and the next day
    final dayStartUtc = DateTime(date.year, date.month, date.day).toUtc();
    final nextDayUtc = dayStartUtc.add(const Duration(days: 1));
    final response = await _client
        .from('bookings')
        .select(
            'id, duration, start_datetime, stylist_id, status, customers(first_name,last_name), services(name)')
        .gte('start_datetime', dayStartUtc.toIso8601String())
        .lt('start_datetime', nextDayUtc.toIso8601String())
        .in_('status', ['pending', 'confirmed'])
        .order('start_datetime')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> bookings = [];
    for (final row in data) {
      final map = Map<String, dynamic>.from(row);
      final customer = map['customers'] as Map<String, dynamic>?;
      final service = map['services'] as Map<String, dynamic>?;
      bookings.add({
        'id': map['id'],
        'firstName': customer != null ? customer['first_name'] : null,
        'lastName': customer != null ? customer['last_name'] : null,
        'serviceName': service != null ? service['name'] : null,
        'stylist_id': map['stylist_id'],
        'start_datetime': map['start_datetime'],
        'duration': map['duration'],
      });
    }
    return bookings;
  }

  /// Updates the stylist id and start datetime of an existing booking.
  /// The [bookingId] identifies the booking to update.  The
  /// [startDateTime] must be provided in the local timezone and is
  /// converted to UTC before saving.  Throws a [PostgrestException]
  /// when the update fails.
  static Future<void> updateBookingStartAndStylist({
    required int bookingId,
    required int stylistId,
    required DateTime startDateTime,
  }) async {
    final response = await _client
        .from('bookings')
        .update({
          'stylist_id': stylistId,
          'start_datetime': startDateTime.toUtc().toIso8601String(),
        })
        .eq('id', bookingId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Retrieves bookings between [startDate] and [endDate] inclusive
  /// with joined customer and service names.  The date range is
  /// interpreted in local time; both [startDate] and [endDate] are
  /// normalised to the start of their respective days in UTC before
  /// querying.  Only bookings whose status is either `pending` or
  /// `confirmed` are returned.  See [getDetailedBookingsForDate]
  /// for the structure of each returned map.
  static Future<List<Map<String, dynamic>>> getDetailedBookingsBetween(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Normalise to start of day for startDate and endDate (inclusive)
    final DateTime startUtc = DateTime(startDate.year, startDate.month, startDate.day).toUtc();
    final DateTime endUtc = DateTime(endDate.year, endDate.month, endDate.day).toUtc().add(const Duration(days: 1));
    final response = await _client
        .from('bookings')
        .select(
            'id, duration, start_datetime, stylist_id, status, customers(first_name,last_name), services(name)')
        .gte('start_datetime', startUtc.toIso8601String())
        .lt('start_datetime', endUtc.toIso8601String())
        .in_('status', ['pending', 'confirmed'])
        .order('start_datetime')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> bookings = [];
    for (final row in data) {
      final map = Map<String, dynamic>.from(row);
      final customer = map['customers'] as Map<String, dynamic>?;
      final service = map['services'] as Map<String, dynamic>?;
      bookings.add({
        'id': map['id'],
        'firstName': customer != null ? customer['first_name'] : null,
        'lastName': customer != null ? customer['last_name'] : null,
        'serviceName': service != null ? service['name'] : null,
        'stylist_id': map['stylist_id'],
        'start_datetime': map['start_datetime'],
        'duration': map['duration'],
      });
    }
    return bookings;
  }


  /// Cancels a list of bookings.  For each booking id in [ids], the
  /// booking status is updated to 'canceled'.  A cancellation
  /// reason and optional message are inserted into the
  /// `cancellation_reasons` table.  Both lists must be the same
  /// length.  Throws an exception on error.
  static Future<void> cancelBookings({
    required List<int> ids,
    required String reason,
    required String message,
  }) async {
    // Update bookings
    final updates = await _client
        .from('bookings')
        .update({'status': 'canceled'})
        .in_('id', ids)
        .execute();
    if (updates.error != null) {
      throw updates.error!;
    }
    // Insert cancellation reasons
    final List<Map<String, dynamic>> rows = ids
        .map((id) => {
              'booking_id': id,
              'reason': reason,
              'message': message,
            })
        .toList();
    final ins = await _client
        .from('cancellation_reasons')
        .insert(rows)
        .execute();
    if (ins.error != null) {
      throw ins.error!;
    }
  }

  /// Retrieves all bookings with status 'pending' or 'confirmed'
  /// regardless of date.  Used in the "today/upcoming" page.  Each
  /// entry contains id, datetime, customer, service, stylist and status.
  static Future<List<Map<String, dynamic>>> getUpcomingOrTodayAppointments() async {
    final response = await _client
        .from('bookings')
        .select(
            'id, start_datetime, status, customers(name), services(name), stylists(name)')
        .in_('status', ['pending', 'confirmed'])
        .order('start_datetime')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> appts = [];
    for (final row in data) {
      final map = Map<String, dynamic>.from(row);
      final customer = map['customers'] as Map<String, dynamic>?;
      final service = map['services'] as Map<String, dynamic>?;
      final stylist = map['stylists'] as Map<String, dynamic>?;
      final dynamic dtVal = map['start_datetime'];
      DateTime dt;
      if (dtVal is String) {
        dt = DateTime.parse(dtVal).toLocal();
      } else if (dtVal is DateTime) {
        dt = dtVal.toLocal();
      } else {
        dt = DateTime.now();
      }
      appts.add({
        'id': map['id'],
        'datetime': dt,
        'customer': customer != null ? customer['name'] : null,
        'service': service != null ? service['name'] : null,
        'stylist': stylist != null ? stylist['name'] : null,
        'status': map['status'],
      });
    }
    return appts;
  }

  /// Retrieves full booking details for a given booking id.  The
  /// returned map contains keys: customerName, stylistName, date,
  /// time, services (list), notes and status.  Each service entry
  /// includes id, name, price and duration.  Returns `null` if no
  /// booking is found.
  static Future<Map<String, dynamic>?> getBookingDetail(int id) async {
    final response = await _client
        .from('bookings')
        .select(
            'id, start_datetime, duration, price, notes, status, customers(name), stylists(name), services(id,name)')
        .eq('id', id)
        .single()
        .execute();
    if (response.error != null) {
      if (response.status == 404 || response.status == 406) {
        return null;
      }
      throw response.error!;
    }
    final data = response.data;
    if (data == null) {
      return null;
    }
    final map = Map<String, dynamic>.from(data);
    final customer = map['customers'] as Map<String, dynamic>?;
    final stylist = map['stylists'] as Map<String, dynamic>?;
    final service = map['services'] as Map<String, dynamic>?;
    // Parse start_datetime into a local DateTime for convenience
    final dynamic dtVal = map['start_datetime'];
    DateTime dt;
    if (dtVal is String) {
      dt = DateTime.parse(dtVal).toLocal();
    } else if (dtVal is DateTime) {
      dt = dtVal.toLocal();
    } else {
      dt = DateTime.now();
    }
    // Compose a unified booking detail map.  Include raw fields
    // (start_datetime, duration, price, notes, status) as well as
    // derived fields (serviceName, customerName, stylistName, date,
    // time) and a services list for detailed info.
    return {
      // Raw booking fields
      'id': map['id'],
      'start_datetime': map['start_datetime'],
      'duration': map['duration'],
      'price': map['price'],
      'notes': map['notes'],
      'status': map['status'],
      // Joined names
      'customerName': customer != null ? customer['name'] : null,
      'stylistName': stylist != null ? stylist['name'] : null,
      'serviceName': service != null ? service['name'] : null,
      // Derived date/time strings in local timezone
      'date': '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
      'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      // List of services associated with the booking.  In this schema
      // there is at most one service per booking, but we return a
      // list for extensibility.
      'services': service != null
          ? [
              {
                'serviceId': service['id'],
                'name': service['name'],
                'price': map['price'],
                'duration': map['duration'],
              }
            ]
          : [],
    };
  }

  /// Retrieves a list of bookings for a specific customer.  The
  /// required [customerId] identifies the customer in the database.
  /// Optional filters allow narrowing by a set of [statuses], a
  /// start and end date range ([start] and [end]), and a
  /// case‑insensitive [search] string that matches the service name.
  /// Results are ordered by the booking start datetime descending.
  static Future<List<Map<String, dynamic>>> getBookingsForCustomer(
      int customerId,
      {
        List<String>? statuses,
        DateTime? start,
        DateTime? end,
        String? search,
      }) async {
    dynamic query = _client
        .from('bookings')
        .select('id, start_datetime, duration, price, status, services(name), stylists(name)')
        .eq('customer_id', customerId);
    // Apply status filter when provided
    if (statuses != null && statuses.isNotEmpty) {
      query = query.in_('status', statuses);
    }
    // Apply date range filters.  Note that start is inclusive and end
    // is exclusive (end of day +1).  Dates are converted to UTC
    // strings to match Supabase's ISO expectations.
    if (start != null) {
      final startUtc = DateTime(start.year, start.month, start.day)
          .toUtc()
          .toIso8601String();
      query = query.gte('start_datetime', startUtc);
    }
    if (end != null) {
      final nextDay = DateTime(end.year, end.month, end.day)
          .add(const Duration(days: 1));
      final endUtc = nextDay.toUtc().toIso8601String();
      query = query.lt('start_datetime', endUtc);
    }
    // Apply search filter on service name
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.ilike('services.name', '%$q%');
    }
    // Order by start_datetime descending
    query = query.order('start_datetime', ascending: false);
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> bookings = [];
    for (final row in data) {
      final map = Map<String, dynamic>.from(row);
      final dynamic dtVal = map['start_datetime'];
      DateTime dt;
      if (dtVal is String) {
        dt = DateTime.parse(dtVal).toLocal();
      } else if (dtVal is DateTime) {
        dt = dtVal.toLocal();
      } else {
        dt = DateTime.now();
      }
      final service = map['services'] as Map<String, dynamic>?;
      final stylist = map['stylists'] as Map<String, dynamic>?;
      bookings.add({
        'id': map['id'],
        'datetime': dt,
        'duration': map['duration'],
        'price': map['price'],
        'status': map['status'],
        'serviceName': service != null ? service['name'] : null,
        'stylistName': stylist != null ? stylist['name'] : null,
      });
    }
    return bookings;
  }

  /// Updates the price and duration of a booking.  Accepts new values
  /// for [price] and [duration] and writes them to the database.
  static Future<void> updateBookingPriceDuration({
    required int bookingId,
    required num price,
    required int duration,
  }) async {
    final response = await _client
        .from('bookings')
        .update({'price': price, 'duration': duration})
        .eq('id', bookingId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Updates the notes of a booking.
  static Future<void> updateBookingNotes({
    required int bookingId,
    required String notes,
  }) async {
    final response = await _client
        .from('bookings')
        .update({'notes': notes})
        .eq('id', bookingId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Deprecated: The MySQL based API previously exposed a getConnection
  /// method which returned a `MySqlConnection`.  With the switch to
  /// Supabase, raw SQL queries should be replaced with specific
  /// helper methods (e.g. [getStylists], [getCustomers], etc.).  This
  /// stub implementation remains solely to prevent runtime errors in
  /// legacy code that still calls `DbService.getConnection()`.  It
  /// returns a connection object with no-op [query] and [close]
  /// methods.  Do not rely on this for production use.
  static Future<_StubConnection> getConnection() async {
    return _StubConnection();
  }
}

/// -------------------------------------------------------------------------
/// Compatibility layer
///
/// Supabase Flutter v2 removed the `.execute()` and `.in_()` methods from
/// the PostgREST query builders and replaced them with direct `await` on
/// the builders and `inFilter()`.  To avoid a large refactor of the
/// existing codebase, we provide thin extension methods that mimic the
/// old API.  The [execute] extension wraps awaiting the builder in a
/// try/catch block and returns a lightweight response object with
/// `data`, `error` and `status` fields similar to the old
/// `PostgrestResponse`.  The [in_] extension simply forwards to
/// `inFilter()`.  If Supabase throws a [PostgrestException], its
/// `code` string is parsed into an integer status when possible.

/// A lightweight response object used by the execute() compatibility
/// extension.  It contains the result data, any PostgREST error and
/// an optional status code parsed from the error code.
class _CompatPostgrestResponse<T> {
  final T? data;
  final PostgrestException? error;
  final int? status;

  _CompatPostgrestResponse({required this.data, this.error, this.status});
}

/// Provides an `execute()` method on PostgREST transform builders to mimic
/// the removed execute() API from Supabase v1.  It awaits the query and
/// wraps the result into a [_CompatPostgrestResponse].  Errors are
/// captured and returned in the `error` field with the status parsed
/// from the exception code when possible.  Usage of this extension
/// allows the existing database service methods to continue using
/// `await query.execute()` without modification.
extension CompatExecuteExtension<T> on PostgrestTransformBuilder<T> {
  Future<_CompatPostgrestResponse<T>> execute() async {
    try {
      // In Supabase v2, PostgREST builders are `Future`s.  Awaiting them
      // directly yields the data (e.g. List<Map<String, dynamic>> or a
      // single row) without wrapping into a response object.
      final res = await this;
      return _CompatPostgrestResponse<T>(data: res);
    } on PostgrestException catch (e) {
      // Attempt to parse numeric status from the error code.  Some
      // PostgREST errors encode the HTTP status as a numeric string.
      final int? status = int.tryParse(e.code ?? '');
      return _CompatPostgrestResponse<T>(data: null, error: e, status: status);
    }
  }
}

/// Adds an `in_()` method to PostgREST filter builders which forwards
/// arguments to `inFilter()`.  This mirrors the old API to simplify
/// migration to Supabase v2.
extension CompatInExtension<T> on PostgrestFilterBuilder<T> {
  PostgrestFilterBuilder<T> in_(String column, List<dynamic> values) {
    return inFilter(column, values);
  }
}

/// A minimal stub connection used to satisfy existing calls to
/// `DbService.getConnection()`.  Its [query] method prints a warning
/// and returns an empty list.  [close] is a no-op.  Replace legacy
/// database calls with Supabase specific methods in [DbService].
class _StubConnection {
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    // This stub is intentionally simplistic.  In a real migration you
    // would refactor calls to use Supabase's query API instead of
    // executing raw SQL.
    debugPrint('DbService.getConnection() called; this method is deprecated.');
    return [];
  }

  Future<void> close() async {
    // Nothing to close in the stub.
  }
}