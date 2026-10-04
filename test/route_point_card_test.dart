import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/route_data.dart';
import 'package:flutter_application_1/models/route_point.dart';
import 'package:flutter_application_1/widgets/route_point_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, String stationId) {
    final point = RouteData.getRoute(
      Direction.mlociny,
      DayType.saturday,
    ).firstWhere((p) => p.stationId == stationId);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: RoutePointCard(
              point: point,
              // Przed pierwszym kursem obiegu 1, więc karta pokazuje odliczanie
              currentTime: DateTime(2026, 10, 3, 0, 5),
              circuit: 1,
              direction: Direction.mlociny,
            ),
          ),
        ),
      ),
    );
  }

  group('RoutePointCard: pierwsze i ostatnie odjazdy', () {
    testWidgets('Stokłosy mają osobną godzinę na sobotę i niedzielę', (
      tester,
    ) async {
      await pumpCard(tester, 'A4');
      expect(find.text('Pierwszy: 05:00'), findsOneWidget);
      expect(find.text('Pierwszy (sb-nd): 05:06'), findsOneWidget);
      expect(find.text('Ostatni: 00:12 / 02:03 (pt-sb)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Wilanowska nie ma wiersza na weekend', (tester) async {
      await pumpCard(tester, 'A7');
      expect(find.text('Pierwszy: 05:00'), findsOneWidget);
      expect(find.textContaining('sb-nd'), findsNothing);
    });
  });
}
