import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../data/levels_data.dart';
import '../models/game_level.dart';

/// Quản lý danh sách các màn chơi trong game.
/// Có khả năng đọc cấu trúc 100 màn chơi từ file JSON trong assets
/// và cung cấp dữ liệu cho toàn bộ ứng dụng.
class LevelManager extends ChangeNotifier {
  static const String defaultAssetPath = 'assets/levels.json';

  List<GameLevel> _levels = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<GameLevel> get levels => List.unmodifiable(_levels);
  int get totalLevels => _levels.length;
  bool get isLoading => _isLoading;
  bool get isLoaded => _levels.isNotEmpty;
  String? get errorMessage => _errorMessage;

  /// Lấy màn chơi theo chỉ số [index] (0-indexed).
  /// Nếu chỉ số không hợp lệ, trả về màn chơi đầu tiên làm fallback.
  GameLevel getLevel(int index) {
    if (_levels.isEmpty) {
      // Nếu chưa load xong JSON, fallback về sampleLevels có sẵn
      return sampleLevels[index.clamp(0, sampleLevels.length - 1)];
    }
    return _levels[index.clamp(0, _levels.length - 1)];
  }

  /// Nạp danh sách các màn chơi từ file JSON trong assets bằng [rootBundle.loadString].
  ///
  /// Parse JSON mảng các level thành danh sách [GameLevel] thông qua [GameLevel.fromJson].
  /// Tự động fallback về [sampleLevels] nếu gặp lỗi nạp file.
  Future<void> loadLevelsFromJson({String assetPath = defaultAssetPath}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String jsonStr = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonStr);

      if (decoded is List) {
        final List<GameLevel> parsedLevels = decoded
            .map((item) => GameLevel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (parsedLevels.isNotEmpty) {
          _levels = parsedLevels;
        } else {
          _levels = List.from(sampleLevels);
        }
      } else {
        throw const FormatException('Dữ liệu JSON levels không phải là danh sách (List).');
      }
    } catch (e) {
      _errorMessage = 'Không thể nạp file JSON từ $assetPath: $e';
      if (kDebugMode) {
        print('[LevelManager] Cảnh báo: $_errorMessage. Sử dụng sampleLevels dự phòng.');
      }
      // Dự phòng sang danh sách sampleLevels hiện có
      if (_levels.isEmpty) {
        _levels = List.from(sampleLevels);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cho phép nạp trực tiếp danh sách levels từ chuỗi JSON thô (rất tiện khi viết Unit Test)
  void loadFromString(String jsonContent) {
    final dynamic decoded = jsonDecode(jsonContent);
    if (decoded is List) {
      _levels = decoded
          .map((item) => GameLevel.fromJson(item as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }
}
