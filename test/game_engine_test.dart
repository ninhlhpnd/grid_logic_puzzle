import 'package:flutter_test/flutter_test.dart';
import 'package:grid_logic_puzzle/data/levels_data.dart';
import 'package:grid_logic_puzzle/engine/game_engine.dart';
import 'package:grid_logic_puzzle/models/enums.dart';
import 'package:grid_logic_puzzle/models/game_level.dart';
import 'package:grid_logic_puzzle/models/position.dart';

void main() {
  // ─── Helper: tạo level đơn giản 3x3 để test ───────────────────────────
  GameLevel makeSimpleLevel({int maxCmds = 10}) {
    return GameLevel(
      id: 'test',
      gridWidth: 3,
      gridHeight: 3,
      maxCommandsAllowed: maxCmds,
      startPos: const Position(0, 1),
      startDirection: Direction.right,
      mapData: [
        [
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall)
        ],
        [
          const Cell(type: CellType.start),
          const Cell(type: CellType.empty),
          const Cell(type: CellType.destination),
        ],
        [
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall)
        ],
      ],
    );
  }

  GameLevel makeLevelWithEnergy() {
    return GameLevel(
      id: 'test_energy',
      gridWidth: 5,
      gridHeight: 3,
      maxCommandsAllowed: 10,
      startPos: const Position(0, 1),
      startDirection: Direction.right,
      mapData: [
        [
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
        ],
        [
          const Cell(type: CellType.start),
          const Cell(type: CellType.empty),
          const Cell(type: CellType.energy),
          const Cell(type: CellType.empty),
          const Cell(type: CellType.destination),
        ],
        [
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
          const Cell(type: CellType.wall),
        ],
      ],
    );
  }

  // ─── Position & Direction ──────────────────────────────────────────────
  group('Kiểm thử Position & Direction', () {
    test('Position: phép cộng và so sánh bằng', () {
      const p1 = Position(1, 2);
      const p2 = Position(3, 4);
      expect(p1 + p2, equals(const Position(4, 6)));
      expect(p2 - p1, equals(const Position(2, 2)));
      expect(p1 == const Position(1, 2), isTrue);
      expect(p1.hashCode, equals(const Position(1, 2).hashCode));
    });

    test('Direction: logic quay 90 độ và vector delta', () {
      expect(Direction.up.turnLeft(), equals(Direction.left));
      expect(Direction.left.turnLeft(), equals(Direction.down));
      expect(Direction.down.turnLeft(), equals(Direction.right));
      expect(Direction.right.turnLeft(), equals(Direction.up));

      expect(Direction.up.turnRight(), equals(Direction.right));
      expect(Direction.right.turnRight(), equals(Direction.down));
      expect(Direction.down.turnRight(), equals(Direction.left));
      expect(Direction.left.turnRight(), equals(Direction.up));

      expect(Direction.up.delta, equals(const Position(0, -1)));
      expect(Direction.down.delta, equals(const Position(0, 1)));
      expect(Direction.left.delta, equals(const Position(-1, 0)));
      expect(Direction.right.delta, equals(const Position(1, 0)));
    });
  });

  // ─── Cell & GameLevel ──────────────────────────────────────────────────
  group('Kiểm thử Cell & GameLevel', () {
    test('Cell: withType giữ nguyên elevation', () {
      const c = Cell(type: CellType.energy, elevation: 1);
      final c2 = c.withType(CellType.empty);
      expect(c2.type, equals(CellType.empty));
      expect(c2.elevation, equals(1));
    });

    test('GameLevel: totalEnergyCount đếm đúng', () {
      final level = makeLevelWithEnergy();
      expect(level.totalEnergyCount, equals(1));
    });

    test('GameLevel: cloneMapData không thay đổi bản gốc', () {
      final level = makeLevelWithEnergy();
      final clone = level.cloneMapData();
      clone[1][2] = const Cell(type: CellType.empty, elevation: 0);
      expect(level.mapData[1][2].type, equals(CellType.energy));
    });
  });

  // ─── GameEngine: Quản lý lệnh ──────────────────────────────────────────
  group('Kiểm thử GameEngine - Quản lý lệnh', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine(
        level: makeSimpleLevel(),
        stepDelay: Duration.zero,
      );
    });

    test('Thêm, xóa và xóa tất cả lệnh', () {
      expect(engine.commandList.isEmpty, isTrue);
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.turnRight);
      expect(engine.commandList.length, equals(2));
      engine.removeCommandAt(0);
      expect(engine.commandList.length, equals(1));
      expect(engine.commandList.first, equals(CommandType.turnRight));
      engine.clearCommands();
      expect(engine.commandList.isEmpty, isTrue);
    });

    test('Không cho phép thêm quá maxCommandsAllowed', () {
      final e = GameEngine(
          level: makeSimpleLevel(maxCmds: 2), stepDelay: Duration.zero);
      expect(e.addCommand(CommandType.moveForward), isTrue);
      expect(e.addCommand(CommandType.moveForward), isTrue);
      expect(e.addCommand(CommandType.moveForward), isFalse);
      expect(e.commandList.length, equals(2));
    });

    test('function1List: thêm, xóa, không cho callFunction1 bên trong', () {
      expect(engine.addToFunction1(CommandType.moveForward), isTrue);
      expect(engine.addToFunction1(CommandType.callFunction1), isFalse);
      expect(engine.function1List.length, equals(1));
      engine.removeFunction1At(0);
      expect(engine.function1List.isEmpty, isTrue);
    });
  });

  // ─── GameEngine: Thực thi lệnh ─────────────────────────────────────────
  group('Kiểm thử GameEngine - Thực thi & Logic Game', () {
    test('Di chuyển thẳng và chiến thắng (không cần energy)', () async {
      final engine = GameEngine(
        level: makeSimpleLevel(),
        stepDelay: Duration.zero,
      );
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.moveForward);
      await engine.runCommands();
      expect(engine.isWon, isTrue);
      expect(engine.botPosition, equals(const Position(2, 1)));
    });

    test('Di chuyển thẳng, nhặt energy và chiến thắng', () async {
      final engine = GameEngine(
        level: makeLevelWithEnergy(),
        stepDelay: Duration.zero,
      );
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.collectEnergy);
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.moveForward);
      await engine.runCommands();
      expect(engine.isWon, isTrue);
      expect(engine.collectedEnergyCount, equals(1));
    });

    test('Va chạm vào tường → isLost = true', () async {
      final level = GameLevel(
        id: 'wall_test',
        gridWidth: 3,
        gridHeight: 3,
        maxCommandsAllowed: 10,
        startPos: const Position(0, 1),
        startDirection: Direction.right,
        mapData: [
          [
            const Cell(type: CellType.empty),
            const Cell(type: CellType.empty),
            const Cell(type: CellType.empty)
          ],
          [
            const Cell(type: CellType.start),
            const Cell(type: CellType.wall),
            const Cell(type: CellType.empty),
          ],
          [
            const Cell(type: CellType.empty),
            const Cell(type: CellType.empty),
            const Cell(type: CellType.destination)
          ],
        ],
      );
      final engine = GameEngine(level: level, stepDelay: Duration.zero);
      engine.addCommand(CommandType.moveForward);
      await engine.runCommands();
      expect(engine.isLost, isTrue);
    });

    test('Đi ra ngoài bản đồ → isLost = true', () async {
      final engine = GameEngine(
        level: makeSimpleLevel(),
        stepDelay: Duration.zero,
      );
      engine.addCommand(CommandType.turnLeft); // quay lên
      engine.addCommand(CommandType.moveForward); // tiến lên → wall → lost
      await engine.runCommands();
      expect(engine.isLost, isTrue);
    });

    test('resetLevel khôi phục đầy đủ trạng thái', () async {
      final level = makeLevelWithEnergy();
      final engine = GameEngine(level: level, stepDelay: Duration.zero);
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.moveForward);
      engine.addCommand(CommandType.collectEnergy);
      await engine.runCommands();
      expect(engine.collectedEnergyCount, equals(1));
      engine.resetLevel();
      expect(engine.botPosition, equals(level.startPos));
      expect(engine.collectedEnergyCount, equals(0));
      expect(engine.isWon, isFalse);
      expect(engine.isLost, isFalse);
      expect(
        engine.getRuntimeCellAt(const Position(2, 1))?.type,
        equals(CellType.energy),
      );
    });

    test('Jump lên bục elevation+1 thành công', () async {
      final level = GameLevel(
        id: 'jump_test',
        gridWidth: 3,
        gridHeight: 1,
        maxCommandsAllowed: 5,
        startPos: const Position(0, 0),
        startDirection: Direction.right,
        mapData: [
          [
            const Cell(type: CellType.start, elevation: 0),
            const Cell(type: CellType.empty, elevation: 1),
            const Cell(type: CellType.destination, elevation: 1),
          ],
        ],
      );
      final engine = GameEngine(level: level, stepDelay: Duration.zero);
      engine.addCommand(CommandType.jump); // lên bục elevation 1
      engine.addCommand(CommandType.moveForward); // tiến trên bục
      await engine.runCommands();
      expect(engine.isWon, isTrue);
      expect(engine.botElevation, equals(1));
    });

    test('callFunction1 thực thi function1List đúng thứ tự', () async {
      final engine = GameEngine(
        level: makeSimpleLevel(),
        stepDelay: Duration.zero,
      );
      engine.addToFunction1(CommandType.moveForward);
      engine.addToFunction1(CommandType.moveForward);
      engine.addCommand(CommandType.callFunction1);
      await engine.runCommands();
      expect(engine.isWon, isTrue);
    });
  });

  // ─── sampleLevels data ─────────────────────────────────────────────────
  group('Kiểm thử sampleLevels', () {
    test('Có đúng 7 màn', () {
      expect(sampleLevels.length, equals(7));
    });

    test('Level 6 có ô elevation > 0', () {
      final level6 = sampleLevels[5];
      bool hasElevation = false;
      for (final row in level6.mapData) {
        for (final cell in row) {
          if (cell.elevation > 0) hasElevation = true;
        }
      }
      expect(hasElevation, isTrue);
    });
  });
}
