import 'package:my_data_app/src/reminder/model/bill_model.dart';

abstract class BillRepository {
  List<BillTask> getAll();
  void add(BillTask task);
  void update(BillTask task);
  void delete(String taskId);
}

class InMemoryBillRepository implements BillRepository {
  final List<BillTask> _tasks;

  InMemoryBillRepository()
      : _tasks = [
          BillTask(
            id: '1',
            title: 'Electricity Bill',
            description: 'Monthly electricity payment',
            amount: 120.50,
            recurrence: RecurrenceType.monthly,
            createdDate: DateTime(2024, 1, 5),
          ),
          BillTask(
            id: '2',
            title: 'Gym Membership',
            description: 'Weekly gym payment',
            amount: 25.00,
            recurrence: RecurrenceType.weekly,
            createdDate: DateTime(2024, 1, 1),
          ),
          BillTask(
            id: '3',
            title: 'Take Vitamins',
            description: 'Daily health routine',
            recurrence: RecurrenceType.daily,
            createdDate: DateTime.now(),
          ),
        ];

  @override
  List<BillTask> getAll() => List.unmodifiable(_tasks);

  @override
  void add(BillTask task) {
    _tasks.add(task);
  }

  @override
  void update(BillTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  void delete(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
  }
}
