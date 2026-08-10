import 'package:flutter_test/flutter_test.dart';
import 'package:sisov_mobile/core/utils/api_error_messages.dart';
import 'package:sisov_mobile/core/utils/validators.dart';

void main() {
  group('document validation', () {
    test('accepts valid CPF and CNPJ', () {
      expect(AppValidators.document('52998224725'), isNull);
      expect(AppValidators.document('11222333000181'), isNull);
    });

    test('rejects invalid or repeated documents', () {
      expect(AppValidators.document('11111111111'), isNotNull);
      expect(AppValidators.document('11222333000182'), isNotNull);
      expect(AppValidators.document('123'), isNotNull);
    });
  });

  group('Google login errors', () {
    test('explains an invalid Google credential', () {
      final message = ApiErrorMessages.fromHttp(
        statusCode: 401,
        body: '{"error":"Invalid Google token."}',
        action: ApiAction.googleLogin,
      );

      expect(message, contains('Google'));
      expect(message, contains('inválida'));
    });

    test('explains profile completion', () {
      final message = ApiErrorMessages.fromHttp(
        statusCode: 428,
        body: '{}',
        action: ApiAction.googleLogin,
      );

      expect(message, contains('CPF ou CNPJ'));
    });
  });
}
