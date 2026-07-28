import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/app_constants.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init(AppConstants.storageBox);
    _box = GetStorage(AppConstants.storageBox);
    return this;
  }

  T? read<T>(String key) => _box.read<T>(key);

  Future<void> write(String key, dynamic value) => _box.write(key, value);

  Future<void> remove(String key) => _box.remove(key);

  List<String> readStringList(String key) {
    final raw = _box.read(key);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> writeStringList(String key, List<String> value) =>
      _box.write(key, value);
}
