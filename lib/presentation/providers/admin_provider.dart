import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
    // ... (Keep existing upload logic) ...
    if (!Env.isConfigured) return null;
    final client = SupabaseClientProvider.client;
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from(Env.storageBucket).uploadBinary(path, file.bytes!, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));
    final url = client.storage.from(Env.storageBucket).getPublicUrl(path);
    return (path, url);
  }

  Future<String?> addCategory(String name, {String? parentId}) async {
    loading = true;
    notifyListeners();
    try {
      final id = await _repo.createCategory(name, parentId: parentId);
      return id;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> renameCategory(String id, String newName) async {
    loading = true;
    notifyListeners();
    try {
      await _repo.updateCategory(id, newName);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({required String name, String? description, required double price, String? categoryId, bool isAvailable = true, PlatformFile? imageFile}) async {
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
      await _repo.createMenuItem(name: name, description: description, price: price, categoryId: categoryId, isAvailable: isAvailable, imagePath: imagePath, imageUrl: imageUrl);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> update({required String id, String? name, String? description, double? price, String? categoryId, bool? isAvailable, PlatformFile? imageFile}) async {
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
      await _repo.updateMenuItem(id: id, name: name, description: description, price: price, categoryId: categoryId, isAvailable: isAvailable, imagePath: imagePath, imageUrl: imageUrl);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    loading = true;
    notifyListeners();
    try {
      await _repo.deleteMenuItem(id);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
