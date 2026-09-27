import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:my_data_app/src/home/home_record_model.dart';

const testUid = 'u1';

HomeCategory customCategory({
  String id = 'cat_custom',
  String name = 'Gym',
  int iconIndex = 3,
  int colorIndex = 2,
}) => HomeCategory(
  id: id,
  displayName: name,
  iconIndex: iconIndex,
  colorIndex: colorIndex,
  isCustom: true,
);

HomeRecord record({
  required String id,
  String title = 'Coffee',
  HomeCategory? category,
  double amount = 120,
  DateTime? date,
  PaymentType? paymentType,
  bool isIncome = false,
}) => HomeRecord(
  id: id,
  title: title,
  category: category ?? HomeCategory.defaults.first,
  amount: amount,
  date: date ?? DateTime(2026, 9, 15),
  paymentType: paymentType,
  isIncome: isIncome,
);

/// A fake Firestore pre-populated for [testUid] so the payment-type seeding
/// path is not exercised unless a test asks for it.
FakeFirebaseFirestore seededFirestore({bool paymentTypesSeeded = true}) {
  final fs = FakeFirebaseFirestore();
  if (paymentTypesSeeded) {
    fs
        .collection('users')
        .doc(testUid)
        .collection('home_settings')
        .doc('prefs')
        .set({'paymentTypesSeeded': true});
  }
  return fs;
}
