import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/delivery_service.dart';

void main() {
  test('detects delivery queries', () {
    expect(DeliveryService.isDeliveryQuery('uber eats near me'), isTrue);
    expect(DeliveryService.isDeliveryQuery('what can I order for delivery'), isTrue);
    expect(DeliveryService.isDeliveryQuery('restaurants around my area'), isTrue);
    expect(DeliveryService.isDeliveryQuery('swap my lunch'), isFalse);
    expect(DeliveryService.isDeliveryQuery('log 200g chicken'), isFalse);
  });
}
