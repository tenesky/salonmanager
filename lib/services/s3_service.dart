import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A simple wrapper around the AWS S3 client that uploads files to a
/// Supabase S3‑compatible Storage bucket.  The Supabase project
/// exposes an S3 endpoint, which means we can interact with it using
/// the standard AWS S3 protocol and a pair of access/secret keys.
///
/// This service is used by the gallery and other parts of the app to
/// store user‑generated images (e.g. hairstyle photos) in the
/// `salonmanager` bucket.  Files are never persisted on the client
/// device – they are uploaded directly to the bucket and the public
/// URL is returned.  You should not hard‑code credentials in
/// production; instead, read them from a secure source (e.g.
/// environment variables or remote config).
class S3Service {
  // Name of the bucket created in Supabase.  Bucket names are case
  // sensitive.  This must match the bucket configured in your
  // Supabase Storage dashboard (e.g. "salonmanager").  Objects
  // uploaded via this service will be stored under the `private/`
  // folder so that Row Level Security policies can control access.
  static const String _bucketName = 'salonmanager';

  /// Uploads a file to the configured bucket via the Supabase Storage
  /// API and returns the full path of the stored object.  The
  /// [fileBytes] must contain the raw bytes of the file to upload.
  /// [fileName] should include an extension (e.g. `photo.jpg`).  The
  /// object key will be prefixed with `private/` and a timestamp to
  /// ensure uniqueness.  Access to these objects is controlled by
  /// Storage RLS policies, so only authenticated users can upload
  /// and retrieve them.  The returned string is the storage path
  /// (not a public URL); call `getPublicUrl` or `createSignedUrl` on
  /// the Supabase client to generate a URL for display.
  static Future<String> uploadGalleryImage(
      Uint8List fileBytes, String fileName) async {
    final filePath =
        'private/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    // Perform the upload.  Throws on error.
    await Supabase.instance.client.storage
        .from(_bucketName)
        .uploadBinary(filePath, fileBytes);
    // Return the storage path.  To display the image, you should call
    // Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath)
    // or createSignedUrl with an expiry.  We leave URL generation to
    // the caller because private buckets require signed URLs.
    return filePath;
  }
}