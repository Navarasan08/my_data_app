import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_state.dart';

export 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

// Vehicle List Page
class VehicleListPage extends StatelessWidget {
  const VehicleListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
        final cubit = context.read<VehicleCubit>();
        final vehicles = state.vehicles;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Vehicles'),
            centerTitle: true,
            elevation: 0,
          ),
          body: vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No vehicles added yet',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first vehicle',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: cubit,
                              child: VehicleDetailsPage(vehicleId: vehicle.id),
                            ),
                          ),
                        );
                      },
                      onEdit: () async {
                        final editedVehicle = await Navigator.push<Vehicle>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddVehiclePage(vehicle: vehicle),
                          ),
                        );
                        if (editedVehicle != null) {
                          cubit.updateVehicle(editedVehicle);
                        }
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Vehicle'),
                            content: Text(
                                'Are you sure you want to delete "${vehicle.name}"? All associated records will also be deleted.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          cubit.deleteVehicle(vehicle.id);
                        }
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newVehicle = await Navigator.push<Vehicle>(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddVehiclePage()),
              );
              if (newVehicle != null) {
                cubit.addVehicle(newVehicle);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
          ),
        );
      },
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleCard({
    Key? key,
    required this.vehicle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalExpenses = vehicle.records
        .where((r) => r.amount != null)
        .fold<double>(0, (sum, r) => sum + r.amount!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.directions_car,
                        color: Colors.blue[700], size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${vehicle.brand} ${vehicle.model} (${vehicle.year})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.blue[400],
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    icon: Icons.tag,
                    label: vehicle.registrationNumber,
                  ),
                  _InfoChip(
                    icon: Icons.receipt_long,
                    label: '${vehicle.records.length} records',
                  ),
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: '\$${totalExpenses.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// Add Vehicle Page
class AddVehiclePage extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehiclePage({Key? key, this.vehicle}) : super(key: key);

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _registrationController = TextEditingController();
  final _vinController = TextEditingController();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _nameController.text = widget.vehicle!.name;
      _brandController.text = widget.vehicle!.brand;
      _modelController.text = widget.vehicle!.model;
      _yearController.text = widget.vehicle!.year;
      _registrationController.text = widget.vehicle!.registrationNumber;
      _vinController.text = widget.vehicle!.vinNumber ?? '';
      _colorController.text = widget.vehicle!.color ?? '';
      _priceController.text = widget.vehicle!.purchasePrice?.toString() ?? '';
      _purchaseDate = widget.vehicle!.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _vinController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveVehicle() {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicle(
        id: widget.vehicle?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        brand: _brandController.text,
        model: _modelController.text,
        year: _yearController.text,
        registrationNumber: _registrationController.text,
        vinNumber:
            _vinController.text.isEmpty ? null : _vinController.text,
        color:
            _colorController.text.isEmpty ? null : _colorController.text,
        purchaseDate: _purchaseDate,
        purchasePrice: _priceController.text.isEmpty
            ? null
            : double.tryParse(_priceController.text),
        records: widget.vehicle?.records ?? [],
      );
      Navigator.pop(context, vehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Name *',
                hintText: 'e.g., My Honda',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.drive_file_rename_outline),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand *',
                      hintText: 'Honda',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model *',
                      hintText: 'Civic',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year *',
                      hintText: '2020',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      hintText: 'Silver',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registrationController,
              decoration: const InputDecoration(
                labelText: 'Registration Number *',
                hintText: 'ABC-1234',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vinController,
              decoration: const InputDecoration(
                labelText: 'VIN Number',
                hintText: '1HGBH41JXMN109186',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Purchase Date'),
              subtitle:
                  Text(DateFormat('MMM dd, yyyy').format(_purchaseDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _purchaseDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _purchaseDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                hintText: '25000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveVehicle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _isEditing ? 'Update Vehicle' : 'Save Vehicle',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// Vehicle Details Page
class VehicleDetailsPage extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailsPage({Key? key, required this.vehicleId})
      : super(key: key);

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  RecordType? filterType;
  DateTime? filterFromDate;
  DateTime? filterToDate;

  List<VehicleRecord> _getFilteredRecords(Vehicle vehicle) {
    var records = vehicle.records.toList();

    if (filterType != null) {
      records = records.where((r) => r.type == filterType).toList();
    }

    if (filterFromDate != null) {
      records = records
          .where((r) =>
              r.date.isAfter(filterFromDate!) ||
              r.date.isAtSameMomentAs(filterFromDate!))
          .toList();
    }

    if (filterToDate != null) {
      final endOfDay = DateTime(
          filterToDate!.year, filterToDate!.month, filterToDate!.day, 23, 59);
      records = records
          .where((r) =>
              r.date.isBefore(endOfDay) || r.date.isAtSameMomentAs(endOfDay))
          .toList();
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        currentType: filterType,
        currentFromDate: filterFromDate,
        currentToDate: filterToDate,
        onApply: (type, fromDate, toDate) {
          setState(() {
            filterType = type;
            filterFromDate = fromDate;
            filterToDate = toDate;
          });
        },
        onClear: () {
          setState(() {
            filterType = null;
            filterFromDate = null;
            filterToDate = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
        final cubit = context.read<VehicleCubit>();
        final vehicle = cubit.getVehicleById(widget.vehicleId);

        if (vehicle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vehicle')),
            body: const Center(child: Text('Vehicle not found')),
          );
        }

        final filteredRecords = _getFilteredRecords(vehicle);
        final hasActiveFilters = filterType != null ||
            filterFromDate != null ||
            filterToDate != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(vehicle.name),
            elevation: 0,
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          body: Column(
            children: [
              // Vehicle Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Year: ${vehicle.year} • ${vehicle.registrationNumber}',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (vehicle.color != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Color: ${vehicle.color}',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Statistics
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: _StatisticsRow(
                    vehicle: vehicle, records: filteredRecords),
              ),
              const Divider(height: 1),

              // Records List
              Expanded(
                child: filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              hasActiveFilters
                                  ? 'No records match your filters'
                                  : 'No records yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return RecordCard(
                            record: record,
                            onEdit: () async {
                              final editedRecord =
                                  await Navigator.push<VehicleRecord>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddRecordPage(record: record),
                                ),
                              );
                              if (editedRecord != null) {
                                cubit.updateRecord(
                                    widget.vehicleId, editedRecord);
                              }
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Record'),
                                  content: Text(
                                      'Are you sure you want to delete "${record.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                cubit.deleteRecord(
                                    widget.vehicleId, record.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newRecord = await Navigator.push<VehicleRecord>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecordPage(),
                ),
              );
              if (newRecord != null) {
                cubit.addRecord(widget.vehicleId, newRecord);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        );
      },
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  final Vehicle vehicle;
  final List<VehicleRecord> records;

  const _StatisticsRow({required this.vehicle, required this.records});

  @override
  Widget build(BuildContext context) {
    final fuelCount = records.where((r) => r.type == RecordType.fuel).length;
    final serviceCount =
        records.where((r) => r.type == RecordType.service).length;
    final totalExpenses = records
        .where((r) => r.amount != null)
        .fold<double>(0, (sum, r) => sum + r.amount!);

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.local_gas_station,
            label: 'Fuel',
            value: fuelCount.toString(),
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.build,
            label: 'Service',
            value: serviceCount.toString(),
            color: Colors.blue,
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.attach_money,
            label: 'Total',
            value: '\$${totalExpenses.toStringAsFixed(0)}',
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class RecordCard extends StatelessWidget {
  final VehicleRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecordCard(
      {Key? key,
      required this.record,
      required this.onEdit,
      required this.onDelete})
      : super(key: key);

  IconData _getIcon() {
    switch (record.type) {
      case RecordType.fuel:
        return Icons.local_gas_station;
      case RecordType.service:
        return Icons.build;
      case RecordType.purchase:
        return Icons.shopping_cart;
      case RecordType.importantDate:
        return Icons.event_note;
      case RecordType.note:
        return Icons.note;
    }
  }

  Color _getColor() {
    switch (record.type) {
      case RecordType.fuel:
        return Colors.orange;
      case RecordType.service:
        return Colors.blue;
      case RecordType.purchase:
        return Colors.purple;
      case RecordType.importantDate:
        return Colors.red;
      case RecordType.note:
        return Colors.grey;
    }
  }

  String _getTypeLabel() {
    switch (record.type) {
      case RecordType.fuel:
        return 'Fuel';
      case RecordType.service:
        return 'Service';
      case RecordType.purchase:
        return 'Purchase';
      case RecordType.importantDate:
        return 'Important Date';
      case RecordType.note:
        return 'Note';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getIcon(), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (record.isImportant)
                            Icon(Icons.star,
                                color: Colors.amber[700], size: 18),
                        ],
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(record.date),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (record.amount != null)
                  Text(
                    '\$${record.amount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue[400],
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  onPressed: onDelete,
                ),
              ],
            ),
            if (record.description != null) ...[
              const SizedBox(height: 8),
              Text(
                record.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _DetailChip(
                  icon: Icons.category,
                  label: _getTypeLabel(),
                ),
                if (record.odometer != null)
                  _DetailChip(
                    icon: Icons.speed,
                    label: '${record.odometer!.toStringAsFixed(0)} km',
                  ),
                if (record.location != null)
                  _DetailChip(
                    icon: Icons.location_on,
                    label: record.location!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// Add Record Page
class AddRecordPage extends StatefulWidget {
  final VehicleRecord? record;

  const AddRecordPage({Key? key, this.record}) : super(key: key);

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _odometerController = TextEditingController();
  final _locationController = TextEditingController();

  RecordType _selectedType = RecordType.fuel;
  DateTime _selectedDate = DateTime.now();
  bool _isImportant = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _titleController.text = widget.record!.title;
      _descriptionController.text = widget.record!.description ?? '';
      _amountController.text = widget.record!.amount?.toString() ?? '';
      _odometerController.text = widget.record!.odometer?.toString() ?? '';
      _locationController.text = widget.record!.location ?? '';
      _selectedType = widget.record!.type;
      _selectedDate = widget.record!.date;
      _isImportant = widget.record!.isImportant;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _odometerController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = VehicleRecord(
        id: widget.record?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        date: _selectedDate,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        amount: _amountController.text.isEmpty
            ? null
            : double.tryParse(_amountController.text),
        odometer: _odometerController.text.isEmpty
            ? null
            : double.tryParse(_odometerController.text),
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        isImportant: _isImportant,
      );
      Navigator.pop(context, record);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Record' : 'Add Record'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Record Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecordType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Gas Fill-up',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Additional details...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle:
                  Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '50.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _odometerController,
              decoration: const InputDecoration(
                labelText: 'Odometer Reading',
                hintText: '45230',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Shell Station',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as Important'),
              subtitle: const Text('Show with star icon'),
              value: _isImportant,
              onChanged: (value) => setState(() => _isImportant = value),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _isEditing ? 'Update Record' : 'Save Record',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(RecordType type) {
    switch (type) {
      case RecordType.fuel:
        return 'Fuel';
      case RecordType.service:
        return 'Service';
      case RecordType.purchase:
        return 'Purchase';
      case RecordType.importantDate:
        return 'Important Date';
      case RecordType.note:
        return 'Note';
    }
  }
}

// Filter Dialog
class FilterDialog extends StatefulWidget {
  final RecordType? currentType;
  final DateTime? currentFromDate;
  final DateTime? currentToDate;
  final Function(RecordType?, DateTime?, DateTime?) onApply;
  final VoidCallback onClear;

  const FilterDialog({
    Key? key,
    this.currentType,
    this.currentFromDate,
    this.currentToDate,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  RecordType? _selectedType;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
    _fromDate = widget.currentFromDate;
    _toDate = widget.currentToDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Records'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = null);
                    }
                  },
                ),
                ...RecordType.values.map((type) {
                  return FilterChip(
                    label: Text(_getTypeLabel(type)),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(
                          () => _selectedType = selected ? type : null);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('From Date'),
              subtitle: Text(_fromDate != null
                  ? DateFormat('MMM dd, yyyy').format(_fromDate!)
                  : 'Not set'),
              trailing: _fromDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _fromDate = null),
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fromDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _fromDate = date);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('To Date'),
              subtitle: Text(_toDate != null
                  ? DateFormat('MMM dd, yyyy').format(_toDate!)
                  : 'Not set'),
              trailing: _toDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _toDate = null),
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _toDate ?? DateTime.now(),
                  firstDate: _fromDate ?? DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _toDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClear();
            Navigator.pop(context);
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedType, _fromDate, _toDate);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _getTypeLabel(RecordType type) {
    switch (type) {
      case RecordType.fuel:
        return 'Fuel';
      case RecordType.service:
        return 'Service';
      case RecordType.purchase:
        return 'Purchase';
      case RecordType.importantDate:
        return 'Important';
      case RecordType.note:
        return 'Note';
    }
  }
}
