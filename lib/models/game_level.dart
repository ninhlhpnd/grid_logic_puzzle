import 'enums.dart';
import 'position.dart';

/// Đại diện cho một ô đơn trên lưới trò chơi.
/// Mỗi ô có loại ([CellType]) và độ cao ([elevation]).
///
/// - [elevation] = 0: mặt đất bình thường.
/// - [elevation] = 1: bục cao 1 tầng (robot cần lệnh `jump` để leo lên).
/// - [elevation] >= 2: có thể mở rộng sau này.
class Cell {
  /// Loại ô: trống, tường, xuất phát, đích, năng lượng.
  final CellType type;

  /// Độ cao của ô (mặc định 0 = mặt đất).
  final int elevation;

  const Cell({
    required this.type,
    this.elevation = 0,
  });

  /// Shorthand tạo ô trống với độ cao tùy chỉnh
  const Cell.empty({this.elevation = 0}) : type = CellType.empty;

  /// Shorthand tạo ô tường
  const Cell.wall({this.elevation = 0}) : type = CellType.wall;

  /// Tạo bản sao Cell với type mới (dùng khi nhặt năng lượng)
  Cell withType(CellType newType) => Cell(type: newType, elevation: elevation);

  /// Kiểm tra ô có phải chướng ngại vật không
  bool get isObstacle => type == CellType.wall;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          elevation == other.elevation;

  @override
  int get hashCode => type.hashCode ^ elevation.hashCode;

  @override
  String toString() => 'Cell(type: $type, elevation: $elevation)';
}

/// Đại diện cho cấu hình của một màn chơi trong game (Grid Logic Puzzle).
class GameLevel {
  /// Mã định danh duy nhất của màn chơi (ví dụ: "level_1", "stage_01")
  final String id;

  /// Số cột của lưới bản đồ (chiều rộng)
  final int gridWidth;

  /// Số hàng của lưới bản đồ (chiều cao)
  final int gridHeight;

  /// Bản đồ tĩnh của màn chơi: ma trận 2 chiều dạng `List<List<Cell>>`.
  /// Mỗi ô chứa loại ô VÀ độ cao (elevation).
  /// Quy ước truy xuất: `mapData[y][x]` tương ứng với hàng y và cột x.
  final List<List<Cell>> mapData;

  /// Số lượng lệnh tối đa trong danh sách lệnh chính (main queue)
  final int maxCommandsAllowed;

  /// Số lượng lệnh tối đa trong hàm con F1
  final int maxFunction1Commands;

  /// Vị trí xuất phát ban đầu của Robot trên lưới
  final Position startPos;

  /// Hướng nhìn ban đầu của Robot khi bắt đầu màn chơi
  final Direction startDirection;

  /// Tên màn chơi (tùy chọn)
  final String? name;

  /// Mô tả ngắn về mục tiêu màn chơi
  final String? description;

  /// Danh sách gợi ý các bước đi đầu tiên cho màn chơi (thường là 3 bước)
  final List<CommandType> initialHints;

  /// Số lệnh tối ưu để hoàn thành màn chơi đạt 3 sao (tùy chọn)
  final int? optimalCommands;

  const GameLevel({
    required this.id,
    required this.gridWidth,
    required this.gridHeight,
    required this.mapData,
    required this.maxCommandsAllowed,
    this.maxFunction1Commands = 8,
    required this.startPos,
    required this.startDirection,
    this.name,
    this.description,
    this.initialHints = const [
      CommandType.moveForward,
      CommandType.moveForward,
      CommandType.moveForward,
    ],
    this.optimalCommands,
  });

  /// Factory chuyển đổi dữ liệu Map JSON thành đối tượng [GameLevel].
  ///
  /// Hỗ trợ linh hoạt cấu trúc:
  /// - `grid`: ma trận 2D chứa chuỗi ("W"/"wall", "E"/"empty", "S"/"start", "D"/"destination", "P"/"energy").
  /// - `elevation_map`: ma trận 2D chứa độ cao từng ô (int, mặc định 0).
  /// - `start_pos`: map `{"x": 0, "y": 1}` hoặc tự động dò tìm vị trí ô "S" nếu thiếu.
  /// - `direction`: chuỗi "up", "down", "left", "right" (mặc định "right").
  /// - `optimal_commands`: số lệnh tối ưu (int).
  /// - `initial_hints`: mảng tên lệnh gợi ý (ví dụ `["moveForward", "jump", ...]`).
  factory GameLevel.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String? ?? 'level_${DateTime.now().millisecondsSinceEpoch}';
    final String? name = json['name'] as String?;
    final String? description = json['description'] as String?;

    final List<dynamic> rawGrid = json['grid'] as List<dynamic>? ?? [];
    final List<dynamic>? rawElevation = json['elevation_map'] as List<dynamic>?;

    final int height = rawGrid.length;
    final int width = height > 0 ? (rawGrid[0] as List<dynamic>).length : 0;

    Position? detectedStartPos;

