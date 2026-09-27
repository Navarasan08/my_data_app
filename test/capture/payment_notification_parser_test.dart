import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/capture/payment_notification_parser.dart';

void main() {
  const gpay = 'com.google.android.apps.nbu.paisa.user';
  const phonepe = 'com.phonepe.app';
  const paytm = 'net.one97.paytm';

  group('PaymentNotificationParser', () {
    test('parses a GPay debit', () {
      final p = PaymentNotificationParser.parse(
        packageName: gpay,
        title: 'You paid ₹250 to Ravi Stores',
        text: null,
      );
      expect(p, isNotNull);
      expect(p!.amount, 250);
      expect(p.counterparty, 'Ravi Stores');
      expect(p.isIncome, false);
      expect(p.sourceApp, 'GPay');
    });

    test('parses a PhonePe debit with amount in text', () {
      final p = PaymentNotificationParser.parse(
        packageName: phonepe,
        title: 'Payment successful',
        text: 'Paid ₹1,250.50 to Big Bazaar via UPI',
      );
      expect(p, isNotNull);
      expect(p!.amount, 1250.50);
      expect(p.counterparty, 'Big Bazaar');
      expect(p.isIncome, false);
      expect(p.sourceApp, 'PhonePe');
    });

    test('parses a credit as income', () {
      final p = PaymentNotificationParser.parse(
        packageName: gpay,
        title: 'You received ₹5,000 from Anitha',
        text: null,
      );
      expect(p, isNotNull);
      expect(p!.amount, 5000);
      expect(p.counterparty, 'Anitha');
      expect(p.isIncome, true);
    });

    test('parses Rs. amount format', () {
      final p = PaymentNotificationParser.parse(
        packageName: paytm,
        title: 'Paid Rs. 99 to Jio Recharge',
        text: null,
      );
      expect(p, isNotNull);
      expect(p!.amount, 99);
      expect(p.counterparty, 'Jio Recharge');
    });

    test('strips a trailing UPI id from the name', () {
      final p = PaymentNotificationParser.parse(
        packageName: gpay,
        title: 'You paid ₹40 to Tea Shop (chai@oksbi)',
        text: null,
      );
      expect(p, isNotNull);
      expect(p!.counterparty, 'Tea Shop');
    });

    test('rejects unknown packages', () {
      final p = PaymentNotificationParser.parse(
        packageName: 'com.random.app',
        title: 'You paid ₹250 to Someone',
        text: null,
      );
      expect(p, isNull);
    });

    test('rejects failed payments', () {
      final p = PaymentNotificationParser.parse(
        packageName: phonepe,
        title: 'Payment of ₹250 to Ravi failed',
        text: null,
      );
      expect(p, isNull);
    });

    test('rejects money requests', () {
      final p = PaymentNotificationParser.parse(
        packageName: gpay,
        title: 'Ravi is requesting ₹500',
        text: null,
      );
      expect(p, isNull);
    });

    test('rejects promos and offers', () {
      final p = PaymentNotificationParser.parse(
        packageName: paytm,
        title: 'Earn ₹100 cashback — scratch now!',
        text: null,
      );
      expect(p, isNull);
    });

    test('rejects text without an amount or direction', () {
      expect(
        PaymentNotificationParser.parse(
          packageName: gpay,
          title: 'Security alert',
          text: 'New login to your account',
        ),
        isNull,
      );
      expect(
        PaymentNotificationParser.parse(
          packageName: gpay,
          title: 'Your balance is ₹1,000',
          text: null,
        ),
        isNull,
      );
    });

    test('handles a missing counterparty gracefully', () {
      final p = PaymentNotificationParser.parse(
        packageName: phonepe,
        title: 'Sent ₹200 successfully',
        text: null,
      );
      expect(p, isNotNull);
      expect(p!.amount, 200);
      expect(p.counterparty, '');
    });
  });
}
