import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/repository/home_record_repository.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';

class HomeRecordCubit extends Cubit<HomeRecordState> {
  final HomeRecordRepository _repository;

  HomeRecordCubit(this._repository)
      : super(HomeRecordState(
          records: _repository.getAll(),
          selectedDate: DateTime.now(),
          customCategories: _repository.getCustomCategories(),
          currency: HomeCurrency.fromCode(_repository.getCurrencyCode()),
        ));

  void addRecord(HomeRecord record) {
    _repository.add(record);
    emit(state.copyWith(records: _repository.getAll()));
  }

  void updateRecord(HomeRecord record) {
    _repository.update(record);
    emit(state.copyWith(records: _repository.getAll()));
  }

  void deleteRecord(String recordId) {
    _repository.delete(recordId);
    emit(state.copyWith(records: _repository.getAll()));
  }

  void changeMonth(int monthDelta) {
    final current = state.selectedDate;
    emit(state.copyWith(
      selectedDate: DateTime(current.year, current.month + monthDelta, 1),
    ));
  }

  void setCategory(HomeCategory? category) {
    if (category == null) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategory: category));
    }
  }

  void setViewMode(HomeViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  List<HomeCategory> get allCategories =>
      [...HomeCategory.defaults, ...state.customCategories];

  List<HomeRecord> get allRecordsSorted {
    return List<HomeRecord>.from(state.records)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<HomeRecord> get recordsForSelectedMonth {
    final sel = state.selectedDate;
    return state.records
        .where((r) => r.date.year == sel.year && r.date.month == sel.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<HomeRecord> get _baseRecords {
    return state.viewMode == HomeViewMode.monthly
        ? recordsForSelectedMonth
        : allRecordsSorted;
  }

  List<HomeRecord> get filteredRecords {
    final records = _baseRecords;
    if (state.selectedCategory == null) return records;
    return records
        .where((r) => r.category == state.selectedCategory)
        .toList();
  }

  double get displayTotal {
    return _baseRecords.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get totalAmount {
    return state.records.fold(0.0, (sum, r) => sum + r.amount);
  }

  Map<HomeCategory, double> get categoryTotals {
    final map = <HomeCategory, double>{};
    for (final r in _baseRecords) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
    return map;
  }

  /// Quantity totals per category, grouped by unit for the current view.
  /// Returns { category: { unit: totalQty } }
  Map<HomeCategory, Map<MeasureUnit, double>> get categoryQuantities {
    final map = <HomeCategory, Map<MeasureUnit, double>>{};
    for (final r in _baseRecords) {
      if (r.quantity != null && r.unit != null) {
        map.putIfAbsent(r.category, () => {});
        map[r.category]![r.unit!] =
            (map[r.category]![r.unit!] ?? 0) + r.quantity!;
      }
    }
    return map;
  }

  Map<DateTime, double> monthlyTotals({int months = 12}) {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = state.records
          .where(
              (r) => r.date.year == month.year && r.date.month == month.month)
          .fold(0.0, (sum, r) => sum + r.amount);
      result[month] = total;
    }
    return result;
  }

  Map<HomeCategory, double> allTimeCategoryTotals() {
    final map = <HomeCategory, double>{};
    for (final r in state.records) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
    return map;
  }

  Map<HomeCategory, double> categoryTotalsInRange(
      DateTime start, DateTime end) {
    final map = <HomeCategory, double>{};
    for (final r in state.records) {
      if (!r.date.isBefore(start) && !r.date.isAfter(end)) {
        map[r.category] = (map[r.category] ?? 0) + r.amount;
      }
    }
    return map;
  }

  double get allTimeTotal =>
      state.records.fold(0.0, (sum, r) => sum + r.amount);

  double get averagePerMonth {
    if (state.records.isEmpty) return 0;
    final months = monthlyTotals();
    final nonZeroMonths = months.values.where((v) => v > 0).length;
    if (nonZeroMonths == 0) return 0;
    return allTimeTotal / nonZeroMonths;
  }

  HomeCategory? get highestCategory {
    final totals = allTimeCategoryTotals();
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Custom category management
  void addCustomCategory(HomeCategory category) {
    _repository.addCustomCategory(category);
    emit(state.copyWith(customCategories: _repository.getCustomCategories()));
  }

  void updateCustomCategory(HomeCategory category) {
    _repository.updateCustomCategory(category);
    // Update records that use this category so they reflect new name/icon/color
    final updatedRecords = state.records.map((r) {
      if (r.category.id == category.id) {
        return r.copyWith(category: category);
      }
      return r;
    }).toList();
    emit(state.copyWith(
      customCategories: _repository.getCustomCategories(),
      records: updatedRecords,
    ));
  }

  void deleteCustomCategory(String categoryId) {
    _repository.deleteCustomCategory(categoryId);
    emit(state.copyWith(customCategories: _repository.getCustomCategories()));
  }

  bool isCategoryInUse(String categoryId) {
    return state.records.any((r) => r.category.id == categoryId);
  }

  String get currencySymbol => state.currency.symbol;

  void setCurrency(HomeCurrency currency) {
    _repository.setCurrencyCode(currency.code);
    emit(state.copyWith(currency: currency));
  }
}
