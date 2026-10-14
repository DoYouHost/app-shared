/// Symbols for common ISO 4217 codes (the set bambuddy's web client names,
/// `frontend/src/utils/currency.ts`). Where the symbol goes is a separate
/// decision — see [formatMoney].
///
/// An unknown code falls back to the code itself, which is what the web does
/// and is still an answer: "12.50 XPF" says more than a bare 12.50.
const _symbols = <String, String>{
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'CHF': 'Fr.',
  'JPY': '¥',
  'CNY': '¥',
  'CAD': r'$',
  'AUD': r'$',
  'INR': '₹',
  'HKD': r'HK$',
  'KRW': '₩',
  'SEK': 'kr',
  'NOK': 'kr',
  'DKK': 'kr',
  'PLN': 'zł',
  'BRL': r'R$',
  'TWD': r'NT$',
  'SGD': r'S$',
  'NZD': r'NZ$',
  'MXN': r'MX$',
  'BZD': r'BZ$',
  'MYR': 'RM',
  'CZK': 'Kč',
  'THB': '฿',
  'ZAR': 'R',
  'TRY': '₺',
  'RUB': '₽',
  'HUF': 'Ft',
  'ILS': '₪',
  'UAH': '₴',
  'IDR': 'Rp',
  'PHP': '₱',
};

/// The symbol for [code] as the server spelled it, or `''` when the server has
/// not said which currency it keeps prices in.
///
/// Empty rather than a guessed `$`: a bare number is ambiguous, a wrong symbol
/// is wrong.
String currencySymbol(String? code) {
  final key = code?.trim().toUpperCase();
  if (key == null || key.isEmpty) return '';
  return _symbols[key] ?? key;
}

/// [amount] with the currency symbol on the side that currency puts it —
/// `$12.50`, but `12.50 zł`, never `zł12.50`, a spelling no Polish price uses.
///
/// After the amount: the symbols of currencies written that way
/// ([_writtenAfter]) and a bare ISO code, which is what an unknown currency shows. Every
/// other symbol goes before it — the glyphs (`$`, `€`, `£`, `₹`…) and the
/// lettered ones alike (`R$`, `HK$`, `RM`, `Rp`, `Fr.`): the first character
/// says nothing about the side, `R$12.50` and `12.50 zł` both start with a
/// letter. A lettered symbol that ends in a letter or a dot is spaced from the
/// number (`Rp 12.50`, `Fr. 12.50`), so the two do not run together.
String formatMoney(String symbol, String amount) {
  if (symbol.isEmpty) return amount;
  if (_writtenAfter.contains(symbol) || _isoCode.hasMatch(symbol)) {
    return '$amount $symbol';
  }
  return _endsInWord.hasMatch(symbol) ? '$symbol $amount' : '$symbol$amount';
}

/// The symbols in [_symbols] whose currency puts them after the amount.
const _writtenAfter = {'zł', 'kr', 'Kč', 'Ft'};

final _isoCode = RegExp(r'^[A-Z]{3}$');
final _endsInWord = RegExp(r'[\p{L}.]$', unicode: true);
