import 'package:flutter/material.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';

/// Section-specific physical-style visualisation for a [VaultEntry]. Used
/// wherever an entry appears (favourites, section list, etc.) so each entry
/// "looks like" the real-world object it represents: cards as credit cards,
/// government IDs as ID cards, contacts as contact tiles, and so on.
///
/// Sensitive fields are masked by default; tapping the eye icon flips a
/// per-card reveal flag.
class VaultEntryVisual extends StatefulWidget {
  final VaultEntry entry;
  final VoidCallback? onTap;
  final Widget? trailing;

  const VaultEntryVisual({
    super.key,
    required this.entry,
    this.onTap,
    this.trailing,
  });

  @override
  State<VaultEntryVisual> createState() => _VaultEntryVisualState();
}

class _VaultEntryVisualState extends State<VaultEntryVisual> {
  bool _revealed = false;

  void _toggleReveal() => setState(() => _revealed = !_revealed);

  String? _f(String key) {
    final v = widget.entry.fields[key];
    return (v == null || v.isEmpty) ? null : v;
  }

  /// First non-empty value across the given keys (handles legacy field
  /// names — e.g. old card entries stored "Card Number (Last 4)").
  String? _firstOf(List<String> keys) {
    for (final k in keys) {
      final v = _f(k);
      if (v != null) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visual = switch (widget.entry.section) {
      VaultSection.card => _CardVisual(state: this),
      VaultSection.govtId => _GovtIdVisual(state: this),
      VaultSection.bankAccount => _BankVisual(state: this),
      VaultSection.emergencyContact => _ContactVisual(state: this),
      VaultSection.insurance => _InsuranceVisual(state: this),
      VaultSection.credential => _CredentialVisual(state: this),
      VaultSection.vehicle => _VehicleVisual(state: this),
      VaultSection.employment => _EmploymentVisual(state: this),
      VaultSection.education => _EducationVisual(state: this),
      VaultSection.socialMedia => _SocialMediaVisual(state: this),
      VaultSection.address => _AddressVisual(state: this),
      VaultSection.basicDetails => _BasicDetailsVisual(state: this),
      VaultSection.hobby => _HobbyVisual(state: this),
    };

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            visual,
            if (widget.trailing != null)
              Positioned(top: 4, right: 4, child: widget.trailing!),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

/// Format a card number with one space every 4 digits — leaves non-digits
/// alone for partial entries.
String _formatCardNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return raw;
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buf.write('  ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Mask all but the last 4 digits of a card number for the default view.
String _maskCardNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) return raw;
  final last = digits.substring(digits.length - 4);
  return '••••  ••••  ••••  $last';
}

/// Solid two-stop diagonal gradient seeded from a base colour — used by the
/// card-style visuals to give each entry a distinct hero look.
LinearGradient _gradient(Color base) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      base,
      Color.lerp(base, Colors.black, 0.35)!,
    ],
  );
}

Widget _revealButton(bool revealed, VoidCallback onTap, {Color? color}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(
        revealed
            ? Icons.visibility_off_rounded
            : Icons.visibility_rounded,
        size: 16,
        color: color ?? Colors.white.withValues(alpha: 0.85),
      ),
    ),
  );
}

