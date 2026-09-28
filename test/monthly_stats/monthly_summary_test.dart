import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';
import 'package:my_data_app/src/monthly_stats/monthly_summary.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

// September 2026 is the month under test throughout.
final month = DateTime(2026, 9);

MonthlySummary compute({
  List<HomeRecord> records = const [],
  List<Bill> bills = const [],
  List<Loan> loans = const [],
  List<DebtEntry> debts = const [],
  List<Vehicle> vehicles = const [],
  List<ChitFund> chitFunds = const [],
  List<InterestRecord> interestRecords = const [],
  ({DateTime start, DateTime end})? homeWindow,
}) {
  return MonthlySummary.compute(
    month: month,
    homeWindow:
        homeWindow ?? (start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1)),
    records: records,
    bills: bills,
    loans: loans,
    debts: debts,
    vehicles: vehicles,
    chitFunds: chitFunds,
    interestRecords: interestRecords,
  );
}

HomeRecord homeRecord({
  required String id,
  required double amount,
  required DateTime date,
  HomeCategory? category,
  bool isIncome = false,
}) {
  return HomeRecord(
    id: id,
    title: id,
    category:
        category ?? (isIncome ? HomeCategory.salary : HomeCategory.groceries),
    amount: amount,
    date: date,
    isIncome: isIncome,
  );
}

MonthlyStatItem itemById(MonthlySummary s, String id) =>
    s.items.firstWhere((i) => i.id == id);

