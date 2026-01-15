import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';

class AdminProvider extends ChangeNotifier {
  final _repo = MenuRepositoryImpl();

  bool loading = false;
  String? error;

  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null) return null;
    return result.files.first;
  }

  Future<(String path, String url)?> uploadImage(PlatformFile file) async {
    if (!Env.isConfigured) return null;
    final client = SupabaseClientProvider.client;

    // Compress to WebP (smaller, modern format supported by 98%+ browsers)
    Uint8List compressedBytes;
    String ext = 'webp';
    try {
      compressedBytes = await FlutterImageCompress.compressWithList(
        file.bytes!,
        minWidth: 1200, // Max width for full image
        minHeight: 1200,
        quality: 85, // Balance quality/size
        format: CompressFormat.webp,
      );
    } catch (e) {
      // Fallback if compression fails (rare)
      compressedBytes = file.bytes!;
      ext = (file.extension ?? 'jpg').toLowerCase();
    }

    // Optional: If compressed is larger (unlikely), use original
    if (compressedBytes.length > file.bytes!.length) {
      compressedBytes = file.bytes!;
      ext = (file.extension ?? 'jpg').toLowerCase();
    }

    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from(Env.storageBucket).uploadBinary(path, compressedBytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

    final url = client.storage.from(Env.storageBucket).getPublicUrl(path);
    return (path, url);
  }

  Future<String?> addCategory(String name, {String? parentId}) async {
    loading = true;
    notifyListeners();
    final result = await _repo.createCategory(name, parentId: parentId);
    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return null;
      },
      (id) {
        loading = false;
        notifyListeners();
        return id;
      }
    );
  }

  Future<bool> renameCategory(String id, String newName) async {
    loading = true;
    notifyListeners();
    final result = await _repo.updateCategory(id, newName);
    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (_) {
        loading = false;
        notifyListeners();
        return true;
      }
    );
  }

  Future<bool> deleteCategory(String id) async {
    loading = true;
    notifyListeners();
    final result = await _repo.deleteCategory(id);
    return result.fold(
      (failure) {
        error = failure.message;
        loading = false;
        notifyListeners();
        return false;
      },
      (_) {
        loading = false;
        notifyListeners();
        return true;
      }
    );
  }

  Future<bool> create({required String name, String? description, required double price, String? categoryId, bool isAvailable = true, bool isMostPopular = false, bool isWeekendSpecial = false, PlatformFile? imageFile}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      String? imagePath, imageUrl;
      if (imageFile != null) {
        final up = await uploadImage(imageFile);
        if (up != null) {
          imagePath = up.$1;
          imageUrl = up.$2;
        }
      }
      final result = await _repo.createMenuItem(name: name, description: description, price: price, categoryId: categoryId, isAvailable: isAvailable, isMostPopular: isMostPopular, isWeekendSpecial: isWeekendSpecial, imagePath: imagePath, imageUrl: imageUrl);
      
      return result.fold(
        (failure) {
          error = failure.message;
          return false;
        },
        (_) => true
      );
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> update({required String id, String? name, String? description, double? price, String? categoryId, bool? isAvailable, bool? isMostPopular, bool? isWeekendSpecial, PlatformFile? imageFile}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      String? imagePath, imageUrl;
      if (imageFile != null) {
        final up = await uploadImage(imageFile);
        if (up != null) {
          imagePath = up.$1;
          imageUrl = up.$2;
        }
      }
      final result = await _repo.updateMenuItem(id: id, name: name, description: description, price: price, categoryId: categoryId, isAvailable: isAvailable, isMostPopular: isMostPopular, isWeekendSpecial: isWeekendSpecial, imagePath: imagePath, imageUrl: imageUrl);
      
      return result.fold(
        (failure) {
          error = failure.message;
          return false;
        },
        (_) => true
      );
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    loading = true;
    notifyListeners();
    try {
      final result = await _repo.deleteMenuItem(id);
      return result.fold(
        (failure) {
          error = failure.message;
          return false;
        },
        (_) => true
      );
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
