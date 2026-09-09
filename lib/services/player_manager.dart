import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

/// Quản lý tiến trình, mạng sống (lives), gợi ý (hints), điểm danh và số sao của người chơi.
/// Tích hợp SharedPreferences để lưu cục bộ và ChangeNotifier để tự động cập nhật UI.
class PlayerManager extends ChangeNotifier {
  static const String _keyLives = 'player_lives';
  static const String _keyHints = 'player_hints';
  static const String _keyLastCheckInDate = 'player_last_check_in_date';
  static const String _keyUnlockedLevels = 'player_unlocked_levels';
  static const String _keyLevelStars = 'player_level_stars';

  static const int maxLives = 5;
  static const int defaultHints = 3;

  int _lives = maxLives;
  int _hints = defaultHints;
  String? _lastCheckInDate;
  int _unlockedLevels = 1;
  Map<int, int> _levelStars = {};
  bool _isInitialized = false;
  bool _justClaimedDailyReward = false;

  // Getters
  int get lives => _lives;
  int get hints => _hints;
  String? get lastCheckInDate => _lastCheckInDate;
  int get unlockedLevels => _unlockedLevels;
  Map<int, int> get levelStars => Map.unmodifiable(_levelStars);
  bool get isInitialized => _isInitialized;
  bool get hasLives => _lives > 0;
  bool get justClaimedDailyReward => _justClaimedDailyReward;

  /// Tổng số sao người chơi đã gom được trên tất cả các level
  int get totalStarsEarned => _levelStars.values.fold(0, (sum, s) => sum + s);

  /// Lấy số sao của một level cụ thể (0 nếu chưa đạt sao nào)
  int getLevelStars(int levelIndex) => _levelStars[levelIndex] ?? 0;

  /// Lưu số sao đạt được cho màn chơi (chỉ ghi đè nếu số sao mới cao hơn)
  void setLevelStars(int levelIndex, int stars) {
    if (stars <= 0) return;
    final current = _levelStars[levelIndex] ?? 0;
    if (stars > current) {
      _levelStars[levelIndex] = stars.clamp(1, 3);
      _save();
      notifyListeners();
    }
  }

  /// Khởi tạo và load dữ liệu từ SharedPreferences, sau đó tự động kiểm tra quà điểm danh.
  Future<void> init() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        SharedPreferencesWindows.registerWith();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();

    _lives = prefs.getInt(_keyLives) ?? maxLives;
    _hints = prefs.getInt(_keyHints) ?? defaultHints;
    _lastCheckInDate = prefs.getString(_keyLastCheckInDate);
    _unlockedLevels = prefs.getInt(_keyUnlockedLevels) ?? 1;

    // Load số sao của từng level
    final starsJson = prefs.getString(_keyLevelStars);
    if (starsJson != null && starsJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(starsJson);
        _levelStars = decoded.map(
          (k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toInt()),
        );
      } catch (_) {}
    }

    _isInitialized = true;

    // Kiểm tra quà điểm danh mỗi khi khởi động
    _justClaimedDailyReward = checkDailyReward();

    notifyListeners();
  }

  /// Lưu tất cả trạng thái hiện tại vào SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLives, _lives);
    await prefs.setInt(_keyHints, _hints);
    if (_lastCheckInDate != null) {
      await prefs.setString(_keyLastCheckInDate, _lastCheckInDate!);
    }
    await prefs.setInt(_keyUnlockedLevels, _unlockedLevels);

    // Lưu bảng sao
    final starsMapStr = _levelStars.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_keyLevelStars, jsonEncode(starsMapStr));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Logic Điểm danh (Daily Reward)
  // ───────────────────────────────────────────────────────────────────────────
  /// Kiểm tra ngày điểm danh:
  /// Nếu `lastCheckInDate` khác ngày hiện tại, hồi phục `lives` về 5,
  /// cộng thêm 1 `hints` làm quà, và cập nhật lại ngày.
  /// Trả về `true` nếu hôm nay nhận được quà mới, `false` nếu đã điểm danh rồi.
  bool checkDailyReward() {
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    final lastDateStr = _lastCheckInDate != null
        ? _formatDate(DateTime.tryParse(_lastCheckInDate!) ?? DateTime(2000))
        : null;

    if (lastDateStr == null || lastDateStr != todayStr) {
      // Hồi phục mạng về 5 và cộng thêm 1 gợi ý
      _lives = maxLives;
      _hints += 1;
      _lastCheckInDate = now.toIso8601String();

      _save();
      notifyListeners();
      return true;
    }

    return false;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Logic Mạng (Lives)
  // ───────────────────────────────────────────────────────────────────────────
  /// Trừ 1 mạng khi thua (chỉ trừ nếu còn mạng).
  void loseLife() {
    if (_lives > 0) {
      _lives--;
      _save();
      notifyListeners();
    }
  }

  /// Thêm số mạng (tối đa không vượt quá 5).
  void addLives(int amount) {
    if (amount <= 0) return;
    _lives = min(maxLives, _lives + amount);
    _save();
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Logic Gợi ý (Hints)
  // ───────────────────────────────────────────────────────────────────────────
  /// Tiêu hao 1 gợi ý. Trả về true nếu thành công, false nếu hết gợi ý.
  bool useHint() {
    if (_hints > 0) {
      _hints--;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Thêm số gợi ý.
  void addHints(int amount) {
    if (amount <= 0) return;
    _hints += amount;
    _save();
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Logic Mở khóa màn chơi
  // ───────────────────────────────────────────────────────────────────────────
  /// Mở khóa màn tiếp theo khi vượt qua màn chơi hiện tại
  void unlockNextLevel(int completedLevelIndex) {
    final targetLevel = completedLevelIndex + 2; // Level index 0 -> level 2
    if (targetLevel > _unlockedLevels) {
      _unlockedLevels = targetLevel;
      _save();
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Giả lập Xem Quảng Cáo (Rewarded Ad)
  // ───────────────────────────────────────────────────────────────────────────
  /// Giả lập xem quảng cáo có thưởng (3 giây), sau đó gọi [onReward].
  Future<void> showRewardedAd(Function onReward) async {
    await Future.delayed(const Duration(seconds: 3));
    onReward();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper
  // ───────────────────────────────────────────────────────────────────────────
  /// Chuyển đổi DateTime sang dạng chuỗi YYYY-MM-DD để so sánh cùng ngày
  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
