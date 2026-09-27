import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/land/model/land_model.dart';
import 'package:my_data_app/src/land/repository/land_repository.dart';
import 'package:my_data_app/src/land/cubit/land_state.dart';

class LandCubit extends Cubit<LandState> {
  final LandRepository _repository;
  StreamSubscription<void>? _sub;

  LandCubit(this._repository)
    : super(
        LandState(
          records: _repository.getAll(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current list and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        records: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  void addRecord(LandRecord record) {
    _repository.add(record);
    _sync();
  }

  void updateRecord(LandRecord record) {
    _repository.update(record);
    _sync();
  }

  void deleteRecord(String id) {
    _repository.delete(id);
    _sync();
  }

  void toggleFavorite(String id) {
    final r = state.records.firstWhere((x) => x.id == id);
    updateRecord(
      r.copyWith(isFavorite: !r.isFavorite, updatedAt: DateTime.now()),
    );
  }

  LandRecord? getById(String id) {
    final matches = state.records.where((r) => r.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<LandRecord> get sortedByFavorite {
    final list = List<LandRecord>.from(state.records);
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  double get totalValue =>
      state.records.fold(0.0, (sum, r) => sum + (r.currentMarketValue ?? 0));
}
