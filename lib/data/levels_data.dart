import '../models/enums.dart';
import '../models/game_level.dart';
import '../models/position.dart';

// ─── Helpers tạo Cell nhanh (lowerCamelCase theo Dart convention) ─────────
const Cell cEmpty = Cell(type: CellType.empty,       elevation: 0); // trống đất
const Cell cWall  = Cell(type: CellType.wall,         elevation: 0); // tường
const Cell cStart = Cell(type: CellType.start,        elevation: 0); // xuất phát
const Cell cDest  = Cell(type: CellType.destination,  elevation: 0); // đích
const Cell cEnergy= Cell(type: CellType.energy,       elevation: 0); // năng lượng

// Ô bục cao (elevation = 1)
const Cell cHigh  = Cell(type: CellType.empty,        elevation: 1); // bục trống
const Cell cEnergyHigh = Cell(type: CellType.energy,  elevation: 1); // pin trên bục
const Cell cDestHigh   = Cell(type: CellType.destination, elevation: 1); // đích trên bục

/// Danh sách 7 màn chơi mẫu với độ khó tăng dần
final List<GameLevel> sampleLevels = [
  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 1: Đi thẳng 3 bước (Dạy làm quen nút Tiến)
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_01',
    name: 'Màn 1: Đi thẳng 3 bước',
    description: 'Làm quen nút Tiến lên: Tiến thẳng 3 bước để về đích!',
    gridWidth: 5,
    gridHeight: 5,
    maxCommandsAllowed: 6,
    maxFunction1Commands: 4,
    startPos: Position(1, 2),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.moveForward,
      CommandType.moveForward,
    ],
    mapData: [
      [cWall, cWall,   cWall,  cWall, cWall],
      [cWall, cEmpty,  cEmpty, cEmpty,cWall],
      [cWall, cStart,  cEmpty, cEmpty,cDest],
      [cWall, cEmpty,  cEmpty, cEmpty,cWall],
      [cWall, cWall,   cWall,  cWall, cWall],
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 2: Cần rẽ trái, rẽ phải để tránh 2 ô tường
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_02',
    name: 'Màn 2: Tránh chướng ngại vật',
    description: 'Dùng Quay Trái & Phải để vượt qua 2 bức tường!',
    gridWidth: 5,
    gridHeight: 5,
    maxCommandsAllowed: 16,
    maxFunction1Commands: 6,
    startPos: Position(0, 1),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.turnRight,
      CommandType.moveForward,
    ],
    mapData: [
      [cWall,  cWall,  cWall,  cWall,  cWall],
      [cStart, cEmpty, cWall,  cEmpty, cDest],
      [cEmpty, cEmpty, cWall,  cEmpty, cEmpty],
      [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
      [cWall,  cWall,  cWall,  cWall,  cWall],
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 3: Nhặt 1 viên pin trước khi tới đích
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_03',
    name: 'Màn 3: Thu thập năng lượng',
    description: 'Nhặt 1 viên pin năng lượng trên đường trước khi tới ô Đích!',
    gridWidth: 5,
    gridHeight: 5,
    maxCommandsAllowed: 8,
    maxFunction1Commands: 6,
    startPos: Position(0, 2),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.moveForward,
      CommandType.collectEnergy,
    ],
    mapData: [
      [cWall,  cWall,   cWall,   cWall,  cWall],
      [cWall,  cEmpty,  cEmpty,  cEmpty, cWall],
      [cStart, cEmpty,  cEnergy, cEmpty, cDest],
      [cWall,  cEmpty,  cEmpty,  cEmpty, cWall],
      [cWall,  cWall,   cWall,   cWall,  cWall],
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 4: Bản đồ 6x6 đường zíc zắc & 2 viên pin
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_04',
    name: 'Màn 4: Đường zíc zắc',
    description: 'Bản đồ 6x6 uốn lượn: Thu thập đủ 2 viên pin để chiến thắng!',
    gridWidth: 6,
    gridHeight: 6,
    maxCommandsAllowed: 18,
    maxFunction1Commands: 8,
    startPos: Position(1, 1),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.moveForward,
      CommandType.collectEnergy,
    ],
    mapData: [
      [cWall, cWall,   cWall,    cWall,   cWall, cWall],
      [cWall, cStart,  cEmpty,   cEnergy, cWall, cWall],
      [cWall, cWall,   cWall,    cEmpty,  cWall, cWall],
      [cWall, cWall,   cEnergy,  cEmpty,  cWall, cWall],
      [cWall, cWall,   cEmpty,   cWall,   cWall, cWall],
      [cWall, cWall,   cDest,    cWall,   cWall, cWall],
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 5: Mê cung hẹp, giới hạn 12 lệnh
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_05',
    name: 'Màn 5: Mê cung hẹp',
    description: 'Mê cung hẹp với giới hạn nghiêm ngặt: Tối đa đúng 12 lệnh!',
    gridWidth: 6,
    gridHeight: 6,
    maxCommandsAllowed: 12,
    maxFunction1Commands: 6,
    startPos: Position(1, 1),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.moveForward,
      CommandType.collectEnergy,
    ],
    mapData: [
      [cWall,  cWall,  cWall,  cWall,  cWall,  cWall],
      [cWall,  cStart, cEmpty, cEnergy,cEmpty, cWall],
      [cWall,  cEmpty, cWall,  cEmpty, cEmpty, cWall],
      [cWall,  cEmpty, cWall,  cWall,  cDest,  cWall],
      [cWall,  cEmpty, cEmpty, cEmpty, cWall,  cWall],
      [cWall,  cWall,  cWall,  cWall,  cWall,  cWall],
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 6: Bục cao — học lệnh Jump (elevation)
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_06',
    name: 'Màn 6: Bậc thang leo lên',
    description: 'Bục cao đang chặn đường! Dùng lệnh "Nhảy" để leo lên rồi tiến về đích.',
    gridWidth: 6,
    gridHeight: 4,
    maxCommandsAllowed: 10,
    maxFunction1Commands: 6,
    startPos: Position(0, 2),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.jump,
      CommandType.moveForward,
    ],
    mapData: [
      [cWall,  cWall,  cWall,  cWall,  cWall,  cWall],
      [cWall,  cEmpty, cHigh,  cHigh,  cEmpty, cWall],
      [cStart, cEmpty, cHigh,  cHigh,  cEmpty, cDest],
      [cWall,  cWall,  cWall,  cWall,  cWall,  cWall],
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // LEVEL 7: Bục cao + pin + dùng F1 lặp lại
  // ─────────────────────────────────────────────────────────────────────────
  const GameLevel(
    id: 'level_07',
    name: 'Màn 7: Bục cao & Hàm F1',
    description: 'Vừa leo bục, vừa nhặt pin trên bục cao! Dùng hàm F1 để tối ưu số lệnh.',
    gridWidth: 7,
    gridHeight: 5,
    maxCommandsAllowed: 14,
    maxFunction1Commands: 8,
    startPos: Position(0, 2),
    startDirection: Direction.right,
    initialHints: [
      CommandType.moveForward,
      CommandType.jump,
      CommandType.turnLeft,
    ],
    mapData: [
      [cWall,  cWall,       cWall,      cWall,       cWall,      cWall, cWall],
      [cWall,  cEmpty,      cHigh,      cEnergyHigh, cHigh,      cEmpty,cWall],
      [cStart, cEmpty,      cHigh,      cEmpty,      cHigh,      cEmpty,cDest],
      [cWall,  cEmpty,      cWall,      cEmpty,      cWall,      cEmpty,cWall],
      [cWall,  cWall,       cWall,      cWall,       cWall,      cWall, cWall],
    ],
  ),
];
