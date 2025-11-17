import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
// The PostgREST classes are used for compatibility extensions below.
import 'package:postgrest/postgrest.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 's3_service.dart';

/// A lightweight data service that wraps Supabase operations.  This
/// service exposes high‑level methods used throughout the app to
/// interact with the Supabase PostgREST API.  It replaces the
/// previous `mysql1` implementation.  All queries are executed
/// against the Supabase client configured at app startup.
class DbService {
  /// Returns the global Supabase client instance.  The client is
  /// initialised in `main.dart` via [Supabase.initialize].
  static final SupabaseClient _client = Supabase.instance.client;

  /// Name of the storage bucket used for gallery images.  All
  /// gallery uploads are stored in this bucket under the `private/`
  /// directory.  When retrieving images, signed URLs are
  /// generated via this bucket name.  Ensure this matches the
  /// bucket created in your Supabase storage dashboard.
  static const String _galleryBucket = 'salonmanager';

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
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
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

  /// Retrieves messages from the `messages` table.  Messages can be
  /// filtered by [type] (e.g. 'system', 'customer', 'team').  If
  /// [type] is null, all message types are returned.  The query
  /// automatically filters messages to those addressed to the current
  /// user (or broadcasts when the `user_id` column is null) and sorts
  /// them with the most recent first.  Each map contains `id`,
  /// `user_id`, `sender`, `type`, `content`, `read` and
  /// `created_at`.
  static Future<List<Map<String, dynamic>>> getMessages({String? type}) async {
    final userId = _client.auth.currentUser?.id;
    dynamic query = _client
        .from('messages')
        .select('id, user_id, sender, type, content, read, created_at');
    if (type != null) {
      query = query.eq('type', type);
    }
    // Only return messages addressed to the current user or broadcast
    if (userId != null) {
      query = query.or('user_id.eq.$userId,user_id.is.null');
    }
    query = query.order('created_at', ascending: false);
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Marks a message as read by setting the `read` flag to true.
  /// Throws an exception if the update fails.
  static Future<void> markMessageRead(int id) async {
    final response = await _client
        .from('messages')
        .update({'read': true})
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Sends a new message.  The [type] determines which tab the
  /// message appears on ('system', 'customer', 'team').  If
  /// [recipientUserId] is provided the message is addressed to a
  /// single user; otherwise it is considered a broadcast (for system
  /// or team messages).  The sender's email is taken from the
  /// current auth session.  Throws if the insert fails.
  static Future<void> sendMessage({
    required String type,
    required String content,
    String? recipientUserId,
  }) async {
    final senderEmail = _client.auth.currentUser?.email ?? 'unknown';
    final Map<String, dynamic> data = {
      'type': type,
      'content': content,
      'sender': senderEmail,
      'read': false,
    };
    if (recipientUserId != null) {
      data['user_id'] = recipientUserId;
    }
    final response = await _client.from('messages').insert(data).execute();
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

  /// Returns a list of all salon members.  Each map contains
  /// `salon_id`, `user_id`, `role` and `active` fields.  The
  /// `salon_members` table is expected to have an `active` boolean
  /// column as suggested in the team management specification.  If
  /// the query fails, an exception is thrown.  Note that this
  /// implementation does not join with the `profiles` or `users`
  /// tables to fetch names or emails; those can be retrieved
  /// separately if needed.
  static Future<List<Map<String, dynamic>>> getSalonMembers() async {
    final response = await _client
        .from('salon_members')
        .select('salon_id, user_id, role, active')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Updates the role of a salon member identified by [salonId] and
  /// [userId].  The [role] must be one of 'salon_admin', 'manager',
  /// 'stylist' or 'azubi'.  Throws an exception if the update fails.
  static Future<void> updateSalonMemberRole({
    required String salonId,
    required String userId,
    required String role,
  }) async {
    final response = await _client
        .from('salon_members')
        .update({'role': role})
        .eq('salon_id', salonId)
        .eq('user_id', userId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Updates the active status of a salon member.  If [active] is
  /// false the member will be considered deactivated and should no
  /// longer have access to the salon's resources.  Throws on error.
  static Future<void> updateSalonMemberActive({
    required String salonId,
    required String userId,
    required bool active,
  }) async {
    final response = await _client
        .from('salon_members')
        .update({'active': active})
        .eq('salon_id', salonId)
        .eq('user_id', userId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Adds a new salon member record.  This should be called after
  /// inviting a user via [AuthService.inviteUser] and obtaining their
  /// `userId`.  The record links the user to the salon with the given
  /// [role] and sets their `active` status.  Throws on error.
  static Future<void> addSalonMember({
    required String salonId,
    required String userId,
    required String role,
    bool active = true,
  }) async {
    final response = await _client
        .from('salon_members')
        .insert({
          'salon_id': salonId,
          'user_id': userId,
          'role': role,
          'active': active,
        })
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

  /// Retrieves the salon profile for the current user.  The salon is
  /// identified by the `owner_id` equal to the current user's id.  If no
  /// salon is found the method returns `null`.  The returned map
  /// contains all columns from the `salons` table.
  static Future<Map<String, dynamic>?> getSalonProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final response = await _client
        .from('salons')
        .select()
        .eq('owner_id', userId)
        .single()
        .execute();
    if (response.error != null) {
      // If no salon exists for this owner return null instead of throwing.
      if (response.status == 406 || response.status == 404) {
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

  /// Updates fields of the salon profile.  Only fields that are provided
  /// (non-null) are modified.  The [salonId] must be the id of the salon
  /// record to update.  Returns a future that completes when the
  /// update succeeds or throws on error.
  static Future<void> updateSalonProfile({
    required String salonId,
    String? name,
    String? address,
    String? phone,
    String? website,
    String? primaryColor,
    String? accentColor,
    String? blockOrder,
    String? openingHours,
    String? legalText,
    bool? useDefaultLegalText,
    String? logoUrl,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (address != null) updateData['address'] = address;
    if (phone != null) updateData['phone'] = phone;
    if (website != null) updateData['website'] = website;
    if (primaryColor != null) updateData['primary_color'] = primaryColor;
    if (accentColor != null) updateData['accent_color'] = accentColor;
    if (blockOrder != null) updateData['block_order'] = blockOrder;
    if (openingHours != null) updateData['opening_hours'] = openingHours;
    if (legalText != null) updateData['legal_text'] = legalText;
    if (useDefaultLegalText != null) {
      updateData['use_default_legal_text'] = useDefaultLegalText;
    }
    if (logoUrl != null) updateData['logo_url'] = logoUrl;
    if (updateData.isEmpty) {
      return;
    }
    final response = await _client
        .from('salons')
        .update(updateData)
        .eq('id', salonId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Uploads a salon logo to Supabase storage.  The [fileBytes]
  /// parameter should contain the binary data of the image, and
  /// [fileName] should include the extension (e.g. mylogo.png).  The
  /// file is stored in a dedicated bucket called `salon-logos`.  The
  /// returned string is the public URL to access the uploaded file.
  static Future<String> uploadSalonLogo(
      List<int> fileBytes, String fileName) async {
    const String bucket = 'salon-logos';
    final String filePath = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    // Convert the provided List<int> to Uint8List because the
    // uploadBinary method expects Uint8List.  If the upload fails an
    // exception will be thrown which can be caught by the caller.
    final bytes = Uint8List.fromList(fileBytes);
    await _client.storage.from(bucket).uploadBinary(filePath, bytes);
    // Return the public URL of the uploaded file.  Supabase will
    // automatically throw on failure.
    final String publicUrl = _client.storage.from(bucket).getPublicUrl(filePath);
    return publicUrl;
  }

  /// Uploads a gallery image using the AWS S3 protocol to the
  /// Supabase Storage bucket configured in [S3Service].  This
  /// wrapper converts the provided `List<int>` into a `Uint8List`
  /// before delegating to [S3Service.uploadGalleryImage].  The
  /// returned string is the URL which can be stored in the
  /// `gallery_images` table.  It will point to the private folder
  /// within the `salonmanager` bucket.  Note: in order for this
  /// method to succeed the `storage.objects` table must have RLS
  /// policies allowing authenticated users to insert and select
  /// private objects, as described in the Supabase documentation.
  static Future<String> uploadGalleryImage(
      List<int> fileBytes, String fileName) async {
    final bytes = Uint8List.fromList(fileBytes);
    return S3Service.uploadGalleryImage(bytes, fileName);
  }

  /// Fetches a list of gallery images from the database.  Each
  /// returned map contains the fields `id`, `user_id`, `salon_id`,
  /// `url`, `description`, `length`, `style`, `colour` and
  /// `created_at`.  Results are ordered by creation time (newest
  /// first).  Optionally pass a [searchQuery] to filter images by
  /// description (case‑insensitive).  If no query is provided all
  /// images are returned.  Throws on error.
  static Future<List<Map<String, dynamic>>> getGalleryImages({
    String? searchQuery,
  }) async {
    dynamic query = _client
        .from('gallery_images')
        .select(
            'id, user_id, salon_id, url, description, length, style, colour, created_at')
        .order('created_at', ascending: false);
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitized = searchQuery.trim();
      query = query.ilike('description', '%$sanitized%');
    }
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final List<dynamic> data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> images = [];
    // Convert each row to a map and replace the stored path with a
    // signed URL.  This ensures private images can be displayed
    // without exposing the underlying storage path.  Signed URLs
    // expire after seven days (604800 seconds).  If URL generation
    // fails, the original path remains unchanged.
    for (final item in data) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(item);
      final String? path = row['url'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          final signed = await _client.storage
              .from(_galleryBucket)
              .createSignedUrl(path, 604800);
          // The Supabase storage API returns a StorageResponse<String>
          // where the signed URL is stored in the `data` field.  Use
          // `data` instead of `url` when checking the result.
          if (signed.error == null && signed.data != null) {
            row['url'] = signed.data as String;
          }
        } catch (_) {
          // Ignore errors; leave url unchanged.
        }
      }
      images.add(row);
    }
    return images;
  }

  /// Returns the ids of images liked by the current user.  If the
  /// user is not logged in an empty list is returned.  Throws on
  /// error.
  static Future<List<String>> getLikedImageIdsForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final response = await _client
        .from('gallery_likes')
        .select('image_id')
        .eq('user_id', userId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data
        .map((e) => (e as Map<String, dynamic>)['image_id'].toString())
        .toList();
  }

  /// Likes a gallery image on behalf of the current user.  Inserts a
  /// row into the `gallery_likes` table.  If the user is not
  /// logged in this method does nothing.  Throws on error.
  static Future<void> likeGalleryImage(String imageId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final response = await _client
        .from('gallery_likes')
        .insert({'user_id': userId, 'image_id': imageId})
        .execute();
    if (response.error != null && response.status != 409) {
      // ignore conflict errors silently (already liked)
      throw response.error!;
    }
  }

  /// Unlikes a gallery image for the current user.  Deletes the
  /// corresponding row from `gallery_likes`.  If the user is not
  /// logged in nothing is deleted.  Throws on error.
  static Future<void> unlikeGalleryImage(String imageId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final response = await _client
        .from('gallery_likes')
        .delete()
        .eq('user_id', userId)
        .eq('image_id', imageId)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Creates a new gallery image record in the database.  The
  /// [url] must point to an existing object in Supabase Storage.  A
  /// description is required; optional fields [length], [style] and
  /// [colour] can be provided to support filtering.  Throws on
  /// error.
  static Future<void> createGalleryImage({
    required String url,
    required String description,
    String? length,
    String? style,
    String? colour,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final Map<String, dynamic> values = {
      'url': url,
      'description': description,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (userId != null) values['user_id'] = userId;
    if (length != null) values['length'] = length;
    if (style != null) values['style'] = style;
    if (colour != null) values['colour'] = colour;
    final response = await _client.from('gallery_images').insert(values).execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Updates the description and optional metadata of an existing
  /// gallery image.  Only the provided fields are modified.  Throws
  /// on error.
  static Future<void> updateGalleryImage({
    required String id,
    String? description,
    String? length,
    String? style,
    String? colour,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (description != null) updateData['description'] = description;
    if (length != null) updateData['length'] = length;
    if (style != null) updateData['style'] = style;
    if (colour != null) updateData['colour'] = colour;
    if (updateData.isEmpty) return;
    final response = await _client
        .from('gallery_images')
        .update(updateData)
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Deletes a gallery image by its id.  This also cascades the
  /// deletion of any associated likes.  Throws on error.
  static Future<void> deleteGalleryImage(String id) async {
    final response = await _client
        .from('gallery_images')
        .delete()
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Returns a list of gallery images posted by the given [userId].
  /// Each map contains the same fields as [getGalleryImages].  If
  /// [userId] is null, an empty list is returned.  Throws on error.
  static Future<List<Map<String, dynamic>>> getGalleryImagesByUser(String? userId) async {
    if (userId == null) return [];
    final response = await _client
        .from('gallery_images')
        .select(
            'id, user_id, salon_id, url, description, length, style, colour, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final List<dynamic> data = response.data as List<dynamic>;
    final List<Map<String, dynamic>> images = [];
    for (final item in data) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(item);
      final String? path = row['url'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          final signed = await _client.storage
              .from(_galleryBucket)
              .createSignedUrl(path, 604800);
          if (signed.error == null && signed.data != null) {
            row['url'] = signed.data as String;
          }
        } catch (_) {
          // ignore errors
        }
      }
      images.add(row);
    }
    return images;
  }

  /// Returns a list of gallery images liked by the current user.  A
  /// join is performed between `gallery_likes` and `gallery_images`
  /// to retrieve image details.  If the user is not logged in, an
  /// empty list is returned.  Throws on error.
  static Future<List<Map<String, dynamic>>> getLikedGalleryImages() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .rpc('get_liked_gallery_images', params: {'uid': userId});
    // If the RPC isn't defined return fallback via join
    if (response.error != null) {
      // fallback: manual join
      final likesRes = await _client
          .from('gallery_likes')
          .select('image_id')
          .eq('user_id', userId)
          .execute();
      if (likesRes.error != null) {
        throw likesRes.error!;
      }
      final ids = (likesRes.data as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['image_id'].toString())
          .toList();
      if (ids.isEmpty) return [];
      final imagesRes = await _client
          .from('gallery_images')
          .select(
              'id, user_id, salon_id, url, description, length, style, colour, created_at')
          .in_('id', ids)
          .execute();
      if (imagesRes.error != null) {
        throw imagesRes.error!;
      }
      final data = imagesRes.data as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final data = response.data as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  /// Retrieves all services.  Each map includes the service id, name,
  /// category, price, duration and description.  Results are ordered by
  /// name.  Throws on error.
  static Future<List<Map<String, dynamic>>> getAllServices() async {
    final response = await _client
        .from('services')
        .select('id, name, category, price, duration, description')
        .order('name')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Inserts a new service record and returns the created id.  The
  /// [category] should correspond to the service category (e.g.
  /// 'Damen', 'Herren', 'Bart', 'Spezial').  Throws on error.
  static Future<int> addService({
    required String name,
    required String category,
    required int duration,
    required num price,
    String? description,
  }) async {
    final response = await _client
        .from('services')
        .insert({
          'name': name,
          'category': category,
          'duration': duration,
          'price': price,
          if (description != null) 'description': description,
        })
        .select('id')
        .single()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    return data['id'] as int;
  }

  /// Updates an existing service.  Only provided fields are updated.
  /// Throws on error.
  static Future<void> updateService({
    required int id,
    String? name,
    String? category,
    int? duration,
    num? price,
    String? description,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (category != null) updateData['category'] = category;
    if (duration != null) updateData['duration'] = duration;
    if (price != null) updateData['price'] = price;
    if (description != null) updateData['description'] = description;
    if (updateData.isEmpty) {
      return;
    }
    final response = await _client
        .from('services')
        .update(updateData)
        .eq('id', id)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Deletes a service by id.  This permanently removes the record.
  /// Throws on error.
  static Future<void> deleteService(int id) async {
    final response =
        await _client.from('services').delete().eq('id', id).execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Calculates revenue totals within a given period.  Returns a map
  /// with keys `totalRevenue` and `daily` where `daily` is a list of
  /// objects with `date` (DateTime) and `total` (num) fields.  The
  /// optional [salonId] filters to a specific salon.  Data is
  /// aggregated client‑side after retrieving all transactions in
  /// range.  Throws on error.
  static Future<Map<String, dynamic>> getRevenueByPeriod({
    required DateTime start,
    required DateTime end,
    String? salonId,
  }) async {
    var query = _client
        .from('transactions')
        .select('total_amount, created_at');
    query = query.gte('created_at', start.toIso8601String());
    query = query.lt('created_at', end.toIso8601String());
    if (salonId != null) {
      query = query.eq('salon_id', salonId);
    }
    final response = await query.execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    num totalRevenue = 0;
    final Map<String, num> dailyTotals = {};
    for (final item in data) {
      final amount = item['total_amount'] as num? ?? 0;
      final createdAtStr = item['created_at'] as String?;
      if (createdAtStr != null) {
        final date = DateTime.parse(createdAtStr).toLocal();
        final dayKey = DateTime(date.year, date.month, date.day).toIso8601String();
        dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + amount;
        totalRevenue += amount;
      }
    }
    final dailyList = dailyTotals.entries
        .map((e) => {
              'date': DateTime.parse(e.key),
              'total': e.value,
            })
        .toList()
      ..sort((a, b) => (a['date'] as DateTime)
          .compareTo(b['date'] as DateTime));
    return {
      'totalRevenue': totalRevenue,
      'daily': dailyList,
    };
  }

  /// Computes utilisation per stylist between [start] and [end].  The
  /// result is a list of maps with `stylist_id`, `bookedMinutes`,
  /// `shiftMinutes` and `utilization` (0–1).  It fetches shifts and
  /// bookings in the time range and aggregates durations per stylist.
  static Future<List<Map<String, dynamic>>> getUtilizationByStylist({
    required DateTime start,
    required DateTime end,
  }) async {
    // Fetch shifts within range
    final shiftsResponse = await _client
        .from('shifts')
        .select('stylist_id, duration, date, start_time')
        .gte('date', DateFormat('yyyy-MM-dd').format(start))
        .lte('date', DateFormat('yyyy-MM-dd').format(end))
        .execute();
    if (shiftsResponse.error != null) {
      throw shiftsResponse.error!;
    }
    final shiftsData = shiftsResponse.data as List<dynamic>;
    final Map<int, int> shiftMinutes = {};
    for (final item in shiftsData) {
      final sid = item['stylist_id'] as int?;
      final duration = item['duration'] as int? ?? 0;
      if (sid != null) {
        shiftMinutes[sid] = (shiftMinutes[sid] ?? 0) + duration;
      }
    }
    // Fetch bookings within range
    final bookingsResponse = await _client
        .from('bookings')
        .select('stylist_id, duration, start_datetime')
        .gte('start_datetime', start.toIso8601String())
        .lt('start_datetime', end.toIso8601String())
        .execute();
    if (bookingsResponse.error != null) {
      throw bookingsResponse.error!;
    }
    final bookingsData = bookingsResponse.data as List<dynamic>;
    final Map<int, int> bookedMinutes = {};
    for (final item in bookingsData) {
      final sid = item['stylist_id'] as int?;
      final duration = item['duration'] as int? ?? 0;
      if (sid != null) {
        bookedMinutes[sid] = (bookedMinutes[sid] ?? 0) + duration;
      }
    }
    // Combine
    final Set<int> stylistIds = {...shiftMinutes.keys, ...bookedMinutes.keys};
    final List<Map<String, dynamic>> result = [];
    for (final id in stylistIds) {
      final shift = shiftMinutes[id] ?? 0;
      final booked = bookedMinutes[id] ?? 0;
      final util = shift > 0 ? booked / shift : 0;
      result.add({
        'stylist_id': id,
        'bookedMinutes': booked,
        'shiftMinutes': shift,
        'utilization': util,
      });
    }
    return result;
  }

  /// Returns the top N services by number of bookings in the given
  /// period.  The result is a list of maps with `service_id`,
  /// `name` and `count`.  Services with more bookings appear first.
  static Future<List<Map<String, dynamic>>> getTopServices({
    required DateTime start,
    required DateTime end,
    int limit = 5,
  }) async {
    // Fetch bookings with service id between dates
    final bookingsResponse = await _client
        .from('bookings')
        .select('service_id')
        .gte('start_datetime', start.toIso8601String())
        .lt('start_datetime', end.toIso8601String())
        .execute();
    if (bookingsResponse.error != null) {
      throw bookingsResponse.error!;
    }
    final bookingsData = bookingsResponse.data as List<dynamic>;
    final Map<int, int> counts = {};
    for (final item in bookingsData) {
      final sid = item['service_id'] as int?;
      if (sid != null) {
        counts[sid] = (counts[sid] ?? 0) + 1;
      }
    }
    // Fetch service names for those ids
    final serviceIds = counts.keys.toList();
    if (serviceIds.isEmpty) {
      return [];
    }
    final servicesResponse = await _client
        .from('services')
        .select('id, name')
        .in_('id', serviceIds)
        .execute();
    if (servicesResponse.error != null) {
      throw servicesResponse.error!;
    }
    final servicesData = servicesResponse.data as List<dynamic>;
    final Map<int, String> idToName = {};
    for (final item in servicesData) {
      final id = item['id'] as int?;
      final name = item['name'] as String?;
      if (id != null && name != null) {
        idToName[id] = name;
      }
    }
    // Build list and sort
    final List<Map<String, dynamic>> result = [];
    counts.forEach((sid, count) {
      result.add({'service_id': sid, 'name': idToName[sid] ?? 'Unbekannt', 'count': count});
    });
    result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    if (result.length > limit) {
      return result.sublist(0, limit);
    }
    return result;
  }

  /// Calculates the no‑show rate for bookings in the given period.
  /// The returned map contains `total` (total bookings), `noShows`
  /// (count with status 'no_show') and `rate` (noShows/total).  If
  /// there are no bookings, the rate is null.  Throws on error.
  static Future<Map<String, dynamic>> getNoShowRates({
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _client
        .from('bookings')
        .select('status')
        .gte('start_datetime', start.toIso8601String())
        .lt('start_datetime', end.toIso8601String())
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    int total = 0;
    int noShows = 0;
    for (final item in data) {
      total++;
      final status = (item['status'] as String?)?.toLowerCase() ?? '';
      if (status == 'no_show' || status == 'noshow' || status == 'no-show') {
        noShows++;
      }
    }
    double? rate;
    if (total > 0) {
      rate = noShows / total;
    }
    return {'total': total, 'noShows': noShows, 'rate': rate};
  }

  /// Aggregates simple loyalty statistics.  Returns a map with
  /// `totalCustomers`, `averagePoints`, `totalRedemptions` and
  /// `redemptionRate` (redemptions per customer) for the entire
  /// database.  Throws on error.
  static Future<Map<String, dynamic>> getLoyaltyStats() async {
    final pointsResponse = await _client.from('customer_loyalty_points').select('points').execute();
    if (pointsResponse.error != null) {
      throw pointsResponse.error!;
    }
    final pointsData = pointsResponse.data as List<dynamic>;
    int totalCustomers = pointsData.length;
    num totalPoints = 0;
    for (final item in pointsData) {
      totalPoints += (item['points'] as int?) ?? 0;
    }
    final averagePoints = totalCustomers > 0 ? totalPoints / totalCustomers : 0;
    final redemptionsResponse = await _client.from('loyalty_redemptions').select('id').execute();
    if (redemptionsResponse.error != null) {
      throw redemptionsResponse.error!;
    }
    final redemptionsData = redemptionsResponse.data as List<dynamic>;
    final totalRedemptions = redemptionsData.length;
    final redemptionRate = totalCustomers > 0 ? totalRedemptions / totalCustomers : 0;
    return {
      'totalCustomers': totalCustomers,
      'averagePoints': averagePoints,
      'totalRedemptions': totalRedemptions,
      'redemptionRate': redemptionRate,
    };
  }

  /// Computes simple inventory KPIs.  Returns a map with
  /// `totalProducts`, `lowStockCount` (quantity <= 5) and
  /// `totalValue` (sum of price * quantity).  Throws on error.
  static Future<Map<String, dynamic>> getInventoryKPI() async {
    final response = await _client
        .from('products')
        .select('price, quantity')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    int totalProducts = data.length;
    int lowStockCount = 0;
    num totalValue = 0;
    for (final item in data) {
      final price = (item['price'] as num?) ?? 0;
      final qty = (item['quantity'] as int?) ?? 0;
      totalValue += price * qty;
      if (qty <= 5) {
        lowStockCount++;
      }
    }
    return {
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
      'totalValue': totalValue,
    };
  }

  /// Retrieves the current loyalty program for the platform or salon.
  ///
  /// This helper returns the first entry in the `loyalty_programs` table
  /// which defines the points per currency unit, level thresholds and
  /// available rewards. The `level_thresholds` and `rewards` columns are
  /// stored as JSONB in the database and are returned as decoded Dart
  /// structures (Map and List respectively). If no program exists the
  /// return value is `null`.
  static Future<Map<String, dynamic>?> getLoyaltyProgram() async {
    final response = await _client
        .from('loyalty_programs')
        .select('id, points_per_currency, level_thresholds, rewards, is_active')
        .limit(1)
        .maybeSingle()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data;
    if (data == null) {
      return null;
    }
    // Decode JSON fields. Supabase returns JSON columns as dynamic
    // maps/lists already, but we defensively cast to Map/List for type
    // safety.
    final levels = data['level_thresholds'];
    final rewards = data['rewards'];
    return {
      'id': data['id'],
      'pointsPerCurrency': data['points_per_currency'],
      'levelThresholds': levels is Map ? Map<String, dynamic>.from(levels) : <String, dynamic>{},
      'rewards': rewards is List ? List<Map<String, dynamic>>.from(rewards.map((e) => Map<String, dynamic>.from(e))) : <Map<String, dynamic>>[],
      'isActive': data['is_active'] ?? true,
    };
  }

  /// Creates or updates the loyalty program.  If a program with the given
  /// [programId] exists, its data is updated; otherwise a new program
  /// record is inserted.  The [pointsPerCurrency] defines how many
  /// loyalty points are earned per unit of currency spent.  The
  /// [levelThresholds] map associates a loyalty level name (e.g.
  /// 'Bronze', 'Silber', 'Gold') with the number of points required to
  /// reach that level.  The [rewards] list contains objects with keys
  /// `name`, `description` and `points`.  Throws on error.
  static Future<void> upsertLoyaltyProgram({
    String? programId,
    required double pointsPerCurrency,
    required Map<String, dynamic> levelThresholds,
    required List<Map<String, dynamic>> rewards,
    bool isActive = true,
  }) async {
    // Prepare the payload.  Supabase will store the map/list directly in
    // JSONB columns.  When upserting, you must include the primary key
    // (`id`) if updating an existing record.
    final payload = <String, dynamic>{
      'points_per_currency': pointsPerCurrency,
      'level_thresholds': levelThresholds,
      'rewards': rewards,
      'is_active': isActive,
    };
    if (programId != null) {
      payload['id'] = programId;
    }
    final response = await _client
        .from('loyalty_programs')
        .upsert(payload)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
  }

  /// Calculates the loyalty status for the currently logged in user.  The
  /// returned map contains the customer's `points`, their current
  /// `level`, the `nextLevelName` (or null if the highest level), the
  /// number of points required to reach the next level (`pointsToNext`),
  /// and a list of `availableRewards` (each with `name`, `description`
  /// and `points`).  This function automatically resolves the
  /// `customer_id` from the current user's email in the `customers`
  /// table and falls back to zero points if none is found.  Rewards
  /// become available when the customer's points meet or exceed the
  /// specified `points` cost.  Throws on network or query errors.
  static Future<Map<String, dynamic>> getLoyaltyStatus() async {
    // Resolve customer ID based on the logged in user's email.  If the
    // user is not logged in or has no matching customer record, they
    // have zero points by default.
    final email = _client.auth.currentUser?.email;
    int? customerId;
    if (email != null) {
      final customerResp = await _client
          .from('customers')
          .select('id')
          .eq('email', email)
          .maybeSingle()
          .execute();
      if (customerResp.error != null) {
        throw customerResp.error!;
      }
      final cust = customerResp.data;
      if (cust != null && cust['id'] != null) {
        customerId = cust['id'] as int?;
      }
    }
    // Fetch points from customer_loyalty_points table.
    int points = 0;
    if (customerId != null) {
      final pointsResp = await _client
          .from('customer_loyalty_points')
          .select('points')
          .eq('customer_id', customerId)
          .maybeSingle()
          .execute();
      if (pointsResp.error != null) {
        throw pointsResp.error!;
      }
      final row = pointsResp.data;
      if (row != null && row['points'] != null) {
        points = (row['points'] as int?) ?? 0;
      }
    }
    // Fetch loyalty program.  If none exists, default to empty config.
    final program = await getLoyaltyProgram();
    Map<String, dynamic> levelThresholds;
    List<Map<String, dynamic>> rewards;
    if (program != null) {
      levelThresholds = Map<String, dynamic>.from(program['levelThresholds'] as Map);
      rewards = List<Map<String, dynamic>>.from(program['rewards'] as List);
    } else {
      levelThresholds = {};
      rewards = [];
    }
    // Determine current level and next level based on thresholds.
    String currentLevel = '';
    String? nextLevelName;
    int? nextLevelPoints;
    if (levelThresholds.isNotEmpty) {
      // Sort levels by threshold ascending.
      final sorted = levelThresholds.entries.toList()
        ..sort((a, b) => (a.value as num).compareTo(b.value as num));
      for (int i = 0; i < sorted.length; i++) {
        final name = sorted[i].key;
        final threshold = (sorted[i].value as num).toInt();
        if (points < threshold) {
          nextLevelName = name;
          nextLevelPoints = threshold;
          break;
        }
        currentLevel = name;
      }
      // If points exceed all thresholds, there is no next level.
    }
    int pointsToNext = 0;
    if (nextLevelPoints != null) {
      pointsToNext = nextLevelPoints - points;
    }
    // Filter rewards that can be redeemed.  We consider a reward
    // available if it has a `points` property and the customer has
    // enough points.  Rewards without a points cost are always
    // available.
    final List<Map<String, dynamic>> availableRewards = [];
    for (final r in rewards) {
      final int cost = (r['points'] as num?)?.toInt() ?? 0;
      if (points >= cost) {
        availableRewards.add(r);
      }
    }
    return {
      'points': points,
      'level': currentLevel,
      'nextLevelName': nextLevelName,
      'pointsToNext': pointsToNext,
      'availableRewards': availableRewards,
    };
  }

  /// Redeems a loyalty reward for the currently logged in user.  The
  /// [reward] must contain at least the keys `name` and `points`.  The
  /// customer's points are reduced by the cost of the reward (if
  /// sufficient) and a redemption record is inserted into
  /// `loyalty_redemptions`.  Throws if the user is not logged in, no
  /// customer record exists or a database error occurs.
  static Future<void> redeemReward(Map<String, dynamic> reward) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw Exception('Nicht angemeldet');
    }
    // Resolve customer ID.
    final customerResp = await _client
        .from('customers')
        .select('id')
        .eq('email', email)
        .maybeSingle()
        .execute();
    if (customerResp.error != null) {
      throw customerResp.error!;
    }
    final cust = customerResp.data;
    if (cust == null || cust['id'] == null) {
      throw Exception('Kein Kundenkonto gefunden');
    }
    final customerId = cust['id'] as int;
    // Determine current points and row id.
    final pointsResp = await _client
        .from('customer_loyalty_points')
        .select('id, points')
        .eq('customer_id', customerId)
        .maybeSingle()
        .execute();
    if (pointsResp.error != null) {
      throw pointsResp.error!;
    }
    final row = pointsResp.data;
    int currentPoints = 0;
    int? rowId;
    if (row != null) {
      rowId = row['id'] as int?;
      currentPoints = (row['points'] as int?) ?? 0;
    }
    final cost = (reward['points'] as num?)?.toInt() ?? 0;
    if (currentPoints < cost) {
      throw Exception('Nicht genügend Punkte');
    }
    final newPoints = currentPoints - cost;
    // Update or insert loyalty points row.
    if (rowId != null) {
      final updateResp = await _client
          .from('customer_loyalty_points')
          .update({'points': newPoints})
          .match({'id': rowId})
          .execute();
      if (updateResp.error != null) {
        throw updateResp.error!;
      }
    } else {
      // Insert new row
      final insertResp = await _client
          .from('customer_loyalty_points')
          .insert({'customer_id': customerId, 'points': newPoints})
          .execute();
      if (insertResp.error != null) {
        throw insertResp.error!;
      }
    }
    // Insert redemption record.  Use null for salon_id as the program
    // may not be tied to a specific salon.
    final insertRedemption = await _client
        .from('loyalty_redemptions')
        .insert({
      'customer_id': customerId,
      'salon_id': null,
      'points_used': cost,
      'reward_description': reward['name'] ?? 'Reward',
    }).execute();
    if (insertRedemption.error != null) {
      throw insertRedemption.error!;
    }
  }

  /// Uploads a CSV report to Supabase storage.  The file is saved
  /// under the `reports` bucket with a timestamped filename.  Returns
  /// the public URL for downloading the report.  Throws on error.
  static Future<String> uploadReportCSV(String csvContent, String fileName) async {
    const bucket = 'reports';
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final bytes = utf8.encode(csvContent);
    // Convert to Uint8List before uploading.  The uploadBinary method
    // will throw on error.  We do not check an error field as the
    // returned type may differ across versions.
    final data = Uint8List.fromList(bytes);
    await _client.storage.from(bucket).uploadBinary(path, data);
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
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

  /// Checks whether a salon with the given [name] already exists.  The
  /// comparison is case‑insensitive. Returns `true` if a salon record
  /// with the same name is found, otherwise `false`. Throws on
  /// unexpected database errors.
  static Future<bool> doesSalonExist(String name) async {
    final sanitized = name.trim();
    if (sanitized.isEmpty) {
      return false;
    }
    final response = await _client
        .from('salons')
        .select('id')
        .ilike('name', sanitized)
        .limit(1)
        .maybeSingle()
        .execute();
    // If the status is 404 or 406, no matching row exists; return false.
    if (response.error != null) {
      // ignore 406 or 404 as they mean no record.
      if (response.status == 404 || response.status == 406) {
        return false;
      }
      throw response.error!;
    }
    return response.data != null;
  }

  /// Inserts a new salon into the database and returns its id.  The
  /// [ownerId] should be the id of the authenticated user who
  /// registers the salon. The [name] is required. The [address] can
  /// be null.  New salons are created with status 'approved' so they
  /// appear immediately on the map; adjust this if manual approval is
  /// desired. Throws on error.
  static Future<String> addSalon({
    required String ownerId,
    required String name,
    String? address,
  }) async {
    final insertData = <String, dynamic>{
      'owner_id': ownerId,
      'name': name,
      'status': 'approved',
    };
    if (address != null && address.trim().isNotEmpty) {
      insertData['address'] = address.trim();
    }
    final response = await _client
        .from('salons')
        .insert(insertData)
        .select('id')
        .single()
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
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
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
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
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
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