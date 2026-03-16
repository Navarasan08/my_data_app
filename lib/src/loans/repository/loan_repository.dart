import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

abstract class LoanRepository {
  List<Loan> getAll();
  void add(Loan loan);
  void update(Loan loan);
  void delete(String id);
  Future<void> init();
}

class FirestoreLoanRepository implements LoanRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<Loan> _loans = [];

  FirestoreLoanRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('loans');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _loans = snapshot.docs
        .map((doc) => Loan.fromJson(doc.data()))
        .toList();
  }

  @override
  List<Loan> getAll() => List.unmodifiable(_loans);

  @override
  void add(Loan loan) {
    _loans.add(loan);
    _collection.doc(loan.id).set(loan.toJson());
  }

  @override
  void update(Loan loan) {
    final index = _loans.indexWhere((l) => l.id == loan.id);
    if (index != -1) {
      _loans[index] = loan;
      _collection.doc(loan.id).set(loan.toJson());
    }
  }

  @override
  void delete(String id) {
    _loans.removeWhere((l) => l.id == id);
    _collection.doc(id).delete();
  }
}
