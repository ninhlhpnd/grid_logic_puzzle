import 'position.dart';

/// Hướng nhìn và di chuyển của Robot trên bản đồ lưới.
enum Direction {
  up,
  down,
  left,
  right;

  /// Quay 90 độ sang trái (ngược chiều kim đồng hồ)
  Direction turnLeft() {
    switch (this) {
      case Direction.up:
        return Direction.left;
      case Direction.left:
        return Direction.down;
      case Direction.down:
        return Direction.right;
      case Direction.right:
        return Direction.up;
    }
  }

  /// Quay 90 độ sang phải (thuận chiều kim đồng hồ)
  Direction turnRight() {
    switch (this) {
      case Direction.up:
        return Direction.right;
      case Direction.right:
        return Direction.down;
      case Direction.down:
        return Direction.left;
      case Direction.left:
        return Direction.up;
    }
  }

  /// Độ lệch tọa độ (dx, dy) khi robot tiến 1 bước theo hướng hiện tại.
  /// Quy ước: gốc (0,0) ở góc trên trái; x tăng sang phải, y tăng xuống dưới.
  Position get delta {
    switch (this) {
      case Direction.up:
        return const Position(0, -1);
      case Direction.down:
        return const Position(0, 1);
      case Direction.left:
        return const Position(-1, 0);
      case Direction.right:
        return const Position(1, 0);
    }
  }

  /// Tên hiển thị tiếng Việt thân thiện
  String get displayName {
    switch (this) {
      case Direction.up:
        return 'Lên trên';
      case Direction.down:
        return 'Xuống dưới';
      case Direction.left:
        return 'Sang trái';
      case Direction.right:
        return 'Sang phải';
    }
  }
}

/// Loại ô trên bản đồ lưới của trò chơi.
enum CellType {
  /// Ô trống bình thường, robot có thể đi qua.
  empty,

  /// Bức tường / Chướng ngại vật: robot đi vào sẽ thua.
  wall,

  /// Ô xuất phát của màn chơi.
  start,

  /// Ô đích đến: robot cần đứng tại đây để thắng.
  destination,

  /// Ô chứa năng lượng: robot cần thu thập hết.
  energy;

  /// Kiểm tra ô có phải là chướng ngại vật hay không
  bool get isObstacle => this == CellType.wall;
}

/// Các loại lệnh điều khiển mà người chơi có thể lập trình cho Robot.
enum CommandType {
  /// Di chuyển tiến 1 ô theo hướng đang nhìn
  /// (chỉ thành công nếu ô tiếp theo có cùng elevation)
  moveForward,

  /// Xoay 90 độ sang trái tại chỗ
  turnLeft,

  /// Xoay 90 độ sang phải tại chỗ
  turnRight,

  /// Thu thập năng lượng tại vị trí bot đang đứng
  collectEnergy,

  /// Nhảy lên bục có elevation = hiện tại + 1,
  /// hoặc nhảy xuống bất kỳ ô thấp hơn phía trước.
  jump,

  /// Gọi hàm con F1: thực thi toàn bộ lệnh trong function1List
  callFunction1;

  /// Tên hiển thị tiếng Việt của lệnh
  String get label {
    switch (this) {
      case CommandType.moveForward:
        return 'Tiến lên';
      case CommandType.turnLeft:
        return 'Rẽ trái';
      case CommandType.turnRight:
        return 'Rẽ phải';
      case CommandType.collectEnergy:
        return 'Nhặt';
      case CommandType.jump:
        return 'Nhảy';
      case CommandType.callFunction1:
        return 'Gọi F1';
    }
  }
}
