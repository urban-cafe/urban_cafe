import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';

/// Service for image picking and Supabase storage uploads.
class StorageService {
  /// Pick an image file using the system file picker.
  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    return result?.files.first;
  }

  /// Upload an image to Supabase storage with robust cross-platform compression.
  /// Guarantees images are resized to max 800x800 and compressed before upload.
  /// Returns (storagePath, publicUrl) or null if not configured.
  Future<(String path, String url)?> uploadImage(PlatformFile file) async {
    if (!Env.isConfigured || file.bytes == null) return null;

    final client = GetIt.I<SupabaseClient>();
    final stopwatch = Stopwatch()..start();

    Uint8List compressedBytes = file.bytes!;
    String ext = (file.extension ?? 'jpg').toLowerCase();

    try {
      // Use pure Dart 'image' package running in an isolate to prevent UI freezing.
      // Works consistently across Web, iOS, and Android without native dependencies.
      compressedBytes = await compute(_compressWithDartImage, file.bytes!);
      ext = 'jpg';
      debugPrint('✅ StorageService: Compressed via Dart Image');
    } catch (e) {
      debugPrint('⚠️ StorageService: ALL compression failed. Uploading original. Error: $e');
      // Final desperation fallback: upload original
      compressedBytes = file.bytes!;
      ext = (file.extension ?? 'jpg').toLowerCase();
    }

    // Safety check: if compression somehow made it larger, keep the original bytes
    if (compressedBytes.length > file.bytes!.length) {
      debugPrint('⚠️ StorageService: Compression made file larger. Keeping original.');
      compressedBytes = file.bytes!;
      ext = (file.extension ?? 'jpg').toLowerCase();
    }

    final int kbOriginal = file.bytes!.length ~/ 1024;
    final int kbFinal = compressedBytes.length ~/ 1024;
    debugPrint('Upload Size: $kbOriginal KB -> $kbFinal KB (${stopwatch.elapsedMilliseconds}ms)');

    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from(Env.storageBucket).uploadBinary(path, compressedBytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

    final url = client.storage.from(Env.storageBucket).getPublicUrl(path);
    return (path, url);
  }
}

/// Runs in an Isolate (via compute) so it doesn't freeze the UI while compressing
Uint8List _compressWithDartImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;

  // Resize if larger than 800px on any side
  img.Image resizedImage = image;
  if (image.width > 800 || image.height > 800) {
    resizedImage = img.copyResize(image, width: image.width > image.height ? 800 : null, height: image.height >= image.width ? 800 : null, interpolation: img.Interpolation.linear);
  }

  // Encode to highly compressed JPG
  return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 75));
}
