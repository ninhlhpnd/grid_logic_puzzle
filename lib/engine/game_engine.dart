import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/game_level.dart';
import '../models/position.dart';

/// GameEngine: Bộ não điều khiển toàn bộ logic trạng thái và vòng lặp trò chơi.
/// Kế thừa [ChangeNotifier] để thông báo thay đổi đến UI mà không cần thư viện ngoài.
///
/// **Hệ thống lệnh 2 tầng:**
/// - [commandList]: Danh sách lệnh chính mà người chơi lập trình.
/// - [function1List]: Hàm con F1 — khi gặp `callFunction1`, engine chạy toàn bộ lệnh F1.
///   (Bảo vệ vòng lặp vô hạn: nếu F1 chứa `callFunction1`, lệnh đó sẽ bị bỏ qua)
///
/// **Hệ thống độ cao (Elevation):**
/// - Lệnh `moveForward`: chỉ thành công nếu ô tiếp theo có CÙNG elevation.
/// - Lệnh `jump`: nhảy sang ô tiếp theo nếu elevation = hiện tại + 1 (nhảy lên)
///   hoặc bất kỳ ô thấp hơn (nhảy xuống).
class GameEngine extends ChangeNotifier {
  /// Màn chơi hiện tại
  late GameLevel currentLevel;

  /// Vị trí hiện tại của Robot trên lưới
  late Position botPosition;

  /// Hướng nhìn hiện tại của Robot
  late Direction botDirection;

  /// Số lượng năng lượng Robot đã thu thập trong lượt chạy hiện tại
  int collectedEnergyCount = 0;

  /// Trạng thái đang thực thi chuỗi lệnh hay đang dừng
  bool isExecuting = false;

  /// Trạng thái chiến thắng màn chơi
  bool isWon = false;

  /// Trạng thái thua cuộc
  bool isLost = false;

  /// Danh sách lệnh chính do người chơi lập trình
  final List<CommandType> commandList = [];

  /// Hàm con F1: danh sách lệnh bổ sung được gọi bởi `callFunction1`
  final List<CommandType> function1List = [];

  /// Bản đồ runtime theo dõi trạng thái các ô (ô energy sau khi nhặt → empty)
  late List<List<Cell>> _runtimeMapData;

  /// Getter bản đồ runtime để UI hiển thị chính xác trạng thái các ô còn lại
  List<List<Cell>> get runtimeMapData => _runtimeMapData;

  /// Vị trí lệnh đang thực thi trong [commandList] (để highlight trên UI)
  int? currentCommandIndex;

  /// Vị trí lệnh đang thực thi bên trong [function1List] (để highlight F1 trên UI)
  int? currentF1CommandIndex;

  /// Thông báo trạng thái chi tiết
  String? statusMessage;

  /// Thời gian chờ giữa mỗi bước (mặc định 400ms)
  final Duration stepDelay;

  /// Khởi tạo GameEngine với một màn chơi xác định
  GameEngine({
    required GameLevel level,
    this.stepDelay = const Duration(milliseconds: 400),
  }) {
    loadLevel(level);
  }

  // ─── Level Management ────────────────────────────────────────────────────

  /// Nạp một màn chơi mới và khởi tạo lại toàn bộ trạng thái
  void loadLevel(GameLevel level) {
    currentLevel = level;
    commandList.clear();
    function1List.clear();
    resetLevel();
  }

  /// Đưa Robot và vật phẩm về trạng thái ban đầu màn chơi (giữ nguyên commandList và function1List)
  void resetLevel() {
    botPosition = currentLevel.startPos;
    botDirection = currentLevel.startDirection;
    collectedEnergyCount = 0;
    isExecuting = false;
    isWon = false;
    isLost = false;
    currentCommandIndex = null;
    currentF1CommandIndex = null;
    statusMessage = 'Màn chơi đã được đặt lại.';
    _runtimeMapData = currentLevel.cloneMapData();
    notifyListeners();
  }

