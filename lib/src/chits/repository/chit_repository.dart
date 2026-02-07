import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';

abstract class ChitRepository {
  List<ChitFund> getAll();
  void add(ChitFund chitFund);
  void update(ChitFund chitFund);
  void delete(String chitFundId);
  Future<void> init();
}

class InMemoryChitRepository implements ChitRepository {
  final List<ChitFund> _chitFunds;

  InMemoryChitRepository()
      : _chitFunds = [
          ChitFund(
            id: '1',
            name: 'Family Chit Group',
            totalAmount: 100000,
            totalMembers: 20,
            durationMonths: 20,
            monthlyContribution: 5000,
            startDate: DateTime(2024, 1, 1),
            status: ChitStatus.active,
            description: 'Monthly family chit fund group',
            members: [
              Member(
                id: '1',
                name: 'John Doe',
                phone: '+1234567890',
                isOrganizer: true,
                joinedDate: DateTime(2024, 1, 1),
              ),
              Member(
                id: '2',
                name: 'Jane Smith',
                phone: '+1234567891',
                joinedDate: DateTime(2024, 1, 1),
              ),
            ],
            auctions: [
              Auction(
                id: '1',
                monthNumber: 1,
                auctionDate: DateTime(2024, 1, 15),
                winnerId: '1',
                winnerName: 'John Doe',
                bidAmount: 8000,
                discountAmount: 2000,
                amountReceived: 98000,
              ),
            ],
          ),
        ];

  @override
  Future<void> init() async {}

  @override
  List<ChitFund> getAll() => List.unmodifiable(_chitFunds);

  @override
  void add(ChitFund chitFund) {
    _chitFunds.add(chitFund);
  }

  @override
  void update(ChitFund chitFund) {
    final index = _chitFunds.indexWhere((c) => c.id == chitFund.id);
    if (index != -1) {
      _chitFunds[index] = chitFund;
    }
  }

  @override
  void delete(String chitFundId) {
    _chitFunds.removeWhere((c) => c.id == chitFundId);
  }
}

class LocalStorageChitRepository implements ChitRepository {
  static const String _storageKey = 'chits_data';
  final SharedPreferences _prefs;
  List<ChitFund> _chitFunds = [];

  LocalStorageChitRepository(this._prefs);

  @override
  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _chitFunds = jsonList
          .map((item) => ChitFund.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Initialize with seed data if empty
      _chitFunds = [
        ChitFund(
          id: '1',
          name: 'Family Chit Group',
          totalAmount: 100000,
          totalMembers: 20,
          durationMonths: 20,
          monthlyContribution: 5000,
          startDate: DateTime(2024, 1, 1),
          status: ChitStatus.active,
          description: 'Monthly family chit fund group',
          members: [
            Member(
              id: '1',
              name: 'John Doe',
              phone: '+1234567890',
              isOrganizer: true,
              joinedDate: DateTime(2024, 1, 1),
            ),
            Member(
              id: '2',
              name: 'Jane Smith',
              phone: '+1234567891',
              joinedDate: DateTime(2024, 1, 1),
            ),
          ],
          auctions: [
            Auction(
              id: '1',
              monthNumber: 1,
              auctionDate: DateTime(2024, 1, 15),
              winnerId: '1',
              winnerName: 'John Doe',
              bidAmount: 8000,
              discountAmount: 2000,
              amountReceived: 98000,
            ),
          ],
        ),
      ];
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final jsonList = _chitFunds.map((chitFund) => chitFund.toJson()).toList();
    await _prefs.setString(_storageKey, json.encode(jsonList));
  }

  @override
  List<ChitFund> getAll() => List.unmodifiable(_chitFunds);

  @override
  void add(ChitFund chitFund) {
    _chitFunds.add(chitFund);
    _saveToStorage();
  }

  @override
  void update(ChitFund chitFund) {
    final index = _chitFunds.indexWhere((c) => c.id == chitFund.id);
    if (index != -1) {
      _chitFunds[index] = chitFund;
      _saveToStorage();
    }
  }

  @override
  void delete(String chitFundId) {
    _chitFunds.removeWhere((c) => c.id == chitFundId);
    _saveToStorage();
  }
}

class FirestoreChitRepository implements ChitRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<ChitFund> _chitFunds = [];

  FirestoreChitRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('chits');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _chitFunds = snapshot.docs
        .map((doc) => ChitFund.fromJson(doc.data()))
        .toList();
  }

  @override
  List<ChitFund> getAll() => List.unmodifiable(_chitFunds);

  @override
  void add(ChitFund chitFund) {
    _chitFunds.add(chitFund);
    _collection.doc(chitFund.id).set(chitFund.toJson());
  }

  @override
  void update(ChitFund chitFund) {
    final index = _chitFunds.indexWhere((c) => c.id == chitFund.id);
    if (index != -1) {
      _chitFunds[index] = chitFund;
      _collection.doc(chitFund.id).set(chitFund.toJson());
    }
  }

  @override
  void delete(String chitFundId) {
    _chitFunds.removeWhere((c) => c.id == chitFundId);
    _collection.doc(chitFundId).delete();
  }
}
