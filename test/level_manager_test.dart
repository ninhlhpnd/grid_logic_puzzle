import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_logic_puzzle/models/enums.dart';
import 'package:grid_logic_puzzle/models/game_level.dart';
import 'package:grid_logic_puzzle/models/position.dart';
import 'package:grid_logic_puzzle/services/level_manager.dart';
import 'package:grid_logic_puzzle/services/player_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  });

  group('Kiểm thử GameLevel.fromJson', () {
    test('Parse Level 1 từ JSON chính xác', () {
      final jsonLevel1 = {
        "id": "level_001",
        "name": "Màn 1: Đi thẳng 3 bước",
        "description": "Tiến thẳng 3 bước về đích",
        "grid": [
          ["W", "W", "W", "W", "W"],
          ["W", "E", "E", "E", "W"],
          ["W", "S", "E", "E", "D"],
          ["W", "E", "E", "E", "W"],
          ["W", "W", "W", "W", "W"]
        ],
        "start_pos": {"x": 1, "y": 2},
        "direction": "right",
        "elevation_map": [
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0]
        ],
        "optimal_commands": 3,
        "max_commands": 6,
        "max_function1_commands": 4,
        "initial_hints": ["moveForward", "moveForward", "moveForward"]
      };

      final level = GameLevel.fromJson(jsonLevel1);

      expect(level.id, "level_001");
      expect(level.name, "Màn 1: Đi thẳng 3 bước");
      expect(level.gridWidth, 5);
      expect(level.gridHeight, 5);
      expect(level.startPos, const Position(1, 2));
      expect(level.startDirection, Direction.right);
      expect(level.optimalCommands, 3);
      expect(level.maxCommandsAllowed, 6);
      expect(level.maxFunction1Commands, 4);
      expect(level.initialHints.length, 3);
      expect(level.initialHints[0], CommandType.moveForward);

      // Kiểm tra cell type
      expect(level.getCellAt(const Position(1, 2))?.type, CellType.start);
      expect(level.getCellAt(const Position(4, 2))?.type, CellType.destination);
      expect(level.getCellAt(const Position(0, 0))?.type, CellType.wall);
      expect(level.getCellAt(const Position(2, 2))?.type, CellType.empty);
      expect(level.getCellAt(const Position(2, 2))?.elevation, 0);
    });

    test('Parse Level 2 có elevation_map (bục cao) chính xác', () {
      final jsonLevel2 = {
        "id": "level_002",
        "name": "Màn 2: Bậc thang leo lên",
        "description": "Bục cao chắn đường",
        "grid": [
          ["W", "W", "W", "W", "W", "W"],
          ["W", "E", "E", "E", "E", "W"],
          ["S", "E", "E", "E", "E", "D"],
          ["W", "W", "W", "W", "W", "W"]
        ],
        "start_pos": {"x": 0, "y": 2},
        "direction": "right",
        "elevation_map": [
          [0, 0, 0, 0, 0, 0],
          [0, 0, 1, 1, 0, 0],
          [0, 0, 1, 1, 0, 0],
          [0, 0, 0, 0, 0, 0]
        ],
        "optimal_commands": 5,
        "max_commands": 10,
        "initial_hints": ["moveForward", "jump", "moveForward"]
      };

      final level = GameLevel.fromJson(jsonLevel2);

      expect(level.id, "level_002");
      expect(level.gridWidth, 6);
      expect(level.gridHeight, 4);
      expect(level.optimalCommands, 5);

      // Ô (2,2) và (3,2) có bục cao 1
      expect(level.getCellAt(const Position(2, 2))?.elevation, 1);
      expect(level.getCellAt(const Position(3, 2))?.elevation, 1);
      // Ô (1,2) ở mặt đất elevation 0
      expect(level.getCellAt(const Position(1, 2))?.elevation, 0);

      // Gợi ý có lệnh jump
      expect(level.initialHints[1], CommandType.jump);
    });
  });

  group('Kiểm thử LevelManager', () {
    test('loadFromString parse danh sách level thành công', () {
      final manager = LevelManager();

      const sampleJson = '''[
        {
          "id": "test_1",
          "name": "Test Màn 1",
          "grid": [["S", "D"]],
          "start_pos": {"x": 0, "y": 0}
        },
        {
          "id": "test_2",
          "name": "Test Màn 2",
          "grid": [["S", "E", "D"]],
          "start_pos": {"x": 0, "y": 0}
        }
      ]''';

      manager.loadFromString(sampleJson);

      expect(manager.isLoaded, isTrue);
      expect(manager.totalLevels, 2);
      expect(manager.getLevel(0).name, "Test Màn 1");
      expect(manager.getLevel(1).name, "Test Màn 2");
    });

    test('Đọc trực tiếp và kiểm tra toàn bộ 100 level trong assets/levels.json', () {
      final file = File('assets/levels.json');
      expect(file.existsSync(), isTrue, reason: 'File assets/levels.json phải tồn tại');

      final content = file.readAsStringSync();
      final List<dynamic> decoded = jsonDecode(content);

      expect(decoded.length, 100, reason: 'Phải có đủ 100 màn chơi trong file JSON');

      // Parse tất cả 100 level không xảy ra lỗi
      final levels = decoded.map((e) => GameLevel.fromJson(e as Map<String, dynamic>)).toList();
      expect(levels.length, 100);

      // Kiểm tra màn 1 và màn 2
      expect(levels[0].id, "level_001");
      expect(levels[1].id, "level_002");
      expect(levels[1].getCellAt(const Position(2, 2))?.elevation, 1);

      // Kiểm tra màn cuối cùng 100
      expect(levels[99].id, "level_100");
    });
  });

  group('Kiểm thử PlayerManager quản lý số Sao (Stars)', () {
    test('Lưu trữ và cập nhật số sao của các màn chơi', () async {
      final player = PlayerManager();
      await player.init();

      // Ban đầu chưa có sao
      expect(player.getLevelStars(0), 0);
      expect(player.totalStarsEarned, 0);

      // Đạt 2 sao ở Màn 1 (index 0)
      player.setLevelStars(0, 2);
      expect(player.getLevelStars(0), 2);
      expect(player.totalStarsEarned, 2);

      // Chơi lại chỉ được 1 sao -> không giảm số sao kỷ lục
      player.setLevelStars(0, 1);
      expect(player.getLevelStars(0), 2);

      // Chơi lại tối ưu đạt 3 sao -> cập nhật lên 3
      player.setLevelStars(0, 3);
      expect(player.getLevelStars(0), 3);
      expect(player.totalStarsEarned, 3);

      // Đạt 2 sao ở Màn 2 (index 1)
      player.setLevelStars(1, 2);
      expect(player.getLevelStars(1), 2);
      expect(player.totalStarsEarned, 5); // 3 + 2 = 5 sao
    });
  });
}