  // ─── Main Command Queue ──────────────────────────────────────────────────

  /// Thêm lệnh vào danh sách chính [commandList].
  /// Trả về `false` nếu đang thực thi hoặc đã đạt giới hạn.
  bool addCommand(CommandType cmd) {
    if (isExecuting) return false;
    if (commandList.length >= currentLevel.maxCommandsAllowed) {
      statusMessage =
          'Đã đạt giới hạn tối đa ${currentLevel.maxCommandsAllowed} lệnh!';
      notifyListeners();
      return false;
    }
    commandList.add(cmd);
    statusMessage = null;
    notifyListeners();
    return true;
  }

  /// Xóa lệnh tại [index] trong [commandList]
  void removeCommandAt(int index) {
    if (isExecuting) return;
    if (index >= 0 && index < commandList.length) {
      commandList.removeAt(index);
      statusMessage = null;
      notifyListeners();
    }
  }

  /// Xóa toàn bộ [commandList]
  void clearCommands() {
    if (isExecuting) return;
    commandList.clear();
    statusMessage = null;
    notifyListeners();
  }

  // ─── Function 1 Queue ───────────────────────────────────────────────────

  /// Thêm lệnh vào hàm con [function1List].
  /// Lưu ý: `callFunction1` bên trong F1 sẽ không được thêm (tránh đệ quy vô hạn).
  bool addToFunction1(CommandType cmd) {
    if (isExecuting) return false;
    // Bảo vệ: không cho phép callFunction1 bên trong F1 (tránh vòng lặp vô hạn)
    if (cmd == CommandType.callFunction1) {
      statusMessage = 'Không thể gọi F1 bên trong hàm F1!';
      notifyListeners();
      return false;
    }
    if (function1List.length >= currentLevel.maxFunction1Commands) {
      statusMessage =
          'Đã đạt giới hạn ${currentLevel.maxFunction1Commands} lệnh trong F1!';
      notifyListeners();
      return false;
    }
    function1List.add(cmd);
    statusMessage = null;
    notifyListeners();
    return true;
  }

  /// Xóa lệnh tại [index] trong [function1List]
  void removeFunction1At(int index) {
    if (isExecuting) return;
    if (index >= 0 && index < function1List.length) {
      function1List.removeAt(index);
      statusMessage = null;
      notifyListeners();
    }
  }

  /// Xóa toàn bộ [function1List]
  void clearFunction1() {
    if (isExecuting) return;
    function1List.clear();
    statusMessage = null;
    notifyListeners();
  }

  // ─── Execution ──────────────────────────────────────────────────────────

  /// Chạy chuỗi lệnh do người chơi lập trình (bất đồng bộ).
  /// Duyệt qua [commandList]; khi gặp `callFunction1` sẽ mở rộng và chạy [function1List].
  Future<void> runCommands() async {
    if (isExecuting || commandList.isEmpty) return;

    // Reset trạng thái về đầu màn trước khi chạy
    botPosition = currentLevel.startPos;
    botDirection = currentLevel.startDirection;
    collectedEnergyCount = 0;
    _runtimeMapData = currentLevel.cloneMapData();
    isExecuting = true;
    isWon = false;
    isLost = false;
    currentCommandIndex = null;
    currentF1CommandIndex = null;
    statusMessage = 'Đang thực thi chương trình...';
    notifyListeners();

    for (int i = 0; i < commandList.length; i++) {
      currentCommandIndex = i;
      final CommandType cmd = commandList[i];

      if (cmd == CommandType.callFunction1) {
        // Gọi hàm F1: thực thi từng lệnh trong function1List
        await _executeFunction1();
      } else {
        _executeSingleCommand(cmd, isInsideF1: false);
        notifyListeners();
        await Future.delayed(stepDelay);
      }

      if (isLost) break;
    }

    // Kết thúc: kiểm tra điều kiện chiến thắng
    if (!isLost) {
      _checkWinCondition();
    }

    isExecuting = false;
    currentCommandIndex = null;
    currentF1CommandIndex = null;
    notifyListeners();
  }