void main() {
  group('income', () {
    test('splits salary from other income within the home window', () {
      final s = compute(
        records: [
          homeRecord(
            id: 'sal',
            amount: 50000,
            date: DateTime(2026, 9, 1),
            isIncome: true,
          ),
          homeRecord(
            id: 'gift',
            amount: 2000,
            date: DateTime(2026, 9, 10),
            category: HomeCategory.giftIncome,
            isIncome: true,
          ),
          // Outside the month: ignored.
          homeRecord(
            id: 'old',
            amount: 45000,
            date: DateTime(2026, 8, 1),
            isIncome: true,
          ),
        ],
      );
      expect(itemById(s, 'salary').amount, 50000);
      expect(itemById(s, 'other_income').amount, 2000);
      expect(s.totalIncome, 52000);
    });

    test('uses the custom cycle window, not the calendar month', () {
      final s = compute(
        homeWindow: (start: DateTime(2026, 8, 30), end: DateTime(2026, 9, 30)),
        records: [
          homeRecord(
            id: 'sal',
            amount: 40000,
            date: DateTime(2026, 8, 30),
            isIncome: true,
          ),
          homeRecord(
            id: 'next',
            amount: 40000,
            date: DateTime(2026, 9, 30),
            isIncome: true,
          ),
        ],
      );
      // 30 Aug is inside the window; 30 Sep (the exclusive end) is not.
      expect(itemById(s, 'salary').amount, 40000);
    });
  });

  group('expenses', () {
    test('sums non-income records in the window', () {
      final s = compute(
        records: [
          homeRecord(id: 'a', amount: 1200, date: DateTime(2026, 9, 5)),
          homeRecord(id: 'b', amount: 800, date: DateTime(2026, 9, 20)),
          homeRecord(id: 'c', amount: 999, date: DateTime(2026, 10, 1)),
        ],
      );
      expect(itemById(s, 'expenses').amount, 2000);
    });
  });

  group('bills', () {
    test('counts active bills with paid progress', () {
      final s = compute(
        bills: [
          Bill(
            id: 'b1',
            name: 'Rent',
            amount: 12000,
            dueDate: DateTime(2026, 1, 5),
            createdDate: DateTime(2026, 1, 1),
            paidMonths: [DateTime(2026, 9)],
          ),
          Bill(
            id: 'b2',
            name: 'Internet',
            amount: 800,
            dueDate: DateTime(2026, 1, 10),
            createdDate: DateTime(2026, 1, 1),
          ),
          // Starts next month: not active in September.
          Bill(
            id: 'b3',
            name: 'New EMI',
            amount: 5000,
            dueDate: DateTime(2026, 10, 1),
            createdDate: DateTime(2026, 9, 1),
          ),
        ],
      );
      final bills = itemById(s, 'bills');
      expect(bills.amount, 12800);
      expect(bills.detail, '1 of 2 paid');
    });
  });

  group('loan EMIs', () {
    Loan loan({
      required String id,
      required DateTime start,
      int tenure = 12,
      double emi = 10000,
      bool isClosed = false,
      LoanDirection direction = LoanDirection.borrowed,
    }) {
      return Loan(
        id: id,
        name: id,
        type: LoanType.personal,
        direction: direction,
        principalAmount: 100000,
        interestRate: 10,
        tenureMonths: tenure,
        emiAmount: emi,
        startDate: start,
        isClosed: isClosed,
      );
    }

    test('includes EMIs whose schedule covers the month', () {
      final s = compute(
        loans: [
          // Started Aug 2026 → EMI 1 due Sep: included.
          loan(id: 'l1', start: DateTime(2026, 8, 10)),
          // Started Sep 2026 → first EMI due Oct: excluded.
          loan(id: 'l2', start: DateTime(2026, 9, 1)),
          // 12-month tenure ending before Sep 2026: excluded.
          loan(id: 'l3', start: DateTime(2025, 1, 1)),
          // Closed: excluded.
          loan(id: 'l4', start: DateTime(2026, 8, 1), isClosed: true),
          // Lent, not borrowed: excluded.
          loan(
            id: 'l5',
            start: DateTime(2026, 8, 1),
            direction: LoanDirection.lent,
          ),
        ],
      );
      final emis = itemById(s, 'loans');
      expect(emis.amount, 10000);
      expect(emis.detail, '1 EMI');
    });
  });

  group('chit contributions', () {
    test('participant pays what is due this month, owner pays while active',
        () {
      Payment payment({required DateTime due, double amount = 5000}) => Payment(
        id: 'p${due.month}',
        memberId: 'me',
        monthNumber: due.month,
        amount: amount,
        dueDate: due,
      );
      final s = compute(
        chitFunds: [
          ChitFund(
            id: 'c1',
            name: 'Participant chit',
            role: ChitRole.participant,
            totalAmount: 100000,
            totalMembers: 20,
            durationMonths: 20,
            monthlyContribution: 5000,
            startDate: DateTime(2026, 1, 1),
            status: ChitStatus.active,
            members: [
              Member(
                id: 'me',
                name: 'Me',
                joinedDate: DateTime(2026, 1, 1),
                payments: [
                  payment(due: DateTime(2026, 9, 5)),
                  payment(due: DateTime(2026, 10, 5)),
                ],
              ),
            ],
          ),
          ChitFund(
            id: 'c2',
            name: 'Own chit',
            role: ChitRole.owner,
            totalAmount: 60000,
            totalMembers: 12,
            durationMonths: 12,
            monthlyContribution: 3000,
            startDate: DateTime(2026, 1, 1),
            status: ChitStatus.active,
          ),
        ],
      );
      final chits = itemById(s, 'chits');
      expect(chits.amount, 8000);
      expect(chits.detail, '2 chits');
    });
  });

  group('interest payable', () {
    test('monthly interest on open borrowed principals only', () {
      InterestRecord record({
        required String id,
        required InterestDirection direction,
        bool isClosed = false,
      }) {
        return InterestRecord(
          id: id,
          direction: direction,
          personName: id,
          principal: 100000,
          interestRate: 2,
          rateUnit: RateUnit.perMonth,
          startDate: DateTime(2026, 1, 1),
          isClosed: isClosed,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
      }

      final s = compute(
        interestRecords: [
          record(id: 'i1', direction: InterestDirection.borrowed),
          record(id: 'i2', direction: InterestDirection.lent),
          record(
            id: 'i3',
            direction: InterestDirection.borrowed,
            isClosed: true,
          ),
        ],
      );
      expect(itemById(s, 'interest').amount, 2000);
    });
  });

  group('debts to pay', () {
    DebtEntry debt({
      required String id,
      required DebtDirection direction,
      DateTime? dueDate,
      double amount = 3000,
      List<DebtSettlement> settlements = const [],
    }) {
      return DebtEntry(
        id: id,
        personName: id,
        direction: direction,
        amount: amount,
        date: DateTime(2026, 1, 1),
        dueDate: dueDate,
        settlements: settlements,
      );
    }

    test('borrowed pending amounts due by the end of the month', () {
      final s = compute(
        debts: [
          // Due this month.
          debt(
            id: 'd1',
            direction: DebtDirection.borrowed,
            dueDate: DateTime(2026, 9, 15),
          ),
          // Overdue from earlier: still to pay.
          debt(
            id: 'd2',
            direction: DebtDirection.borrowed,
            dueDate: DateTime(2026, 7, 1),
            settlements: [
              DebtSettlement(
                id: 's1',
                amount: 1000,
                date: DateTime(2026, 8, 1),
              ),
            ],
          ),
          // Due next month: not this month's problem.
          debt(
            id: 'd3',
            direction: DebtDirection.borrowed,
            dueDate: DateTime(2026, 10, 2),
          ),
          // Lent out: money owed to me, not by me.
          debt(
            id: 'd4',
            direction: DebtDirection.lent,
            dueDate: DateTime(2026, 9, 1),
          ),
          // No due date: excluded from the monthly tally.
          debt(id: 'd5', direction: DebtDirection.borrowed),
        ],
      );
      final debtsItem = itemById(s, 'debts');
      expect(debtsItem.amount, 3000 + 2000);
      expect(debtsItem.detail, '2 people');
    });
  });

  group('vehicle expenses', () {
    test('sums this month\'s records and counts fuel fills', () {
      final s = compute(
        vehicles: [
          Vehicle(
            id: 'v1',
            name: 'Bike',
            brand: 'B',
            model: 'M',
            year: '2020',
            registrationNumber: 'TN 01',
            purchaseDate: DateTime(2020, 1, 1),
            records: [
              VehicleRecord(
                id: 'r1',
                type: RecordType.fuel,
                date: DateTime(2026, 9, 3),
                title: 'Petrol',
                amount: 500,
              ),
              VehicleRecord(
                id: 'r2',
                type: RecordType.service,
                date: DateTime(2026, 9, 12),
                title: 'Service',
                amount: 1500,
              ),
              VehicleRecord(
                id: 'r3',
                type: RecordType.fuel,
                date: DateTime(2026, 8, 28),
                title: 'Petrol',
                amount: 400,
              ),
              // No amount: a note, not an expense.
              VehicleRecord(
                id: 'r4',
                type: RecordType.note,
                date: DateTime(2026, 9, 5),
                title: 'Note',
              ),
            ],
          ),
        ],
      );
      final vehicle = itemById(s, 'vehicle');
      expect(vehicle.amount, 2000);
      expect(vehicle.detail, '1 fuel fill');
    });
  });

  group('tally', () {
    test('balance is income minus every outgoing item', () {
      final s = compute(
        records: [
          homeRecord(
            id: 'sal',
            amount: 50000,
            date: DateTime(2026, 9, 1),
            isIncome: true,
          ),
          homeRecord(id: 'exp', amount: 12000, date: DateTime(2026, 9, 10)),
        ],
        bills: [
          Bill(
            id: 'b1',
            name: 'Rent',
            amount: 10000,
            dueDate: DateTime(2026, 1, 5),
            createdDate: DateTime(2026, 1, 1),
          ),
        ],
      );
      expect(s.totalIncome, 50000);
      expect(s.totalOutgoing, 22000);
      expect(s.balance, 28000);
      expect(s.isEmpty, isFalse);
    });

    test('isEmpty when nothing has any amount', () {
      expect(compute().isEmpty, isTrue);
    });
  });
}
