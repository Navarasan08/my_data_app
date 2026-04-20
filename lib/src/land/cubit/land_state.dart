import 'package:my_data_app/src/land/model/land_model.dart';

class LandState {
  final List<LandRecord> records;

  const LandState({required this.records});

  LandState copyWith({List<LandRecord>? records}) =>
      LandState(records: records ?? this.records);
}
