import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';

class MoneyOweState {
  final List<DebtEntry> entries;

  const MoneyOweState({required this.entries});

  MoneyOweState copyWith({List<DebtEntry>? entries}) =>
      MoneyOweState(entries: entries ?? this.entries);
}