    // Parse ma trận ô kết hợp với elevation_map
    final List<List<Cell>> mapData = List.generate(height, (y) {
      final row = rawGrid[y] as List<dynamic>;
      final elevRow = (rawElevation != null && y < rawElevation.length)
          ? rawElevation[y] as List<dynamic>?
          : null;

      return List.generate(width, (x) {
        final cellStr = (x < row.length ? row[x].toString() : 'E').toLowerCase().trim();
        final int elevation = (elevRow != null && x < elevRow.length)
            ? (int.tryParse(elevRow[x].toString()) ?? 0)
            : 0;

        CellType type = CellType.empty;
        switch (cellStr) {
          case 'w':
          case 'wall':
            type = CellType.wall;
            break;
          case 's':
          case 'start':
            type = CellType.start;
            detectedStartPos = Position(x, y);
            break;
          case 'd':
          case 'destination':
          case 'dest':
          case 'finish':
            type = CellType.destination;
            break;
          case 'p':
          case 'energy':
          case 'pin':
          case 'battery':
            type = CellType.energy;
            break;
          case 'e':
          case 'empty':
          default:
            type = CellType.empty;
            break;
        }

        return Cell(type: type, elevation: elevation);
      });
    });

    // Xác định startPos
    Position startPos = const Position(0, 0);
    if (json['start_pos'] != null && json['start_pos'] is Map) {
      final sp = json['start_pos'] as Map;
      startPos = Position(
        (sp['x'] as num?)?.toInt() ?? 0,
        (sp['y'] as num?)?.toInt() ?? 0,
      );
    } else if (detectedStartPos != null) {
      startPos = detectedStartPos!;
    }

    // Xác định startDirection
    Direction startDirection = Direction.right;
    final dirStr = (json['direction'] as String?)?.toLowerCase().trim();
    switch (dirStr) {
      case 'up':
        startDirection = Direction.up;
        break;
      case 'down':
        startDirection = Direction.down;
        break;
      case 'left':
        startDirection = Direction.left;
        break;
      case 'right':
      default:
        startDirection = Direction.right;
        break;
    }

    final int maxCommandsAllowed =
        (json['max_commands'] as num?)?.toInt() ?? (json['max_commands_allowed'] as num?)?.toInt() ?? 12;
    final int maxFunction1Commands =
        (json['max_function1_commands'] as num?)?.toInt() ?? 8;
    final int? optimalCommands = (json['optimal_commands'] as num?)?.toInt();

    // Parse initialHints
    final List<CommandType> initialHints = [];
    if (json['initial_hints'] is List) {
      for (final h in json['initial_hints'] as List) {
        final hStr = h.toString().toLowerCase().trim();
        switch (hStr) {
          case 'moveforward':
          case 'forward':
          case 'move':
            initialHints.add(CommandType.moveForward);
            break;
          case 'turnleft':
          case 'left':
            initialHints.add(CommandType.turnLeft);
            break;
          case 'turnright':
          case 'right':
            initialHints.add(CommandType.turnRight);
            break;
          case 'collectenergy':
          case 'collect':
          case 'pick':
            initialHints.add(CommandType.collectEnergy);
            break;
          case 'jump':
            initialHints.add(CommandType.jump);
            break;
          case 'callfunction1':
          case 'f1':
            initialHints.add(CommandType.callFunction1);
            break;
        }
      }
    }

    return GameLevel(
      id: id,
      name: name,
      description: description,
      gridWidth: width,
      gridHeight: height,
      mapData: mapData,
      startPos: startPos,
      startDirection: startDirection,
      maxCommandsAllowed: maxCommandsAllowed,
      maxFunction1Commands: maxFunction1Commands,
      optimalCommands: optimalCommands,
      initialHints: initialHints.isNotEmpty
          ? initialHints
          : const [
              CommandType.moveForward,
              CommandType.moveForward,
              CommandType.moveForward,
            ],
    );
  }

  /// Kiểm tra tọa độ [pos] có nằm trong ranh giới lưới hay không
  bool isWithinBounds(Position pos) {
    return pos.x >= 0 && pos.x < gridWidth && pos.y >= 0 && pos.y < gridHeight;
  }

  /// Lấy Cell tại vị trí [pos]. Trả về null nếu nằm ngoài bản đồ.
  Cell? getCellAt(Position pos) {
    if (!isWithinBounds(pos)) return null;
    return mapData[pos.y][pos.x];
  }

  /// Tổng số vật phẩm năng lượng (`CellType.energy`) có trong màn chơi ban đầu
  int get totalEnergyCount {
    int count = 0;
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (mapData[y][x].type == CellType.energy) {
          count++;
        }
      }
    }
    return count;
  }

  /// Tạo bản sao sâu (deep copy) của `mapData` để GameEngine sử dụng trong lúc chạy,
  /// tránh làm thay đổi dữ liệu gốc khi bot thu thập vật phẩm.
  List<List<Cell>> cloneMapData() {
    return List<List<Cell>>.generate(
      gridHeight,
      (y) => List<Cell>.from(mapData[y]),
      growable: false,
    );
  }
}
