import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/services/storage_service.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/menu/domain/repositories/menu_repository.dart';
import 'package:urban_cafe/features/orders/domain/usecases/get_admin_analytics.dart';

class AdminProvider extends ChangeNotifier {
  final MenuRepository _repo;
  final StorageService _storage;
  final GetAdminAnalytics? getAdminAnalyticsUseCase;

  AdminProvider({MenuRepository? menuRepository, StorageService? storageService, this.getAdminAnalyticsUseCase})
    : _repo = menuRepository ?? GetIt.I<MenuRepository>(),
      _storage = storageService ?? GetIt.I<StorageService>();

  bool loading = false;
  String? error;

  // Analytics State
  Map<String, dynamic>? analytics;

  // ─────────────────────────────────────────────────────────────────
  // HELPER: Unified loading/error handling
  // ─────────────────────────────────────────────────────────────────
  Future<T?> _execute<T>(Future<Either<Failure, T>> Function() action, {bool notify = true}) async {
    loading = true;
    error = null;
    if (notify) notifyListeners();

    try {
      final result = await action();
      return result.fold((failure) {
        error = failure.message;
        return null;
      }, (data) => data);
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false;
      if (notify) notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────────────
  Future<void> loadAnalytics() async {
    if (getAdminAnalyticsUseCase == null) return;

    final data = await _execute(() => getAdminAnalyticsUseCase!(NoParams()));
    if (data != null) analytics = data;
  }

  // ─────────────────────────────────────────────────────────────────
  // IMAGE HANDLING (delegated to StorageService)
  // ─────────────────────────────────────────────────────────────────
  Future<PlatformFile?> pickImage() => _storage.pickImage();

  Future<(String path, String url)?> uploadImage(PlatformFile file) => _storage.uploadImage(file);

  // ─────────────────────────────────────────────────────────────────
  // CATEGORY MANAGEMENT
  // ─────────────────────────────────────────────────────────────────
  Future<String?> addCategory(String name, {String? parentId}) async {
    return _execute(() => _repo.createCategory(name, parentId: parentId));
  }

  Future<bool> renameCategory(String id, String newName) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repo.updateCategory(id, newName);
      return result.fold((failure) {
        error = failure.message;
        return false;
      }, (_) => true);
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repo.deleteCategory(id);
      return result.fold((failure) {
        error = failure.message;
        return false;
      }, (_) => true);
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // MENU ITEM CRUD
  // ─────────────────────────────────────────────────────────────────
  Future<bool> create({
    required String name,
    String? description,
    required double price,
    String? categoryId,
    bool isAvailable = true,
    bool isMostPopular = false,
    bool isWeekendSpecial = false,
    PlatformFile? imageFile,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      String? imagePath, imageUrl;
      if (imageFile != null) {
        final upload = await _storage.uploadImage(imageFile);
        if (upload != null) {
          imagePath = upload.$1;
          imageUrl = upload.$2;
        }
      }

      final result = await _repo.createMenuItem(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        isAvailable: isAvailable,
        isMostPopular: isMostPopular,
        isWeekendSpecial: isWeekendSpecial,
        imagePath: imagePath,
        imageUrl: imageUrl,
      );

      return result.fold((failure) {
        error = failure.message;
        return false;
      }, (_) => true);
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> update({
    required String id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    bool? isAvailable,
    bool? isMostPopular,
    bool? isWeekendSpecial,
    PlatformFile? imageFile,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      String? imagePath, imageUrl;
      if (imageFile != null) {
        final upload = await _storage.uploadImage(imageFile);
        if (upload != null) {
          imagePath = upload.$1;
          imageUrl = upload.$2;
        }
      }

      final result = await _repo.updateMenuItem(
        id: id,
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        isAvailable: isAvailable,
        isMostPopular: isMostPopular,
        isWeekendSpecial: isWeekendSpecial,
        imagePath: imagePath,
        imageUrl: imageUrl,
      );

      return result.fold((failure) {
        error = failure.message;
        return false;
      }, (_) => true);
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
    error = null;
    notifyListeners();

    try {
      final result = await _repo.deleteMenuItem(id);
      return result.fold((failure) {
        error = failure.message;
        return false;
      }, (_) => true);
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