  /// Thực thi toàn bộ lệnh trong [function1List].
  Future<void> _executeFunction1() async {
    if (function1List.isEmpty) {
      statusMessage = 'Hàm F1 trống!';
      notifyListeners();
      await Future.delayed(stepDelay);
      return;
    }

    for (int j = 0; j < function1List.length; j++) {
      currentF1CommandIndex = j;
      final CommandType f1Cmd = function1List[j];

      // callFunction1 bên trong F1 bị bỏ qua (tránh đệ quy vô hạn)
      if (f1Cmd == CommandType.callFunction1) continue;

      _executeSingleCommand(f1Cmd, isInsideF1: true);
      notifyListeners();
      await Future.delayed(stepDelay);

      if (isLost) break;
    }

    currentF1CommandIndex = null;
  }

  // ─── Core Command Logic ──────────────────────────────────────────────────

  /// Thực thi một lệnh đơn lẻ.
  /// [isInsideF1]: true nếu đang chạy bên trong hàm F1 (dùng để thông báo chi tiết hơn).
  void _executeSingleCommand(CommandType cmd, {required bool isInsideF1}) {
    switch (cmd) {
      case CommandType.moveForward:
        _doMoveForward(allowElevationDiff: false);
        break;

      case CommandType.jump:
        _doJump();
        break;

      case CommandType.turnLeft:
        botDirection = botDirection.turnLeft();
        break;

      case CommandType.turnRight:
        botDirection = botDirection.turnRight();
        break;

      case CommandType.collectEnergy:
        _doCollectEnergy();
        break;

      case CommandType.callFunction1:
        // Không xử lý ở đây (được xử lý ở tầng runCommands / bỏ qua trong F1)
        break;
    }
  }

  /// Lệnh Tiến: di chuyển 1 ô về phía trước.
  /// Chỉ thành công nếu ô tiếp theo có CÙNG elevation với ô hiện tại.
  void _doMoveForward({required bool allowElevationDiff}) {
    final Position nextPos = botPosition + botDirection.delta;
    final int currentElevation = _runtimeMapData[botPosition.y][botPosition.x].elevation;

    // Kiểm tra ra khỏi bản đồ
    if (!currentLevel.isWithinBounds(nextPos)) {
      botPosition = nextPos;
      isLost = true;
      statusMessage = 'Thất bại: Robot đã rơi ra ngoài bản đồ!';
      return;
    }

    final Cell nextCell = _runtimeMapData[nextPos.y][nextPos.x];

    // Kiểm tra tường
    if (nextCell.type == CellType.wall) {
      isLost = true;
      statusMessage = 'Thất bại: Robot đã va chạm với bức tường!';
      return;
    }

    // Kiểm tra độ cao: chỉ được di chuyển nếu cùng elevation
    if (nextCell.elevation != currentElevation) {
      isLost = true;
      if (nextCell.elevation > currentElevation) {
        statusMessage =
            'Thất bại: Ô phía trước cao hơn! Hãy dùng lệnh "Nhảy" để leo lên bục.';
      } else {
        statusMessage =
            'Thất bại: Ô phía trước thấp hơn! Hãy dùng lệnh "Nhảy" để nhảy xuống.';
      }
      return;
    }

    // Di chuyển an toàn
    botPosition = nextPos;
  }

