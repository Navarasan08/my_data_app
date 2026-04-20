import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/land/model/land_model.dart';
import 'package:my_data_app/src/land/repository/land_repository.dart';
import 'package:my_data_app/src/land/cubit/land_state.dart';

class LandCubit extends Cubit<LandState> {
  final LandRepository _repository;

  LandCubit(this._repository)
      : super(LandState(records: _repository.getAll()));

  void addRecord(LandRecord record) {
    _repository.add(record);
    emit(state.copyWith(records: _repository.getAll()));
  }

  void updateRecord(LandRecord record) {
    _repository.update(record);
    emit(state.copyWith(records: _repository.getAll()));
  }

  void deleteRecord(String id) {
    _repository.delete(id);
    emit(state.copyWith(records: _repository.getAll()));
  }

  void toggleFavorite(String id) {
    final r = state.records.firstWhere((x) => x.id == id);
    updateRecord(r.copyWith(
      isFavorite: !r.isFavorite,
      updatedAt: DateTime.now(),
    ));
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

  double get totalValue => state.records
      .fold(0.0, (sum, r) => sum + (r.currentMarketValue ?? 0));
}
