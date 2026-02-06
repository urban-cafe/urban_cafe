import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';

/// Service for image picking and Supabase storage uploads.
class StorageService {
  /// Pick an image file using the system file picker.
  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    return result?.files.first;
  }

  /// Upload an image to Supabase storage with WebP compression.
  /// Returns (storagePath, publicUrl) or null if not configured.
  Future<(String path, String url)?> uploadImage(PlatformFile file) async {
    if (!Env.isConfigured || file.bytes == null) return null;

    final client = GetIt.I<SupabaseClient>();

    // Compress to WebP (smaller, modern format supported by 98%+ browsers)
    Uint8List compressedBytes;
    String ext = 'webp';

    try {
      compressedBytes = await FlutterImageCompress.compressWithList(file.bytes!, minWidth: 1200, minHeight: 1200, quality: 85, format: CompressFormat.webp);
    } catch (e) {
      // Fallback if compression fails
      compressedBytes = file.bytes!;
      ext = (file.extension ?? 'jpg').toLowerCase();
    }

    // Use original if compression made it larger (unlikely)
    if (compressedBytes.length > file.bytes!.length) {
      compressedBytes = file.bytes!;
      ext = (file.extension ?? 'jpg').toLowerCase();
    }

    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from(Env.storageBucket).uploadBinary(path, compressedBytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

    final url = client.storage.from(Env.storageBucket).getPublicUrl(path);
    return (path, url);
  }
}
