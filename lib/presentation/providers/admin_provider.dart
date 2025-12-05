import 'dart:developer';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/data/datasources/supabase_client.dart';
import 'package:urban_cafe/data/repositories/menu_repository_impl.dart';
import 'package:urban_cafe/domain/entities/menu_item.dart';
import 'package:urban_cafe/domain/usecases/create_menu_item.dart';
import 'package:urban_cafe/domain/usecases/delete_menu_item.dart';
import 'package:urban_cafe/domain/usecases/update_menu_item.dart';

class AdminProvider extends ChangeNotifier {
  final _create = CreateMenuItem(MenuRepositoryImpl());
  final _update = UpdateMenuItem(MenuRepositoryImpl());
  final _delete = DeleteMenuItem(MenuRepositoryImpl());
  bool loading = false;
  String? error;
  MenuItemEntity? lastSaved;

  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null) return null;
    return result.files.first;
  }

  Future<(String path, String url)?> uploadImage(PlatformFile file) async {
    if (!Env.isConfigured) return null;
    if (SupabaseClientProvider.client.auth.currentUser == null) {
      error = 'Sign in required to upload images';
      notifyListeners();
      return null;
    }
    final client = SupabaseClientProvider.client;
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final id = client.auth.currentUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$id-${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = file.bytes ?? Uint8List(0);
    await client.storage
        .from(Env.storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$ext', cacheControl: 'public, max-age=31536000'),
        );
    final url = client.storage.from(Env.storageBucket).getPublicUrl(path);
    return (path, url);
  }

  Future<MenuItemEntity?> create({required String name, String? description, required double price, String? category, bool isAvailable = true, PlatformFile? imageFile}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      String? imagePath;
      String? imageUrl;
      if (imageFile != null) {
        final uploaded = await uploadImage(imageFile);
        if (uploaded != null) {
          imagePath = uploaded.$1;
          imageUrl = uploaded.$2;
        }
      }
      lastSaved = await _create(name: name, description: description, price: price, category: category, isAvailable: isAvailable, imagePath: imagePath, imageUrl: imageUrl);
      return lastSaved;
    } catch (e) {
      error = e.toString();
      log("Error creating menu item: $error");
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<MenuItemEntity?> update({required String id, String? name, String? description, double? price, String? category, bool? isAvailable, PlatformFile? imageFile}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      String? imagePath;
      String? imageUrl;
      if (imageFile != null) {
        final uploaded = await uploadImage(imageFile);
        if (uploaded != null) {
          imagePath = uploaded.$1;
          imageUrl = uploaded.$2;
        }
      }
      lastSaved = await _update(id: id, name: name, description: description, price: price, category: category, isAvailable: isAvailable, imagePath: imagePath, imageUrl: imageUrl);
      return lastSaved;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _delete(id);
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
