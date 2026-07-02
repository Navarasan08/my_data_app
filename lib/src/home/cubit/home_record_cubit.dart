import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
          paymentTypes: _repository.getPaymentTypes(),
          currency: HomeCurrency.fromCode(_repository.getCurrencyCode()),
          showMonthlyCalendar: _repository.getShowMonthlyCalendar(),
          monthlyStartDay: _repository.getMonthlyStartDay(),
          weekendAdjustment:
              weekendAdjustmentFromName(_repository.getWeekendAdjustment()),
          isCalendarView: _repository.getIsCalendarView(),
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
    final cur = state.selectedDate;
    final target = DateTime(cur.year, cur.month + monthDelta, 1);
    final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
    final day = cur.day > daysInTarget ? daysInTarget : cur.day;
    emit(state.copyWith(
      selectedDate: DateTime(target.year, target.month, day),
    ));
  }

  /// Toggle a category in the filter set. If the set was empty, this starts
  /// it. Tapping a selected category removes it.
  void toggleCategory(HomeCategory category) {
    final next = Set<String>.from(state.selectedCategoryIds);
    if (next.contains(category.id)) {
      next.remove(category.id);
    } else {
      next.add(category.id);
    }
    emit(state.copyWith(selectedCategoryIds: next));
  }

  /// Replace the current selection with [ids] (used by the multi-select
  /// filter sheet).
  void setCategoryIds(Set<String> ids) {
    emit(state.copyWith(selectedCategoryIds: Set<String>.from(ids)));
  }

  void clearCategoryFilter() {
    emit(state.copyWith(selectedCategoryIds: const {}));
  }

  void setViewMode(HomeViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  List<HomeCategory> get allCategories =>
      [...HomeCategory.defaults, ...state.customCategories];

  /// Categories sorted by usage (most-used first). Ties keep their declared
  /// order so the strip stays stable when counts are equal.
  List<HomeCategory> get categoriesByUsage {
    final counts = <String, int>{};
    for (final r in state.records) {
      counts[r.category.id] = (counts[r.category.id] ?? 0) + 1;
    }
    final indexed = allCategories.asMap().entries.toList();
    indexed.sort((a, b) {
      final ca = counts[a.value.id] ?? 0;
      final cb = counts[b.value.id] ?? 0;
      if (cb != ca) return cb.compareTo(ca);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  List<HomeRecord> get allRecordsSorted {
    return List<HomeRecord>.from(state.records)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ── Monthly cycle (custom start day + weekend adjustment) ────────────────

  /// True when the user has customised the monthly cycle away from a plain
  /// calendar month (start day other than 1, or any weekend shift on day 1).
  bool get hasCustomCycle =>
      state.monthlyStartDay != 1 ||
      state.weekendAdjustment != WeekendAdjustment.exact;

  /// The weekend-adjusted date on which the cycle anchored at (year, month)
  /// begins. The nominal start is `monthlyStartDay` clamped to the month's
  /// length; if that lands on a weekend it is shifted per [WeekendAdjustment].
  DateTime effectiveCycleStart(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = state.monthlyStartDay.clamp(1, daysInMonth);
    var d = DateTime(year, month, day);
    switch (state.weekendAdjustment) {
      case WeekendAdjustment.exact:
        break;
      case WeekendAdjustment.previousFriday:
        if (d.weekday == DateTime.saturday) {
          d = d.subtract(const Duration(days: 1));
        } else if (d.weekday == DateTime.sunday) {
          d = d.subtract(const Duration(days: 2));
        }
        break;
      case WeekendAdjustment.followingMonday:
        if (d.weekday == DateTime.saturday) {
          d = d.add(const Duration(days: 2));
        } else if (d.weekday == DateTime.sunday) {
          d = d.add(const Duration(days: 1));
        }
        break;
    }
    return DateTime(d.year, d.month, d.day);
  }

  /// First-of-month marker of the cycle that [date] falls within. A date
  /// earlier than its own month's cycle start belongs to the previous month's
  /// cycle.
  DateTime _anchorFor(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final thisStart = effectiveCycleStart(date.year, date.month);
    if (d.isBefore(thisStart)) {
      return DateTime(date.year, date.month - 1, 1);
    }
    return DateTime(date.year, date.month, 1);
  }

  /// Cycle window for the "financial month" labelled [year]-[month].
  ///
  /// The label follows the month the cycle *mostly* falls within, not the one
  /// it starts in: we anchor on whichever cycle contains the 15th of the
  /// month. So with a late start day (e.g. 30) the July window runs
  /// 30 Jun → 30 Jul (exclusive) instead of 30 Jul → 30 Aug — i.e. "this
  /// month" begins on the 30th of the *previous* month. Returns the inclusive
  /// start and the exclusive end (= the next cycle's start). With no custom
  /// cycle this is just the plain calendar month.
  ({DateTime start, DateTime end}) cycleWindowForMonth(int year, int month) {
    final anchor = _anchorFor(DateTime(year, month, 15));
    return (
      start: effectiveCycleStart(anchor.year, anchor.month),
      end: effectiveCycleStart(anchor.year, anchor.month + 1),
    );
  }

  /// Inclusive start of the currently selected cycle.
  DateTime get selectedCycleStart {
    final a = _anchorFor(state.selectedDate);
    return effectiveCycleStart(a.year, a.month);
  }

  /// Exclusive end of the currently selected cycle (= start of the next one).
  DateTime get selectedCycleEnd {
    final a = _anchorFor(state.selectedDate);
    return effectiveCycleStart(a.year, a.month + 1);
  }

  bool _inSelectedCycle(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(selectedCycleStart) && d.isBefore(selectedCycleEnd);
  }

  List<HomeRecord> get recordsForSelectedMonth {
    if (!hasCustomCycle) {
      final sel = state.selectedDate;
      return state.records
          .where((r) => r.date.year == sel.year && r.date.month == sel.month)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return state.records.where((r) => _inSelectedCycle(r.date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<HomeRecord> get _baseRecords {
    if (!state.showMonthlyCalendar) return allRecordsSorted;
    return state.viewMode == HomeViewMode.monthly
        ? recordsForSelectedMonth
        : allRecordsSorted;
  }

  List<HomeRecord> get filteredRecords {
    final records = _baseRecords;
    if (state.selectedCategoryIds.isEmpty) return records;
    return records
        .where((r) => state.selectedCategoryIds.contains(r.category.id))
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

  /// Like [monthlyTotals], but each bucket spans the custom monthly cycle
  /// (effective start date → next cycle start). The map key stays the anchor
  /// month (first-of-month) so callers label it as a plain month. When no
  /// custom cycle is set this is identical to [monthlyTotals].
  Map<DateTime, double> monthlyCycleTotals({int months = 12}) {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = months - 1; i >= 0; i--) {
      final anchor = DateTime(now.year, now.month - i, 1);
      final w = cycleWindowForMonth(anchor.year, anchor.month);
      final total = state.records.where((r) {
        final d = DateTime(r.date.year, r.date.month, r.date.day);
        return !d.isBefore(w.start) && d.isBefore(w.end);
      }).fold(0.0, (sum, r) => sum + r.amount);
      result[anchor] = total;
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

  /// Records whose `date` falls within `[start, end]` (inclusive), optionally
  /// restricted to a single category and/or payment-type id. Used by the
  /// analysis page to power the "tap a category to see its records" sheet.
  List<HomeRecord> recordsInRange(
    DateTime start,
    DateTime end, {
    HomeCategory? category,
    String? paymentTypeId,
  }) {
    final list = state.records.where((r) {
      if (r.date.isBefore(start) || r.date.isAfter(end)) return false;
      if (category != null && r.category.id != category.id) return false;
      if (paymentTypeId != null && r.paymentType?.id != paymentTypeId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Totals per payment-type within `[start, end]`. Records without a payment
  /// type are excluded (since `paymentType` is optional on `HomeRecord`).
  Map<PaymentType, double> paymentTotalsInRange(
    DateTime start,
    DateTime end, {
    HomeCategory? category,
  }) {
    final map = <PaymentType, double>{};
    for (final r in state.records) {
      if (r.date.isBefore(start) || r.date.isAfter(end)) continue;
      if (category != null && r.category.id != category.id) continue;
      final pt = r.paymentType;
      if (pt == null) continue;
      map[pt] = (map[pt] ?? 0) + r.amount;
    }
    return map;
  }

  /// Count of records in `[start, end]` that don't have a payment type
  /// recorded, used by the analysis page to surface "X records with no
  /// payment method" hint.
  int countUntaggedPaymentsInRange(
    DateTime start,
    DateTime end, {
    HomeCategory? category,
  }) {
    int n = 0;
    for (final r in state.records) {
      if (r.date.isBefore(start) || r.date.isAfter(end)) continue;
      if (category != null && r.category.id != category.id) continue;
      if (r.paymentType == null) n++;
    }
    return n;
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

  // ── Payment types ───────────────────────────────────────────────────────

  List<PaymentType> get paymentTypes => state.paymentTypes;

  bool isPaymentTypeInUse(String typeId) {
    return state.records.any((r) => r.paymentType?.id == typeId);
  }

  void addPaymentType(PaymentType type) {
    _repository.addPaymentType(type);
    emit(state.copyWith(paymentTypes: _repository.getPaymentTypes()));
  }

  /// Updating a payment type also rewrites the embedded snapshot on every
  /// record currently using that id, so existing records reflect the new
  /// name / icon / color rather than a stale copy.
  void updatePaymentType(PaymentType type) {
    _repository.updatePaymentType(type);
    final updatedRecords = state.records.map((r) {
      if (r.paymentType?.id == type.id) {
        final updated = r.copyWith(paymentType: type);
        _repository.update(updated);
        return updated;
      }
      return r;
    }).toList();
    emit(state.copyWith(
      paymentTypes: _repository.getPaymentTypes(),
      records: updatedRecords,
    ));
  }

  /// Removes the type from the user's managed list. Existing records keep
  /// the type snapshot they were saved with — they don't lose their label.
  void deletePaymentType(String typeId) {
    _repository.deletePaymentType(typeId);
    emit(state.copyWith(paymentTypes: _repository.getPaymentTypes()));
  }

  String get currencySymbol => state.currency.symbol;

  /// Format [amount] with the active currency's symbol and locale-aware
  /// thousands grouping (e.g. ₹1,23,456 for INR, $123,456 for USD).
  String formatAmount(double amount, {int decimals = 0}) =>
      state.currency.format(amount, decimals: decimals);

  void setCurrency(HomeCurrency currency) {
    _repository.setCurrencyCode(currency.code);
    emit(state.copyWith(currency: currency));
  }

  void setShowMonthlyCalendar(bool value) {
    _repository.setShowMonthlyCalendar(value);
    emit(state.copyWith(showMonthlyCalendar: value));
  }

  void setMonthlyStartDay(int day) {
    final clamped = day.clamp(1, 31);
    _repository.setMonthlyStartDay(clamped);
    emit(state.copyWith(monthlyStartDay: clamped));
  }

  void setWeekendAdjustment(WeekendAdjustment adjustment) {
    _repository.setWeekendAdjustment(adjustment.name);
    emit(state.copyWith(weekendAdjustment: adjustment));
  }

  /// Label for the currently selected period shown in the month navigator.
  /// Plain `MMM yyyy` for calendar months; an inclusive date range (e.g.
  /// `25 Jun – 24 Jul`) when a custom cycle is active.
  String get selectedPeriodLabel {
    if (!hasCustomCycle) {
      return DateFormat('MMM yyyy').format(state.selectedDate);
    }
    final start = selectedCycleStart;
    final lastDay = selectedCycleEnd.subtract(const Duration(days: 1));
    final sameYear = start.year == lastDay.year;
    final startFmt = DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy');
    return '${startFmt.format(start)} – ${DateFormat('d MMM yyyy').format(lastDay)}';
  }

  void toggleCalendarView() {
    final next = !state.isCalendarView;
    _repository.setIsCalendarView(next);
    emit(state.copyWith(isCalendarView: next));
  }

  /// Totals grouped by full date across the currently selected cycle,
  /// respecting the active category filter. Used by the month-grid calendar
  /// view, whose grid spans the cycle (which may cross calendar months when a
  /// custom start day is set), so totals are keyed by date — not day-of-month,
  /// which can repeat within a cycle.
  Map<DateTime, double> get dailyTotalsForSelectedCycle {
    final selected = state.selectedCategoryIds;
    final start = selectedCycleStart;
    final end = selectedCycleEnd;
    final out = <DateTime, double>{};
    for (final r in state.records) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      if (d.isBefore(start) || !d.isBefore(end)) continue;
      if (selected.isNotEmpty && !selected.contains(r.category.id)) continue;
      out[d] = (out[d] ?? 0) + r.amount;
    }
    return out;
  }

  /// Records on a specific date, respecting the active category filter.
  List<HomeRecord> recordsForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final selected = state.selectedCategoryIds;
    return state.records.where((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      if (d != target) return false;
      if (selected.isNotEmpty && !selected.contains(r.category.id)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Select a specific date (used by the calendar grid to drive the records
  /// list shown below it).
  void selectDate(DateTime date) {
    emit(state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    ));
  }

  /// Records on the currently selected day. Drives the records list shown
  /// under the month-grid calendar.
  List<HomeRecord> get recordsForSelectedDay =>
      recordsForDate(state.selectedDate);
}
