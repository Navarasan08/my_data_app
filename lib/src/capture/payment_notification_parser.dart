/// Pure-Dart parser that turns a payment app's notification text into a
/// structured payment. No plugin imports — fully unit-testable.
class ParsedPayment {
  /// Parsed amount in rupees (or whatever currency the text used).
  final double amount;

  /// Who the money went to (debit) or came from (credit). May be empty when
  /// the notification didn't name anyone.
  final String counterparty;

  /// True for money received (credited/refunded), false for money spent.
  final bool isIncome;

  /// Human label of the source app, e.g. "GPay".
  final String sourceApp;

  const ParsedPayment({
    required this.amount,
    required this.counterparty,
    required this.isIncome,
    required this.sourceApp,
  });
}

class PaymentNotificationParser {
  /// Package → display label of apps whose notifications we try to parse.
  /// Anything not in this allowlist is ignored outright.
  static const Map<String, String> allowedPackages = {
    'com.google.android.apps.nbu.paisa.user': 'GPay',
    'com.phonepe.app': 'PhonePe',
    'net.one97.paytm': 'Paytm',
    'in.org.npci.upiapp': 'BHIM',
    'in.amazon.mShop.android.shopping': 'Amazon Pay',
    'com.whatsapp': 'WhatsApp Pay',
  };

  /// ₹1,234.56 / Rs. 1234 / INR 500 — captures the numeric part.
  static final RegExp _amountRe = RegExp(
    r'(?:₹|Rs\.?\s?|INR\s?)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _creditRe = RegExp(
    r'\b(received|credited|refund(?:ed)?|deposited|cashback of)\b',
    caseSensitive: false,
  );

  static final RegExp _debitRe = RegExp(
    r'\b(paid|sent|debited|spent|payment of|you paid)\b',
    caseSensitive: false,
  );

  /// Notifications that mention money but aren't completed payments.
  static final RegExp _rejectRe = RegExp(
    r'\b(failed|declined|pending|reminder|requested|is requesting|request(?:s)? money|offer|win|earn|scratch|reward)\b',
    caseSensitive: false,
  );

  /// `to Ravi Stores`, `at Big Bazaar`, `from Anitha` — captures the name up
  /// to a connective ("on", "via", …), punctuation, or end of text.
  static final RegExp _toRe = RegExp(
    r'\b(?:to|at)\s+([^.,\n]+?)(?=\s+(?:on|via|using|for|from|with|upi|a\/c)\b|[.,\n!]|$)',
    caseSensitive: false,
  );

  static final RegExp _fromRe = RegExp(
    r'\bfrom\s+([^.,\n]+?)(?=\s+(?:on|via|using|for|to|with|upi|a\/c)\b|[.,\n!]|$)',
    caseSensitive: false,
  );

  /// Returns the parsed payment, or null when the notification isn't a
  /// completed payment from an allowed app (promos, requests, failures,
  /// non-payment chatter all return null).
  static ParsedPayment? parse({
    required String packageName,
    String? title,
    String? text,
  }) {
    final sourceApp = allowedPackages[packageName];
    if (sourceApp == null) return null;

    final combined = [title, text]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join('. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (combined.isEmpty) return null;

    if (_rejectRe.hasMatch(combined)) return null;

    final amountMatch = _amountRe.firstMatch(combined);
    if (amountMatch == null) return null;
    final amount =
        double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    final isCredit = _creditRe.hasMatch(combined);
    final isDebit = _debitRe.hasMatch(combined);
    // Not recognisably a payment either way (e.g. balance updates).
    if (!isCredit && !isDebit) return null;
    // Debit wording wins when both appear ("paid ... cashback of ₹5" promos
    // are already rejected above; residual mixes are almost always debits).
    final isIncome = isCredit && !isDebit;

    final nameMatch =
        isIncome ? _fromRe.firstMatch(combined) : _toRe.firstMatch(combined);
    final counterparty = (nameMatch?.group(1) ?? '').trim();

    return ParsedPayment(
      amount: amount,
      counterparty: _cleanName(counterparty),
      isIncome: isIncome,
      sourceApp: sourceApp,
    );
  }

  /// Strips trailing filler words and stray UPI ids from a captured name.
  static String _cleanName(String raw) {
    var name = raw.trim();
    name = name.replaceAll(
        RegExp(r'\s+(successfully|successful|completed)$',
            caseSensitive: false),
        '');
    // "Ravi Stores (ravi@oksbi)" → "Ravi Stores"
    name = name.replaceAll(RegExp(r'\s*\([^)]*@[^)]*\)\s*$'), '');
    return name.trim();
  }
}
