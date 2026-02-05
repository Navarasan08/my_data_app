import 'package:my_data_app/src/chits/model/chit_model.dart';

class ChitState {
  final List<ChitFund> chitFunds;

  const ChitState({required this.chitFunds});

  ChitState copyWith({List<ChitFund>? chitFunds}) {
    return ChitState(chitFunds: chitFunds ?? this.chitFunds);
  }
}
