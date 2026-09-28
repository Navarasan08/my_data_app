import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

String _fmt(double v) => NumberFormat('#,##,###', 'en_IN').format(v.round());

/// Create or edit a loan. Terms are entered once; the live preview at the
/// bottom of the Terms section shows the derived EMI, total payable and
/// total interest as the numbers change.
class AddLoanPage extends StatefulWidget {
  final Loan? loan;
  const AddLoanPage({super.key, this.loan});

  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _emiController = TextEditingController();
  final _lenderController = TextEditingController();
  final _accountController = TextEditingController();
  final _notesController = TextEditingController();

  LoanType _type = LoanType.personal;
  LoanDirection _direction = LoanDirection.borrowed;
  DateTime _startDate = DateTime.now();
  bool _emiManuallyEdited = false;

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    if (l != null) {
      _nameController.text = l.name;
      _principalController.text = l.principalAmount.toStringAsFixed(0);
      _rateController.text = l.interestRate.toString();
      _tenureController.text = l.tenureMonths.toString();
      _emiController.text = l.emiAmount.toStringAsFixed(2);
      _lenderController.text = l.lenderOrBorrower ?? '';
      _accountController.text = l.accountNumber ?? '';
      _notesController.text = l.notes ?? '';
      _type = l.type;
      _direction = l.direction;
      _startDate = l.startDate;
      _emiManuallyEdited = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _emiController.dispose();
    _lenderController.dispose();
    _accountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTermsChanged() {
    if (!_emiManuallyEdited) {
      final p = double.tryParse(_principalController.text);
      final r = double.tryParse(_rateController.text);
      final t = int.tryParse(_tenureController.text);
      if (p != null && r != null && t != null && t > 0) {
        _emiController.text = Loan.calculateEmi(p, r, t).toStringAsFixed(2);
      }
    }
    setState(() {}); // refresh the preview card
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final loan = Loan(
      id: widget.loan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _type,
      direction: _direction,
      principalAmount: double.parse(_principalController.text),
      interestRate: double.parse(_rateController.text),
      tenureMonths: int.parse(_tenureController.text),
      emiAmount: double.tryParse(_emiController.text) ?? 0,
      startDate: _startDate,
      lenderOrBorrower: _lenderController.text.trim().isEmpty
          ? null
          : _lenderController.text.trim(),
      accountNumber: _accountController.text.trim().isEmpty
          ? null
          : _accountController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isClosed: widget.loan?.isClosed ?? false,
      repayments: widget.loan?.repayments ?? [],
    );

    Navigator.pop(context, loan);
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final principal = double.tryParse(_principalController.text);
    final tenure = int.tryParse(_tenureController.text);
    final emi = double.tryParse(_emiController.text);
    final totalPayable =
        (emi != null && tenure != null && tenure > 0) ? emi * tenure : null;
    final totalInterest = (totalPayable != null && principal != null)
        ? (totalPayable - principal).clamp(0.0, double.infinity)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Loan' : 'Add Loan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionLabel('Basics'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec('Loan Name *', Icons.label_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LoanType>(
              initialValue: _type,
              decoration: _dec('Loan Type', Icons.category_outlined),
              items: LoanType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 18, color: t.color),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<LoanDirection>(
              segments: const [
                ButtonSegment(
                  value: LoanDirection.borrowed,
                  label: Text('I borrowed'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: LoanDirection.lent,
                  label: Text('I lent'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 20),

            _SectionLabel('Terms'),
            TextFormField(
              controller: _principalController,
              decoration: _dec('Principal Amount *', Icons.currency_rupee),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
              onChanged: (_) => _onTermsChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: _dec('Rate % / yr *', Icons.percent),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = double.tryParse(v);
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => _onTermsChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tenureController,
                    decoration: _dec('Months *', Icons.timelapse_rounded),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => _onTermsChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emiController,
              decoration: _dec(
                'EMI Amount',
                Icons.payment_rounded,
                suffix: _emiManuallyEdited
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Auto-calculate',
                        onPressed: () {
                          _emiManuallyEdited = false;
                          _onTermsChanged();
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) {
                _emiManuallyEdited = true;
                setState(() {});
              },
            ),
            if (totalPayable != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PreviewStat(
                        label: 'EMI / month',
                        value: '₹${_fmt(emi!)}',
                      ),
                    ),
                    Expanded(
                      child: _PreviewStat(
                        label: 'Total payable',
                        value: '₹${_fmt(totalPayable)}',
                      ),
                    ),
                    Expanded(
                      child: _PreviewStat(
                        label: 'Total interest',
                        value: '₹${_fmt(totalInterest ?? 0)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            _SectionLabel('Details'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2040),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _lenderController,
              textCapitalization: TextCapitalization.words,
              decoration: _dec(
                _direction == LoanDirection.borrowed
                    ? 'Lender Name'
                    : 'Borrower Name',
                Icons.person_outline,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountController,
              decoration: _dec('Account Number (optional)', Icons.numbers),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: _dec('Notes (optional)', Icons.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _isEditing ? 'Update Loan' : 'Save Loan',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Record one EMI payment or a part payment against a loan.
class AddRepaymentPage extends StatefulWidget {
  final String loanId;
  final int nextMonthNumber;
  final double emiAmount;
  final bool isPartPayment;

  const AddRepaymentPage({
    super.key,
    required this.loanId,
    required this.nextMonthNumber,
    this.emiAmount = 0,
    this.isPartPayment = false,
  });

  @override
  State<AddRepaymentPage> createState() => _AddRepaymentPageState();
}

class _AddRepaymentPageState extends State<AddRepaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _amountController;
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paidDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController(
      text: widget.isPartPayment ? '0' : widget.nextMonthNumber.toString(),
    );
    _amountController = TextEditingController(
      text: widget.isPartPayment ? '' : widget.emiAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final repayment = Repayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      monthNumber: widget.isPartPayment ? 0 : int.parse(_monthController.text),
      amount: amount,
      principalPortion: widget.isPartPayment
          ? amount
          : (_principalController.text.isNotEmpty
                ? double.tryParse(_principalController.text)
                : null),
      interestPortion: widget.isPartPayment
          ? 0
          : (_interestController.text.isNotEmpty
                ? double.tryParse(_interestController.text)
                : null),
      paidDate: _paidDate,
      notes: _notesController.text.trim().isEmpty
          ? (widget.isPartPayment ? 'Part payment' : null)
          : _notesController.text.trim(),
      isPartPayment: widget.isPartPayment,
    );

    Navigator.pop(context, repayment);
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPartPayment ? 'Part Payment' : 'Record EMI Payment',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (widget.isPartPayment)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.savings_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A part payment goes straight against the '
                        'outstanding principal.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!widget.isPartPayment) ...[
              TextFormField(
                controller: _monthController,
                decoration: _dec('Month Number *', Icons.tag),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _amountController,
              decoration: _dec(
                widget.isPartPayment
                    ? 'Part Payment Amount *'
                    : 'EMI Amount *',
                Icons.currency_rupee,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            if (!widget.isPartPayment) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _principalController,
                      decoration: _dec(
                        'Principal part',
                        Icons.account_balance_wallet_outlined,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _interestController,
                      decoration: _dec('Interest part', Icons.percent),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Leave the split empty to work it out automatically.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Paid Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_paidDate)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _paidDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2040),
                );
                if (date != null) setState(() => _paidDate = date);
              },
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _notesController,
              decoration: _dec('Notes (optional)', Icons.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: widget.isPartPayment ? Colors.green : null,
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                widget.isPartPayment
                    ? 'Record Part Payment'
                    : 'Record EMI Payment',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
