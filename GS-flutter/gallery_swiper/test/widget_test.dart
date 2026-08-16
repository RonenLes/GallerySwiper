import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_swiper/main.dart';

void main() {
  testWidgets('renders the empty gallery', (tester) async {
    await tester.pumpWidget(const GallerySwiperApp());
    await tester.pump();
    expect(find.text('Pick photos'), findsOneWidget);
    expect(find.text('Your gallery, your call'), findsOneWidget);

    await tester.tap(find.byTooltip('Change scan option'));
    await tester.pumpAndSettle();
    expect(find.text('Scan all'), findsOneWidget);
    expect(find.text('Month / year'), findsOneWidget);
    expect(find.text('Album'), findsOneWidget);
  });
}
