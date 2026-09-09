import 'package:flutter_test/flutter_test.dart';
import 'package:grid_logic_puzzle/main.dart';

void main() {
  testWidgets('Khởi tạo màn hình GameScreen thành công', (WidgetTester tester) async {
    await tester.pumpWidget(const GridPuzzleApp());

    // Kiểm tra tiêu đề app bar (đã đổi thành Mini Bot Logic)
    expect(find.text('Mini Bot Logic'), findsOneWidget);

    // Kiểm tra các nút Action
    expect(find.text('CHẠY (RUN)'), findsOneWidget);
    expect(find.text('ĐẶT LẠI (RESET)'), findsOneWidget);
  });
}
