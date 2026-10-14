import 'package:app_util/app_util.dart';
import 'package:flutter_test/flutter_test.dart';

/// The currency code comes from the server's settings, so it is input: it can
/// be absent, blank, lower-case, or a code this table has never heard of.
void main() {
  group('currencySymbol', () {
    test('known codes resolve, whatever case they arrive in', () {
      expect(currencySymbol('USD'), r'$');
      expect(currencySymbol('pln'), 'zł');
      expect(currencySymbol(' eur '), '€');
    });

    test('no code at all resolves to nothing', () {
      // Empty rather than a guessed dollar: a bare number is ambiguous, a wrong
      // symbol is wrong.
      expect(currencySymbol(null), '');
      expect(currencySymbol(''), '');
      expect(currencySymbol('   '), '');
    });

    test('an unknown code is shown as itself', () {
      expect(currencySymbol('XPF'), 'XPF');
    });
  });

  group('formatMoney', () {
    test('a glyph goes before the amount, a written-after symbol after it', () {
      expect(formatMoney(r'$', '12.50'), r'$12.50');
      expect(formatMoney('€', '12.50'), '€12.50');
      expect(formatMoney('zł', '12.50'), '12.50 zł');
      expect(formatMoney('Kč', '12.50'), '12.50 Kč');
    });

    test('an unknown code lands on the alphabetic side', () {
      expect(formatMoney('XPF', '12.50'), '12.50 XPF');
    });

    test('a lettered symbol written before the amount stays before it', () {
      expect(formatMoney(r'R$', '12.50'), r'R$12.50');
      expect(formatMoney(r'HK$', '12.50'), r'HK$12.50');
      expect(formatMoney('RM', '12.50'), 'RM 12.50');
      expect(formatMoney('Fr.', '12.50'), 'Fr. 12.50');
      expect(formatMoney('kr', '12.50'), '12.50 kr');
      expect(formatMoney('Ft', '12.50'), '12.50 Ft');
    });

    test('no symbol leaves the amount alone', () {
      expect(formatMoney('', '12.50'), '12.50');
    });
  });
}
