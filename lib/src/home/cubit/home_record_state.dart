import 'package:my_data_app/src/home/home_record_model.dart';

enum HomeViewMode { all, monthly }

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

  @override
  bool operator ==(Object other) => other is HomeCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class HomeRecordState {
  final List<HomeRecord> records;
  final DateTime selectedDate;
  final HomeCategory? selectedCategory;
  final List<HomeCategory> customCategories;
  final HomeViewMode viewMode;
  final HomeCurrency currency;

  const HomeRecordState({
    required this.records,
    required this.selectedDate,
    this.selectedCategory,
    this.customCategories = const [],
    this.viewMode = HomeViewMode.monthly,
    this.currency = HomeCurrency.inr,
  });

  HomeRecordState copyWith({
    List<HomeRecord>? records,
    DateTime? selectedDate,
    HomeCategory? selectedCategory,
    bool clearCategory = false,
    List<HomeCategory>? customCategories,
    HomeViewMode? viewMode,
    HomeCurrency? currency,
  }) {
    return HomeRecordState(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      customCategories: customCategories ?? this.customCategories,
      viewMode: viewMode ?? this.viewMode,
      currency: currency ?? this.currency,
    );
  }
}
