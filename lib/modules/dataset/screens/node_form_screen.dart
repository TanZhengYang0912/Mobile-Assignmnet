import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/dataset_state.dart';

class NodeFormScreen extends StatefulWidget {
  final EquipmentNode? node;

  const NodeFormScreen({super.key, this.node});

  @override
  State<NodeFormScreen> createState() => _NodeFormScreenState();
}

class _NodeFormScreenState extends State<NodeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _nodeName;
  late String _utilityType;
  late String _status;
  late String _zoneId;
  String? _manufacturer;
  String? _firmwareVersion;
  String? _ipAddress;
  DateTime? _installationDate;
  DateTime? _lastMaintenanceDate;

  final DateFormat _dateFormat = DateFormat.yMMMd();

  final List<String> _malaysianStates = [
    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 'Pahang', 'Perak', 
    'Perlis', 'Pulau Pinang', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu', 
    'W.P. Kuala Lumpur', 'W.P. Labuan', 'W.P. Putrajaya'
  ];

  @override
  void initState() {
    super.initState();
    _nodeName = widget.node?.nodeName ?? '';
    _utilityType = widget.node?.utilityType ?? 'Water';
    _status = widget.node?.status ?? 'Active';
    _zoneId = widget.node?.zoneId ?? 'Selangor';
    if (!_malaysianStates.contains(_zoneId)) _zoneId = 'Selangor';
    
    _manufacturer = widget.node?.manufacturer;
    _firmwareVersion = widget.node?.firmwareVersion;
    _ipAddress = widget.node?.ipAddress;
    _installationDate = widget.node?.installationDate;
    _lastMaintenanceDate = widget.node?.lastMaintenanceDate;
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final node = EquipmentNode(
        nodeId: widget.node?.nodeId,
        nodeName: _nodeName,
        utilityType: _utilityType,
        status: _status,
        zoneId: _zoneId,
        manufacturer: _manufacturer,
        firmwareVersion: _firmwareVersion,
        ipAddress: _ipAddress,
        installationDate: _installationDate,
        lastMaintenanceDate: _lastMaintenanceDate,
        healthScore: widget.node?.healthScore ?? 100, // Keep existing health score or 100
      );
      
      context.read<DatasetState>().addOrUpdateNode(node);
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate(BuildContext context, bool isInstallDate) async {
    final initialDate = isInstallDate 
        ? (_installationDate ?? DateTime.now())
        : (_lastMaintenanceDate ?? DateTime.now());
        
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isInstallDate) {
          _installationDate = picked;
        } else {
          _lastMaintenanceDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.node != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Configuration' : 'New Deployment'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('General Information', Icons.info_outline),
            _buildCard([
              TextFormField(
                initialValue: _nodeName,
                decoration: const InputDecoration(labelText: 'Equipment Name', icon: Icon(Icons.badge)),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => _nodeName = value!,
              ),
              DropdownButtonFormField<String>(
                value: _utilityType,
                decoration: const InputDecoration(labelText: 'Utility Type', icon: Icon(Icons.category)),
                items: ['Water', 'Electricity'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _utilityType = value!),
                onSaved: (value) => _utilityType = value!,
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Operational Status', icon: Icon(Icons.traffic)),
                items: ['Active', 'Maintenance', 'Critical', 'Offline'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (value) => setState(() => _status = value!),
                onSaved: (value) => _status = value!,
              ),
              DropdownButtonFormField<String>(
                value: _zoneId,
                decoration: const InputDecoration(labelText: 'Zone / State', icon: Icon(Icons.place)),
                items: _malaysianStates.map((state) {
                  return DropdownMenuItem(value: state, child: Text(state));
                }).toList(),
                onChanged: (value) => setState(() => _zoneId = value!),
                onSaved: (value) => _zoneId = value!,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSectionHeader('Hardware Specs', Icons.memory),
            _buildCard([
              TextFormField(
                initialValue: _manufacturer,
                decoration: const InputDecoration(labelText: 'Manufacturer', icon: Icon(Icons.precision_manufacturing)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please specify the manufacturer' : null,
                onSaved: (value) => _manufacturer = value,
              ),
              TextFormField(
                initialValue: _ipAddress,
                decoration: const InputDecoration(labelText: 'IP Address', icon: Icon(Icons.network_wifi)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'IP Address is required';
                  final ipRegExp = RegExp(r"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$");
                  if (!ipRegExp.hasMatch(value)) return 'Enter a valid IPv4 address (e.g. 192.168.1.1)';
                  return null;
                },
                onSaved: (value) => _ipAddress = value,
              ),
              TextFormField(
                initialValue: _firmwareVersion,
                decoration: const InputDecoration(labelText: 'Firmware Version', icon: Icon(Icons.system_update)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Firmware version is required' : null,
                onSaved: (value) => _firmwareVersion = value,
              ),
            ]),

            const SizedBox(height: 24),
            
            _buildSectionHeader('Maintenance Schedule', Icons.build),
            _buildCard([
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Installation Date'),
                subtitle: Text(_installationDate != null ? _dateFormat.format(_installationDate!) : 'Not Set'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _pickDate(context, true),
              ),
              if (isEditing)
                ListTile(
                  leading: const Icon(Icons.build_circle),
                  title: const Text('Last Maintenance Date'),
                  subtitle: Text(_lastMaintenanceDate != null ? _dateFormat.format(_lastMaintenanceDate!) : 'Not Set'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () => _pickDate(context, false),
                ),
            ]),

            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveForm,
              child: const Text('Save Configuration', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: Colors.teal.shade900, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