Widget _badge(String text, {Color color = Colors.black54}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// CARD — physical credit/debit card with gradient, chip, masked number
// ──────────────────────────────────────────────────────────────────────────

class _CardVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _CardVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final cardType = state._f('Card Type') ?? 'Card';
    final bank = state._f('Bank/Issuer') ?? state.widget.entry.title;
    final network = state._f('Network');
    final rawNumber = state._firstOf(['Card Number', 'Card Number (Last 4)']);
    final holder = state._f('Card Holder Name')?.toUpperCase() ?? '';
    final expiry = state._f('Expiry') ?? '••/••';
    final cvv = state._f('CVV');

    final base = _accentForCardType(cardType);
    final number = rawNumber == null
        ? '••••  ••••  ••••  ••••'
        : (state._revealed
            ? _formatCardNumber(rawNumber)
            : _maskCardNumber(rawNumber));

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _gradient(base),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  cardType.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Icon(Icons.sim_card_rounded,
                color: Colors.amber.shade300, size: 30),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (rawNumber != null || cvv != null)
                  _revealButton(state._revealed, state._toggleReveal),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        holder.isEmpty ? 'YOUR NAME' : holder,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPIRES',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 8,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiry,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (cvv != null) ...[
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CVV',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state._revealed ? cvv : '•••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (network != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    network.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _accentForCardType(String type) {
    switch (type.toLowerCase()) {
      case 'credit card':
        return const Color(0xFF1E3A8A); // deep blue
      case 'debit card':
        return const Color(0xFF065F46); // emerald
      case 'prepaid card':
        return const Color(0xFF7C2D12); // burnt orange
      case 'forex card':
        return const Color(0xFF581C87); // royal purple
      default:
        return Colors.indigo.shade700;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// GOVT ID — photo placeholder + ID number, looks like a national ID card
// ──────────────────────────────────────────────────────────────────────────

class _GovtIdVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _GovtIdVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final idType = state._f('ID Type') ?? state.widget.entry.title;
    final idNumber = state._f('ID Number');
    final nameOnId = state._f('Name on ID');
    final issued = state._f('Issued By');
    final issueDate = state._f('Issue Date');
    final expiry = state._f('Expiry Date');

    final accent = VaultSection.govtId.color;
    final maskedNumber = idNumber == null
        ? '— — — —'
        : (state._revealed
            ? idNumber
            : _maskMiddle(idNumber));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(idType.toUpperCase(), color: accent),
              const Spacer(),
              if (idNumber != null)
                _revealButton(state._revealed, state._toggleReveal,
                    color: accent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 70,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: accent.withValues(alpha: 0.4), width: 1),
                ),
                child: Icon(Icons.person_rounded,
                    color: accent.withValues(alpha: 0.7), size: 38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nameOnId != null)
                      Text(
                        nameOnId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (nameOnId != null) const SizedBox(height: 6),
                    Text(
                      maskedNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.black87,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (issued != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Issued by $issued',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    if (issueDate != null || expiry != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (issueDate != null)
                            _MiniLabel(label: 'Issued', value: issueDate),
                          if (expiry != null)
                            _MiniLabel(label: 'Expires', value: expiry),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskMiddle(String s) {
    final clean = s.replaceAll(' ', '');
    if (clean.length <= 4) return s;
    final last = clean.substring(clean.length - 4);
    return '•••• •••• $last';
  }
}

// ──────────────────────────────────────────────────────────────────────────
// BANK ACCOUNT — wide cheque-leaf style card
// ──────────────────────────────────────────────────────────────────────────

class _BankVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _BankVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bank = state._f('Bank Name') ?? state.widget.entry.title;
    final branch = state._f('Branch');
    final accountNumber = state._f('Account Number');
    final ifsc = state._f('IFSC Code');
    final accType = state._f('Account Type');
    final holder = state._f('Account Holder');
    final upi = state._f('UPI ID');

    final masked = accountNumber == null
        ? '••••••••••••'
        : (state._revealed
            ? accountNumber
            : '••••••${accountNumber.length > 4 ? accountNumber.substring(accountNumber.length - 4) : accountNumber}');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.account_balance_rounded,
                    color: Colors.teal.shade700, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (branch != null)
                      Text(
                        branch,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (accType != null) _badge(accType, color: Colors.teal.shade700),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A/C NUMBER',
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(
                        masked,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (accountNumber != null)
                  _revealButton(state._revealed, state._toggleReveal,
                      color: Colors.teal.shade700),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (holder != null) _MiniLabel(label: 'Holder', value: holder),
              if (ifsc != null) _MiniLabel(label: 'IFSC', value: ifsc),
              if (upi != null) _MiniLabel(label: 'UPI', value: upi),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// EMERGENCY CONTACT — phone contact card
// ──────────────────────────────────────────────────────────────────────────

class _ContactVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _ContactVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final name = state._f('Name') ?? state.widget.entry.title;
    final relation = state._f('Relation');
    final phone = state._f('Phone');
    final alt = state._f('Alt Phone');
    final email = state._f('Email');
    final addr = state._f('Address');

    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join();

    final accent = Colors.redAccent;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _gradient(accent),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (relation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          relation,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.emergency_rounded, color: accent, size: 22),
            ],
          ),
          if (phone != null || alt != null || email != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],
          if (phone != null)
            _ContactLine(icon: Icons.phone_rounded, value: phone, color: accent),
          if (alt != null)
            _ContactLine(
                icon: Icons.phone_iphone_rounded, value: alt, color: accent),
          if (email != null)
            _ContactLine(
                icon: Icons.email_rounded, value: email, color: accent),
          if (addr != null)
            _ContactLine(
                icon: Icons.location_on_rounded, value: addr, color: accent),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _ContactLine(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// INSURANCE — policy-style card
// ──────────────────────────────────────────────────────────────────────────

class _InsuranceVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _InsuranceVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final type = state._f('Policy Type') ?? 'Policy';
    final provider = state._f('Provider') ?? state.widget.entry.title;
    final policyNo = state._f('Policy Number');
    final premium = state._f('Premium Amount');
    final freq = state._f('Premium Frequency');
    final sum = state._f('Sum Assured');
    final start = state._f('Start Date');
    final end = state._f('End Date');

    final accent = Colors.pink.shade700;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: _gradient(accent),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'POLICY · ${type.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (policyNo != null)
                  Text(
                    '#$policyNo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (sum != null)
                      Expanded(
                        child: _PolicyStat(
                          label: 'Sum Assured',
                          value: sum,
                          color: accent,
                        ),
                      ),
                    if (premium != null)
                      Expanded(
                        child: _PolicyStat(
                          label: 'Premium${freq != null ? ' / $freq' : ''}',
                          value: premium,
                          color: accent,
                        ),
                      ),
                  ],
                ),
                if (start != null || end != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (start != null) _MiniLabel(label: 'From', value: start),
                      if (start != null && end != null)
                        const SizedBox(width: 14),
                      if (end != null) _MiniLabel(label: 'To', value: end),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PolicyStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// CREDENTIAL — service / username / masked password
// ──────────────────────────────────────────────────────────────────────────

class _CredentialVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _CredentialVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final service = state._f('Service/Website') ?? state.widget.entry.title;
    final username = state._f('Username/Email');
    final password = state._f('Password');
    final pin = state._f('PIN');
    final twofa = state._f('2FA Method');

    final accent = Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lock_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          username,
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (password != null || pin != null)
                _revealButton(state._revealed, state._toggleReveal),
            ],
          ),
          if (password != null) ...[
            const SizedBox(height: 12),
            _SecretLine(
                label: 'Password',
                value: password,
                revealed: state._revealed),
          ],
          if (pin != null) ...[
            const SizedBox(height: 6),
            _SecretLine(
                label: 'PIN', value: pin, revealed: state._revealed),
          ],
          if (twofa != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shield_moon_rounded,
                    color: Colors.amber.shade300, size: 14),
                const SizedBox(width: 6),
                Text(
                  '2FA · $twofa',
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SecretLine extends StatelessWidget {
  final String label;
  final String value;
  final bool revealed;
  const _SecretLine({
    required this.label,
    required this.value,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context) {
    final display = revealed ? value : '•' * value.length.clamp(4, 16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('$label  ',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                letterSpacing: 0.6,
              )),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 13,
                letterSpacing: 1.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// VEHICLE — number plate hero + spec strip
// ──────────────────────────────────────────────────────────────────────────

class _VehicleVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _VehicleVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final type = state._f('Vehicle Type');
    final make = state._f('Make');
    final model = state._f('Model');
    final year = state._f('Year');
    final reg = state._f('Registration No');
    final color = state._f('Color');
    final fuel = state._f('Fuel Type');

    final headline = [
      if (make != null) make,
      if (model != null) model,
    ].join(' ').trim().isEmpty
        ? state.widget.entry.title
        : [if (make != null) make, if (model != null) model].join(' ').trim();

    final accent = Colors.orange.shade800;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForType(type),
                color: accent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (year != null || type != null)
                      Text(
                        [if (type != null) type, if (year != null) year]
                            .join(' · '),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (reg != null) ...[
            const SizedBox(height: 12),
            // Number-plate style
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade600,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  reg.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.black,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
          if (color != null || fuel != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (color != null) _badge('Color · $color', color: accent),
                if (fuel != null) _badge('Fuel · $fuel', color: accent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(String? t) {
    final s = (t ?? '').toLowerCase();
    if (s.contains('bike') || s.contains('motor')) {
      return Icons.two_wheeler_rounded;
    }
    if (s.contains('truck')) return Icons.local_shipping_rounded;
    if (s.contains('bus')) return Icons.directions_bus_rounded;
    return Icons.directions_car_rounded;
  }
}

// ──────────────────────────────────────────────────────────────────────────
// EMPLOYMENT — work ID badge
// ──────────────────────────────────────────────────────────────────────────

class _EmploymentVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _EmploymentVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final company = state._f('Company') ?? state.widget.entry.title;
    final designation = state._f('Designation');
    final empId = state._f('Employee ID');
    final department = state._f('Department');
    final join = state._f('Join Date');
    final endDate = state._f('End Date');

    final accent = Colors.brown.shade600;
    final cs = Theme.of(context).colorScheme;
    final initials = company.trim().isEmpty
        ? '?'
        : company.trim().split(RegExp(r'\s+')).first[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _gradient(accent),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (designation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          designation,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.work_rounded, color: Colors.brown, size: 18),
            ],
          ),
          if (empId != null || department != null || join != null || endDate != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (empId != null) _MiniLabel(label: 'Emp ID', value: empId),
                if (department != null)
                  _MiniLabel(label: 'Dept', value: department),
                if (join != null) _MiniLabel(label: 'Joined', value: join),
                if (endDate != null) _MiniLabel(label: 'Until', value: endDate),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// EDUCATION — certificate-style
// ──────────────────────────────────────────────────────────────────────────

class _EducationVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _EducationVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final degree = state._f('Degree/Course') ?? state.widget.entry.title;
    final inst = state._f('Institution');
    final university = state._f('University');
    final year = state._f('Year of Passing');
    final score = state._f('Percentage/CGPA');
    final spec = state._f('Specialization');

    final accent = Colors.cyan.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.school_rounded, color: accent, size: 28),
          const SizedBox(height: 8),
          Text(
            degree,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (spec != null) ...[
            const SizedBox(height: 2),
            Text(
              spec,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
          if (inst != null) ...[
            const SizedBox(height: 6),
            Text(
              inst,
              style:
                  TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (university != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                university,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          if (year != null || score != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              children: [
                if (year != null) _badge('Year · $year', color: accent),
                if (score != null) _badge('Score · $score', color: accent),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// SOCIAL MEDIA — brand-colored card
// ──────────────────────────────────────────────────────────────────────────

class _SocialMediaVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _SocialMediaVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final platform = state._f('Platform') ?? state.widget.entry.title;
    final handle = state._f('Username/Handle') ?? state._f('Profile Name');
    final email = state._f('Email Used');
    final url = state._f('Profile URL');

    final (accent, icon) = _brandFor(platform);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _gradient(accent),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (handle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      handle.startsWith('@') ? handle : '@$handle',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (email != null || url != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      email ?? url ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _brandFor(String p) {
    final s = p.toLowerCase();
    if (s.contains('instagram')) {
      return (const Color(0xFFE1306C), Icons.camera_alt_rounded);
    }
    if (s.contains('facebook')) {
      return (const Color(0xFF1877F2), Icons.facebook_rounded);
    }
    if (s.contains('twitter') || s.contains('x')) {
      return (Colors.black, Icons.tag_rounded);
    }
    if (s.contains('linkedin')) {
      return (const Color(0xFF0A66C2), Icons.business_center_rounded);
    }
    if (s.contains('youtube')) {
      return (const Color(0xFFFF0000), Icons.play_circle_rounded);
    }
    if (s.contains('whatsapp')) {
      return (const Color(0xFF25D366), Icons.chat_rounded);
    }
    if (s.contains('telegram')) {
      return (const Color(0xFF229ED9), Icons.send_rounded);
    }
    if (s.contains('github')) return (Colors.black87, Icons.code_rounded);
    if (s.contains('reddit')) {
      return (const Color(0xFFFF4500), Icons.forum_rounded);
    }
    return (Colors.deepPurple, Icons.public_rounded);
  }
}

// ──────────────────────────────────────────────────────────────────────────
// ADDRESS — envelope-style
// ──────────────────────────────────────────────────────────────────────────

class _AddressVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _AddressVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final label = state._f('Label') ?? state.widget.entry.title;
    final lines = [
      state._f('Door/Flat No'),
      state._f('Street'),
      state._f('Area/Locality'),
      [state._f('City'), state._f('District')]
          .where((v) => v != null && v.isNotEmpty)
          .join(', '),
      [state._f('State'), state._f('PIN Code')]
          .where((v) => v != null && v.isNotEmpty)
          .join(' '),
      state._f('Country'),
    ].where((v) => v != null && v.isNotEmpty).cast<String>().toList();

    final landmark = state._f('Landmark');
    final accent = Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  l,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              )),
          if (landmark != null && landmark.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.tour_rounded,
                    size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    landmark,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// BASIC DETAILS — profile bio card
// ──────────────────────────────────────────────────────────────────────────

class _BasicDetailsVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _BasicDetailsVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final name = state._f('Full Name') ?? state.widget.entry.title;
    final dob = state._f('Date of Birth');
    final blood = state._f('Blood Group');
    final phone = state._f('Phone');
    final email = state._f('Email');
    final gender = state._f('Gender');

    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join();

    final accent = Colors.blue.shade700;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _gradient(accent),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dob != null || gender != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [if (gender != null) gender, if (dob != null) dob]
                              .join(' · '),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              if (blood != null) _badge(blood, color: Colors.red.shade700),
            ],
          ),
          if (phone != null || email != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (phone != null)
              _ContactLine(
                  icon: Icons.phone_rounded, value: phone, color: accent),
            if (email != null)
              _ContactLine(
                  icon: Icons.email_rounded, value: email, color: accent),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// HOBBY — tag-style bubble
// ──────────────────────────────────────────────────────────────────────────

class _HobbyVisual extends StatelessWidget {
  final _VaultEntryVisualState state;
  const _HobbyVisual({required this.state});

  @override
  Widget build(BuildContext context) {
    final hobby = state._f('Hobby/Interest') ?? state.widget.entry.title;
    final cat = state._f('Category');
    final level = state._f('Level');
    final since = state._f('Since');
    final accent = Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sports_esports_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hobby,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cat != null || level != null || since != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (cat != null) _badge(cat, color: accent),
                        if (level != null) _badge(level, color: accent),
                        if (since != null)
                          _badge('since $since', color: accent),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ──────────────────────────────────────────────────────────────────────────

class _MiniLabel extends StatelessWidget {
  final String label;
  final String value;
  const _MiniLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
