import 'package:my_data_app/src/checklist/model/checklist_model.dart';

class ChecklistState {
  final List<ChecklistGroup> checklists;

  const ChecklistState({required this.checklists});

  ChecklistState copyWith({List<ChecklistGroup>? checklists}) {
    return ChecklistState(checklists: checklists ?? this.checklists);
  }
}