  /// Lệnh Nhảy: nhảy sang ô tiếp theo theo hướng đang nhìn.
  /// - Nhảy LÊN: ô tiếp theo có elevation = hiện tại + 1.
  /// - Nhảy XUỐNG: ô tiếp theo có elevation < hiện tại (bất kỳ).
  /// - Thất bại nếu: cùng elevation (dùng tiến), hoặc chênh lệch > 1 khi lên.
  void _doJump() {
    final Position nextPos = botPosition + botDirection.delta;
    final int currentElevation = _runtimeMapData[botPosition.y][botPosition.x].elevation;

    // Kiểm tra ra khỏi bản đồ
    if (!currentLevel.isWithinBounds(nextPos)) {
      botPosition = nextPos;
      isLost = true;
      statusMessage = 'Thất bại: Robot đã rơi ra ngoài bản đồ khi nhảy!';
      return;
    }

    final Cell nextCell = _runtimeMapData[nextPos.y][nextPos.x];

    // Kiểm tra tường
    if (nextCell.type == CellType.wall) {
      isLost = true;
      statusMessage = 'Thất bại: Robot nhảy vào tường!';
      return;
    }

    final int nextElevation = nextCell.elevation;
    final int diff = nextElevation - currentElevation;

    if (diff == 1) {
      // Nhảy lên đúng 1 bậc → OK
      botPosition = nextPos;
    } else if (diff < 0) {
      // Nhảy xuống bất kỳ số bậc → OK
      botPosition = nextPos;
    } else if (diff == 0) {
      // Cùng elevation → dùng Tiến, không phải Nhảy
      isLost = true;
      statusMessage = 'Thất bại: Hai ô cùng độ cao! Hãy dùng lệnh "Tiến" thay vì "Nhảy".';
    } else {
      // Chênh lệch > 1 khi lên → quá cao, không nhảy được
      isLost = true;
      statusMessage =
          'Thất bại: Bục quá cao ($diff tầng)! Chỉ có thể nhảy lên 1 tầng một lần.';
    }
  }

  /// Lệnh Thu thập năng lượng tại vị trí hiện tại
  void _doCollectEnergy() {
    if (!currentLevel.isWithinBounds(botPosition)) return;

    if (_runtimeMapData[botPosition.y][botPosition.x].type == CellType.energy) {
      // Thay ô energy thành empty, giữ nguyên elevation
      _runtimeMapData[botPosition.y][botPosition.x] =
          _runtimeMapData[botPosition.y][botPosition.x].withType(CellType.empty);
      collectedEnergyCount++;
      statusMessage =
          'Đã nhặt 1 viên năng lượng! ($collectedEnergyCount/${currentLevel.totalEnergyCount})';
    } else {
      statusMessage = 'Không có năng lượng tại vị trí này!';
    }
  }

  /// Kiểm tra điều kiện chiến thắng sau khi chạy xong lệnh
  void _checkWinCondition() {
    final bool hasCollectedAllEnergy =
        collectedEnergyCount == currentLevel.totalEnergyCount;

    final bool isAtDestination = currentLevel.isWithinBounds(botPosition) &&
        currentLevel.mapData[botPosition.y][botPosition.x].type ==
            CellType.destination;

    if (hasCollectedAllEnergy && isAtDestination) {
      isWon = true;
      statusMessage = 'Chúc mừng! Bạn đã hoàn thành xuất sắc màn chơi!';
    } else if (!isAtDestination && !hasCollectedAllEnergy) {
      statusMessage =
          'Thất bại: Chưa đến đích và còn thiếu ${currentLevel.totalEnergyCount - collectedEnergyCount} năng lượng!';
    } else if (!isAtDestination) {
      statusMessage = 'Thất bại: Robot chưa về đến ô Đích!';
    } else {
      statusMessage =
          'Thất bại: Chưa thu thập đủ năng lượng ($collectedEnergyCount/${currentLevel.totalEnergyCount})!';
    }
  }

  // ─── Utilities ──────────────────────────────────────────────────────────

  /// Lấy Cell tại vị trí [pos] trên bản đồ runtime
  Cell? getRuntimeCellAt(Position pos) {
    if (!currentLevel.isWithinBounds(pos)) return null;
    return _runtimeMapData[pos.y][pos.x];
  }

  /// Độ cao ô hiện tại của Robot
  int get botElevation {
    if (!currentLevel.isWithinBounds(botPosition)) return 0;
    return _runtimeMapData[botPosition.y][botPosition.x].elevation;
  }
}
