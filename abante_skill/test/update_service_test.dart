import 'package:abante_skill/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isNewer compares dotted versions numerically', () {
    expect(UpdateService.isNewer('1.0.1', '1.0.0'), isTrue);
    expect(UpdateService.isNewer('1.1.0', '1.0.9'), isTrue);
    expect(UpdateService.isNewer('1.0.10', '1.0.9'), isTrue);
    expect(UpdateService.isNewer('2.0', '1.9.9'), isTrue);

    expect(UpdateService.isNewer('1.0.0', '1.0.0'), isFalse);
    expect(UpdateService.isNewer('1.0.0', '1.0.1'), isFalse);
    expect(UpdateService.isNewer('1.0.0+5', '1.0.0+1'), isFalse, reason: 'build number alone is not an update');
  });
}
