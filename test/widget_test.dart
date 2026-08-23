import 'package:flutter_test/flutter_test.dart';

import 'package:sav_frontend/main.dart';

void main() {
  testWidgets('La app arranca en la pantalla de login', (tester) async {
    await tester.pumpWidget(const AutoRentApp());
    expect(find.text('AutoRent Perú'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
