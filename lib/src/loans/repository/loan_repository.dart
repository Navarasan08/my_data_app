import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

abstract class LoanRepository implements SyncNode {
  List<Loan> getAll();
  void add(Loan loan);
  void update(Loan loan);
  void delete(String id);
}

class FirestoreLoanRepository extends SingleCollectionRepository<Loan>
    implements LoanRepository {
  FirestoreLoanRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'loans',
        fromDoc: (json, _) => Loan.fromJson(json),
        toJson: (l) => l.toJson(),
        idOf: (l) => l.id,
      );

  @override
  void add(Loan loan) => store.save(loan);

  @override
  void update(Loan loan) => store.save(loan);

  @override
  void delete(String id) => store.remove(id);
}
