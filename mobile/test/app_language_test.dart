import 'package:flutter_test/flutter_test.dart';
import 'package:staff_portal/core/localization/app_language.dart';

void main() {
  test('Cantonese catalogue translates shared and dynamic HR labels', () {
    expect(
      AppLanguage.translate('Leave Requests', AppLanguage.cantonese),
      '請假申請',
    );
    expect(
      AppLanguage.translate('3 days left', AppLanguage.cantonese),
      '3日剩餘',
    );
    expect(
      AppLanguage.translate('Dashboard', AppLanguage.english),
      'Dashboard',
    );
  });
}
