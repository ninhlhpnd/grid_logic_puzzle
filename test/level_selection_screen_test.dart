import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_logic_puzzle/screens/level_selection_screen.dart';
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

  testWidgets('LevelSelectionScreen hiển thị 100 màn chơi, khóa level > unlockedLevels',
      (WidgetTester tester) async {
    final playerManager = PlayerManager();
    await playerManager.init();

    // Mở khóa đến level 3 (tức index 0, 1, 2)
    playerManager.unlockNextLevel(0); // unlocked: 2
    playerManager.unlockNextLevel(1); // unlocked: 3
    playerManager.setLevelStars(0, 3); // Level 1 có 3 sao
    playerManager.setLevelStars(1, 2); // Level 2 có 2 sao

    final levelManager = LevelManager();
    // Tạo sample 5 level cho levelManager
    const sampleJson = '''[
      {"id": "l1", "name": "Màn 1", "grid": [["S", "D"]], "start_pos": {"x": 0, "y": 0}},
      {"id": "l2", "name": "Màn 2", "grid": [["S", "D"]], "start_pos": {"x": 0, "y": 0}},
      {"id": "l3", "name": "Màn 3", "grid": [["S", "D"]], "start_pos": {"x": 0, "y": 0}},
      {"id": "l4", "name": "Màn 4", "grid": [["S", "D"]], "start_pos": {"x": 0, "y": 0}},
      {"id": "l5", "name": "Màn 5", "grid": [["S", "D"]], "start_pos": {"x": 0, "y": 0}}
    ]''';
    levelManager.loadFromString(sampleJson);

    int? selectedLevel;

    await tester.pumpWidget(
      MaterialApp(
        home: LevelSelectionScreen(
          levelManager: levelManager,
          playerManager: playerManager,
          currentSelectedLevelIndex: 0,
          onSelectLevel: (idx) {
            selectedLevel = idx;
          },
        ),
      ),
    );

    // Kiểm tra UI AppBar và Title
    expect(find.text('CHỌN MÀN CHƠI'), findsOneWidget);
    expect(find.text('Tiến trình khám phá: Màn 3 / 5'), findsOneWidget);

    // Level 1 và 2 hiển thị số và sao
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsWidgets); // Có thể xuất hiện ở card level 3 và header

    // Level 4 và 5 bị khóa -> có icon lock
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);

    // Click vào Level 2 (index 1) -> onSelectLevel(1) và pop
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(selectedLevel, 1);
  });
}
