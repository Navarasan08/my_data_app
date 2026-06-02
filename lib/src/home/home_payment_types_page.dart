import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';

class HomePaymentTypesPage extends StatelessWidget {
  const HomePaymentTypesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<HomeRecordCubit>();
        final paymentTypes = state.paymentTypes;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Types'),
            centerTitle: true,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showPaymentTypeDialog(context, cubit, null),
            icon: const Icon(Icons.add),
            label: const Text('Add Type'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Tag records with cash / UPI / card etc. Records keep their tag even if the type is later removed here.',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (paymentTypes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No payment types yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...paymentTypes.map((t) {
                      final inUse = cubit.isPaymentTypeInUse(t.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(t.icon, color: t.color, size: 22),
                          ),
                          title: Text(
                            t.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: inUse
                              ? const Text('In use',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.green))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: Colors.blue[400]),
                                onPressed: () =>
                                    _showPaymentTypeDialog(context, cubit, t),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red[400]),
                                onPressed: () => _confirmDeletePaymentType(
                                    context, cubit, t, inUse),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPaymentTypeDialog(
      BuildContext context, HomeRecordCubit cubit, PaymentType? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _PaymentTypeDialog(
        existing: existing,
        onSave: (t) {
          if (existing != null) {
            cubit.updatePaymentType(t);
          } else {
            cubit.addPaymentType(t);
          }
        },
      ),
    );
  }

  void _confirmDeletePaymentType(BuildContext context, HomeRecordCubit cubit,
      PaymentType type, bool inUse) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Type'),
        content: Text(
          inUse
              ? '"${type.displayName}" is used by some records. They will keep showing this label, but it won\'t appear in the picker. Delete?'
              : 'Are you sure you want to delete "${type.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.deletePaymentType(type.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeDialog extends StatefulWidget {
  final PaymentType? existing;
  final ValueChanged<PaymentType> onSave;

  const _PaymentTypeDialog({this.existing, required this.onSave});

  @override
  State<_PaymentTypeDialog> createState() => _PaymentTypeDialogState();
}

class _PaymentTypeDialogState extends State<_PaymentTypeDialog> {
  final _nameController = TextEditingController();
  int _selectedIconIndex = 0;
  int _selectedColorIndex = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.displayName;
      _selectedIconIndex = widget.existing!.iconIndex;
      _selectedColorIndex = widget.existing!.colorIndex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewIcon = PaymentType.availableIcons[_selectedIconIndex];
    final previewColor = PaymentType.availableColors[_selectedColorIndex];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Payment Type' : 'Add Payment Type'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: previewColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: previewColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(previewIcon, color: previewColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Preview'
                            : _nameController.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: previewColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Bank Transfer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              Text('Icon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  )),
              const SizedBox(height: 6),
              SizedBox(
                height: 96,
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: PaymentType.availableIcons.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIconIndex == index;
                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedIconIndex = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? previewColor.withValues(alpha: 0.15)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: previewColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          PaymentType.availableIcons[index],
                          size: 20,
                          color: isSelected
                              ? previewColor
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              Text('Color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  )),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                    PaymentType.availableColors.length, (index) {
                  final color = PaymentType.availableColors[index];
                  final isSelected = _selectedColorIndex == index;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedColorIndex = index),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: cs.outline, width: 1),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  final name = _nameController.text.trim();
                  final id = widget.existing?.id ??
                      'pt_${DateTime.now().millisecondsSinceEpoch}';
                  final type = PaymentType(
                    id: id,
                    displayName: name,
                    iconIndex: _selectedIconIndex,
                    colorIndex: _selectedColorIndex,
                  );
                  widget.onSave(type);
                  Navigator.pop(context);
                },
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
