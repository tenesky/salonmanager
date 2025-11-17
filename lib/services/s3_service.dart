import 'dart:typed_data';

import 'package:aws_s3_client/aws_s3_client.dart';

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
  // TODO: Remove hard‑coded credentials for production.  These keys
  // correspond to the S3 access keys generated from your Supabase
  // dashboard.  They should be rotated periodically and stored
  // securely, not checked into source control.
  static const String _accessKeyId =
      '279d0acbe57b394832c90299bed2456c';
  static const String _secretAccessKey =
      'be86a9858ebb460a05abe8f69a09031cf52dabafd46657cb27aa78c332b5fa03';

  // The Supabase project host for S3.  Do not include the path to
  // `/storage/v1/s3` here – the AWS S3 client will add the
  // appropriate route automatically.
  static const String _host = 'tojygtbhddmlgyilgcyj.storage.supabase.co';

  // Name of the bucket.  In Supabase, bucket names are case
  // sensitive.  This matches the bucket you created via the
  // dashboard.
  static const String _bucketName = 'salonmanager';

  // Region is not strictly required for Supabase but AWS libraries
  // expect one.  Since the endpoint URL determines the region
  // automatically, we set this to 'auto'.  You may also specify
  // 'us‑east‑1' or the region displayed in your Supabase project
  // settings.
  static const String _region = 'auto';

  /// Uploads a file to the configured bucket and returns the fully
  /// qualified URL for accessing the object.  The [fileBytes] must
  /// contain the raw bytes of the file to upload.  [fileName] should
  /// include an extension (e.g. `photo.jpg`).
  ///
  /// The object key will be prepended with a timestamp to ensure
  /// uniqueness.  Files are uploaded to the `private/` directory of
  /// the bucket so that access is controlled via Row Level
  /// Security (RLS) policies.  For this to work you must have
  /// created RLS policies on the `storage.objects` table similar to
  /// the ones shown in the Supabase dashboard.  See README for
  /// details.
  static Future<String> uploadGalleryImage(
      Uint8List fileBytes, String fileName) async {
    final s3 = S3(
      region: _region,
      accessKey: _accessKeyId,
      secretKey: _secretAccessKey,
      host: _host,
    );
    // The bucket instance provides helper methods for uploads.
    final bucket = Bucket(
      s3: s3,
      bucketName: _bucketName,
    );

    // Construct a unique key under the `private` folder.  The
    // timestamp ensures that multiple uploads with the same fileName
    // do not collide.  We prefix with 'private/' so that RLS
    // policies restrict access to authenticated users.
    final String key =
        'private/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // Determine the content type from the file extension.  If
    // unknown, default to binary/octet‑stream.
    final String contentType;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      default:
        contentType = 'application/octet‑stream';
        break;
    }

    // Upload the object to S3.  If anything goes wrong the
    // underlying library will throw an exception which propagates to
    // the caller.  You may wish to catch and handle it at a higher
    // layer (e.g. show a snackbar).
    await bucket.uploadObject(
      key,
      fileBytes,
      contentType: contentType,
    );

    // The public URL for private objects is based on the path to
    // `object` rather than `s3`.  Note that access to this URL will
    // require an authorization token generated via Supabase signed
    // URLs unless you make the object public.
    return
        'https://$_host/storage/v1/object/private/$_bucketName/$key';
  }
}