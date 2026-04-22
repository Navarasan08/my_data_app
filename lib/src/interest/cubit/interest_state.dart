import 'package:my_data_app/src/interest/model/interest_model.dart';

class InterestState {
  final List<InterestRecord> records;
  const InterestState({required this.records});
  InterestState copyWith({List<InterestRecord>? records}) =>
      InterestState(records: records ?? this.records);
}
