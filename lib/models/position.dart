/// Đại diện cho một tọa độ 2D (x, y) trên lưới trò chơi.
/// - `x`: Chỉ số cột (từ 0 đến gridWidth - 1, tăng dần từ trái sang phải).
/// - `y`: Chỉ số hàng (từ 0 đến gridHeight - 1, tăng dần từ trên xuống dưới).
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  /// Cộng hai vị trí (hoặc cộng vector delta)
  Position operator +(Position other) => Position(x + other.x, y + other.y);

  /// Trừ hai vị trí
  Position operator -(Position other) => Position(x - other.x, y - other.y);

  /// So sánh giá trị hai Position
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  /// Tạo bản sao với tọa độ mới
  Position copyWith({int? x, int? y}) {
    return Position(
      x ?? this.x,
      y ?? this.y,
    );
  }

  @override
  String toString() => 'Position($x, $y)';
}
