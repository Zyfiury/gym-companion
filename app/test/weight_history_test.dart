import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/utils/weight_history.dart';

void main() {
  test('merge combines embedded and subcollection by date', () {
    final merged = WeightHistoryHelper.merge([
      {'date': '2026-06-01', 'weight': 74.0},
      {'date': '2026-06-03', 'weight': 73.2},
      {'date': '2026-06-02', 'weight': 73.8},
      {'date': '2026-06-03', 'weight': 73.0},
    ]);
    expect(merged.length, 3);
    expect(merged.last['weight'], 73.0);
    expect(merged.first['date'], '2026-06-01');
  });

  test('upsert adds new day and updates same day', () {
    final history = <Map<String, dynamic>>[];
    expect(WeightHistoryHelper.upsert(history, 75, date: '2026-06-01'), isFalse);
    expect(history.length, 1);
    expect(WeightHistoryHelper.upsert(history, 74.5, date: '2026-06-02'), isFalse);
    expect(history.length, 2);
    expect(WeightHistoryHelper.upsert(history, 74.0, date: '2026-06-02'), isTrue);
    expect(history.length, 2);
    expect(history.last['weight'], 74.0);
  });

  test('seedBaselineIfEmpty only runs once', () {
    final history = <Map<String, dynamic>>[];
    WeightHistoryHelper.seedBaselineIfEmpty(history, 80);
    expect(history.length, 1);
    WeightHistoryHelper.seedBaselineIfEmpty(history, 80);
    expect(history.length, 1);
  });

  test('latestWeight uses most recent date not last inserted', () {
    final history = <Map<String, dynamic>>[];
    WeightHistoryHelper.upsert(history, 73, date: '2026-06-07');
    WeightHistoryHelper.upsert(history, 75, date: '2026-06-01');
    expect(WeightHistoryHelper.latestWeight(history), 73);
  });
}
