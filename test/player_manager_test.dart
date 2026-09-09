import 'package:flutter_test/flutter_test.dart';
import 'package:grid_logic_puzzle/services/player_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  });

  group('PlayerManager Tests', () {
    test('Khởi tạo ban đầu với các giá trị mặc định chính xác', () async {
      final manager = PlayerManager();
      await manager.init();

      // Mặc định: 5 mạng, 3 gợi ý ban đầu + 1 gợi ý từ checkDailyReward ngày đầu = 4 gợi ý
      expect(manager.lives, 5);
      expect(manager.hints, 4); // 3 mặc định + 1 điểm danh lần đầu
      expect(manager.unlockedLevels, 1);
      expect(manager.hasLives, isTrue);
      expect(manager.lastCheckInDate, isNotNull);
      expect(manager.justClaimedDailyReward, isTrue);
    });

    test('Logic trừ mạng (loseLife) không âm', () async {
      final manager = PlayerManager();
      await manager.init();

      expect(manager.lives, 5);
      manager.loseLife();
      expect(manager.lives, 4);

      manager.loseLife();
      manager.loseLife();
      manager.loseLife();
      manager.loseLife();
      expect(manager.lives, 0);
      expect(manager.hasLives, isFalse);

      // Thua tiếp khi lives == 0 không bị số âm
      manager.loseLife();
      expect(manager.lives, 0);
    });

    test('Logic cộng mạng (addLives) không vượt quá 5', () async {
      final manager = PlayerManager();
      await manager.init();

      // Giảm về 0
      for (int i = 0; i < 5; i++) {
        manager.loseLife();
      }
      expect(manager.lives, 0);

      // Xem quảng cáo nhận 3 mạng
      manager.addLives(3);
      expect(manager.lives, 3);

      // Nhận tiếp 3 mạng nữa -> bị chặn tối đa 5 mạng
      manager.addLives(3);
      expect(manager.lives, 5);
    });

    test('Logic gợi ý (useHint & addHints)', () async {
      final manager = PlayerManager();
      await manager.init();

      final initialHints = manager.hints;
      expect(initialHints > 0, isTrue);

      // Dùng gợi ý thành công
      final used1 = manager.useHint();
      expect(used1, isTrue);
      expect(manager.hints, initialHints - 1);

      // Dùng hết gợi ý
      while (manager.hints > 0) {
        manager.useHint();
      }
      expect(manager.hints, 0);

      // Dùng khi hints == 0 -> false
      final usedWhenEmpty = manager.useHint();
      expect(usedWhenEmpty, isFalse);
      expect(manager.hints, 0);

      // Xem quảng cáo nhận 1 gợi ý
      manager.addHints(1);
      expect(manager.hints, 1);
    });

    test('Logic Điểm danh (checkDailyReward): Không nhận quà 2 lần trong cùng ngày', () async {
      final manager = PlayerManager();
      await manager.init();

      // Đã nhận trong init() rồi
      final claimedAgain = manager.checkDailyReward();
      expect(claimedAgain, isFalse);
    });

    test('Logic Mở khóa màn chơi (unlockNextLevel)', () async {
      final manager = PlayerManager();
      await manager.init();

      expect(manager.unlockedLevels, 1);

      // Thắng màn 1 (index 0) -> mở màn 2
      manager.unlockNextLevel(0);
      expect(manager.unlockedLevels, 2);

      // Thắng lại màn 1 -> không bị lùi level
      manager.unlockNextLevel(0);
      expect(manager.unlockedLevels, 2);

      // Thắng màn 2 (index 1) -> mở màn 3
      manager.unlockNextLevel(1);
      expect(manager.unlockedLevels, 3);
    });

    test('Logic Giả lập quảng cáo (showRewardedAd)', () async {
      final manager = PlayerManager();
      bool rewarded = false;

      // Chạy showRewardedAd
      final future = manager.showRewardedAd(() {
        rewarded = true;
      });

      expect(rewarded, isFalse);
      await future;
      expect(rewarded, isTrue);
    });
  });
}
