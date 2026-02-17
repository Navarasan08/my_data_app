import 'package:my_data_app/src/home/home_record_model.dart';

class HomeRecordState {
  final List<HomeRecord> records;
  final DateTime selectedDate;
  final HomeCategory? selectedCategory;

  const HomeRecordState({
    required this.records,
    required this.selectedDate,
    this.selectedCategory,
  });

  HomeRecordState copyWith({
    List<HomeRecord>? records,
    DateTime? selectedDate,
    HomeCategory? selectedCategory,
    bool clearCategory = false,
  }) {
    return HomeRecordState(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }
}
