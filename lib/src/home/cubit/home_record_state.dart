import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';

enum HomeViewMode { all, monthly }

/// How to treat the monthly start date when it lands on a weekend.
/// [exact] keeps the date as-is (default — plain calendar behaviour when the
/// start day is 1). [previousFriday] / [followingMonday] shift a Sat/Sun start
/// to the nearest weekday in that direction.
enum WeekendAdjustment { exact, previousFriday, followingMonday }

WeekendAdjustment weekendAdjustmentFromName(String? name) {
  return WeekendAdjustment.values.firstWhere(
    (w) => w.name == name,
    orElse: () => WeekendAdjustment.exact,
  );
}

class HomeCurrency {
  final String code;
  final String symbol;
  final String name;

  const HomeCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  static const inr = HomeCurrency(code: 'INR', symbol: '\u20B9', name: 'Indian Rupee');
  static const usd = HomeCurrency(code: 'USD', symbol: '\$', name: 'US Dollar');
  static const eur = HomeCurrency(code: 'EUR', symbol: '\u20AC', name: 'Euro');
  static const gbp = HomeCurrency(code: 'GBP', symbol: '\u00A3', name: 'British Pound');
  static const aed = HomeCurrency(code: 'AED', symbol: 'AED', name: 'UAE Dirham');
  static const sar = HomeCurrency(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal');
  static const jpy = HomeCurrency(code: 'JPY', symbol: '\u00A5', name: 'Japanese Yen');

  static const List<HomeCurrency> all = [inr, usd, eur, gbp, aed, sar, jpy];

  static HomeCurrency fromCode(String code) {
    return all.firstWhere((c) => c.code == code, orElse: () => inr);
  }

  String get _locale {
    switch (code) {
      case 'INR':
        return 'en_IN';
      case 'USD':
        return 'en_US';
      case 'GBP':
        return 'en_GB';
      case 'EUR':
        return 'de_DE';
      case 'JPY':
        return 'ja_JP';
      case 'AED':
      case 'SAR':
      default:
        return 'en_US';
    }
  }

  /// Format [amount] with locale-aware grouping (e.g. INR \u2192 \u20B91,23,456,
  /// USD \u2192 $123,456) and prepend the currency symbol.
  String format(double amount, {int decimals = 0}) {
    final formatter = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return '$symbol${formatter.format(amount)}';
  }

  @override
  bool operator ==(Object other) => other is HomeCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class HomeRecordState {
  final List<HomeRecord> records;
  final DateTime selectedDate;

  /// Multi-select category filter, by category id. Empty set = "show all".
  final Set<String> selectedCategoryIds;

  final List<HomeCategory> customCategories;
  final List<PaymentType> paymentTypes;
  final HomeViewMode viewMode;
  final HomeCurrency currency;
  final bool showMonthlyCalendar;

  /// Day-of-month (1–31) on which a monthly cycle begins. 1 = plain calendar
  /// month. Days beyond a month's length are clamped (e.g. 31 → 28 in Feb).
  final int monthlyStartDay;

  /// What to do when [monthlyStartDay] lands on a Saturday or Sunday.
  final WeekendAdjustment weekendAdjustment;

  /// When true, the records list is replaced with a month-grid calendar where
  /// each day cell shows the total expense for that day. Toggled from the
  /// app bar.
  final bool isCalendarView;

  const HomeRecordState({
    required this.records,
    required this.selectedDate,
    this.selectedCategoryIds = const {},
    this.customCategories = const [],
    this.paymentTypes = const [],
    this.viewMode = HomeViewMode.monthly,
    this.currency = HomeCurrency.inr,
    this.showMonthlyCalendar = true,
    this.monthlyStartDay = 1,
    this.weekendAdjustment = WeekendAdjustment.exact,
    this.isCalendarView = false,
  });

  HomeRecordState copyWith({
    List<HomeRecord>? records,
    DateTime? selectedDate,
    Set<String>? selectedCategoryIds,
    List<HomeCategory>? customCategories,
    List<PaymentType>? paymentTypes,
    HomeViewMode? viewMode,
    HomeCurrency? currency,
    bool? showMonthlyCalendar,
    int? monthlyStartDay,
    WeekendAdjustment? weekendAdjustment,
    bool? isCalendarView,
  }) {
    return HomeRecordState(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      customCategories: customCategories ?? this.customCategories,
      paymentTypes: paymentTypes ?? this.paymentTypes,
      viewMode: viewMode ?? this.viewMode,
      currency: currency ?? this.currency,
      showMonthlyCalendar: showMonthlyCalendar ?? this.showMonthlyCalendar,
      monthlyStartDay: monthlyStartDay ?? this.monthlyStartDay,
      weekendAdjustment: weekendAdjustment ?? this.weekendAdjustment,
      isCalendarView: isCalendarView ?? this.isCalendarView,
    );
  }
}
