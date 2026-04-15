import 'package:flutter_test/flutter_test.dart';
import 'package:geo_entities_app/main.dart';

void main() {
  testWidgets('app starts with required bottom navigation tabs',
      (tester) async {
    await tester.pumpWidget(const MyApp(enableMap: false, loadOnStart: false));
    await tester.pump();

    expect(find.text('Map'), findsWidgets);
    expect(find.text('Landmarks'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Add/View'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pump();
    expect(find.text('Recent landmark visits and offline sync status.'),
        findsOneWidget);

    await tester.tap(find.text('Add/View'));
    await tester.pump();
    expect(find.text('New landmark'), findsOneWidget);
    expect(find.text('Create landmark'), findsOneWidget);
  });
}
