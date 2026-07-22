import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
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

  late final TextEditingController _nameController;
  late final TextEditingController _facilityController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _ipController;
  late final TextEditingController _firmwareController;

  late String _utilityType;
  late String _status;
  late String _zoneId;
  DateTime? _installationDate;
  DateTime? _lastMaintenanceDate;
  DateTime? _nextMaintenanceDate;

  final _lockedFormat = DateFormat('MMM d, y');
  final _editableFormat = DateFormat('dd/MM/yyyy');

  static const _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'W.P. Kuala Lumpur',
    'W.P. Labuan',
    'W.P. Putrajaya'
  ];

  static const _utilityTypes = ['Water', 'Electricity'];
  static const _statuses = ['Active', 'Warning', 'Critical', 'Maintenance'];

  bool get _isEditing => widget.node != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node?.nodeName ?? '');
    _facilityController =
        TextEditingController(text: widget.node?.facilityName ?? '');
    _manufacturerController =
        TextEditingController(text: widget.node?.manufacturer ?? '');
    _ipController = TextEditingController(text: widget.node?.ipAddress ?? '');
    _firmwareController =
        TextEditingController(text: widget.node?.firmwareVersion ?? '');

    _utilityType = widget.node?.utilityType ?? 'Water';
    final rawStatus = widget.node?.status ?? 'Active';
    _status = _statuses.contains(rawStatus) ? rawStatus : 'Active';
    _zoneId = widget.node?.zoneId ?? 'Selangor';
    if (!_malaysianStates.contains(_zoneId)) _zoneId = 'Selangor';

    final now = DateTime.now();
    _installationDate = widget.node?.installationDate ?? now;
    _lastMaintenanceDate = widget.node?.lastMaintenanceDate ?? now;
    _nextMaintenanceDate = widget.node?.nextMaintenanceDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facilityController.dispose();
    _manufacturerController.dispose();
    _ipController.dispose();
    _firmwareController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final node = EquipmentNode(
      nodeId: widget.node?.nodeId,
      nodeName: _nameController.text.trim(),
      utilityType: _utilityType,
      status: _status,
      zoneId: _zoneId,
      facilityName: _facilityController.text.trim(),
      facilityCity: widget.node?.facilityCity,
      manufacturer: _manufacturerController.text.trim(),
      firmwareVersion: _firmwareController.text.trim(),
      ipAddress: _ipController.text.trim(),
      installationDate: _installationDate,
      lastMaintenanceDate: _lastMaintenanceDate,
      nextMaintenanceDate: _nextMaintenanceDate,
      healthScore: widget.node?.healthScore ?? 100,
    );
    context.read<DatasetState>().addOrUpdateNode(node);
    Navigator.of(context).pop();
  }

  Future<void> _pickNextMaintenanceDate() async {
    final result = await showDialog<_CalendarResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CalendarPickerDialog(
        initialDate: _nextMaintenanceDate ?? DateTime.now(),
      ),
    );
    if (result != null) {
      setState(() => _nextMaintenanceDate = result.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _sectionCard(
                    icon: Icons.info_outline,
                    title: 'General Information',
                    children: [
                      _textFieldRow(
                        label: 'Equipment Name',
                        controller: _nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const _RowDivider(),
                      _textFieldRow(
                        label: 'Shopping Mall / Facility',
                        controller: _facilityController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Facility is required'
                            : null,
                      ),
                      const _RowDivider(),
                      _dropdownRow<String>(
                        label: 'Utility Type',
                        value: _utilityType,
                        items: _utilityTypes,
                        onChanged: (v) => setState(() => _utilityType = v!),
                      ),
                      const _RowDivider(),
                      _dropdownRow<String>(
                        label: 'Operational Status',
                        value: _status,
                        items: _statuses,
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const _RowDivider(),
                      _pickerRow(
                        label: 'State / Federal Territory',
                        value: _zoneId,
                        onTap: _showStatePicker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.settings_outlined,
                    title: 'Hardware Specs',
                    children: [
                      _textFieldRow(
                        label: 'Manufacturer',
                        controller: _manufacturerController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Manufacturer is required'
                            : null,
                      ),
                      const _RowDivider(),
                      _textFieldRow(
                        label: 'IP Address',
                        controller: _ipController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'IP Address is required';
                          }
                          final ip = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
                          if (!ip.hasMatch(v.trim())) {
                            return 'Enter a valid IPv4 (e.g. 192.168.1.1)';
                          }
                          return null;
                        },
                      ),
                      const _RowDivider(),
                      _textFieldRow(
                        label: 'Firmware Version',
                        controller: _firmwareController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Firmware version is required'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.build_outlined,
                    title: 'Maintenance Schedule',
                    children: [
                      _lockedDateRow(
                        label: 'Installation Date',
                        date: _installationDate,
                      ),
                      const _RowDivider(),
                      _lockedDateRow(
                        label: 'Last Maintenance Date',
                        date: _lastMaintenanceDate,
                      ),
                      const _RowDivider(),
                      _editableDateRow(
                        label: 'Next Maintenance Date',
                        date: _nextMaintenanceDate,
                        onTap: _pickNextMaintenanceDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Text(
            _isEditing ? 'Edit Configuration' : 'New Deployment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.adminPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adminPrimary,
                  ),
                ),
              ],
            ),
          ),
          const _RowDivider(),
          ...children,
        ],
      ),
    );
  }

  Widget _textFieldRow({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              items: items
                  .map((v) => DropdownMenuItem<T>(
                        value: v,
                        child: Text(v.toString()),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatePicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.6,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Zone / State',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: _malaysianStates.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (_, i) {
                        final s = _malaysianStates[i];
                        final selected = s == _zoneId;
                        return InkWell(
                          onTap: () => Navigator.of(ctx).pop(s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? AppColors.adminPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check,
                                      color: AppColors.adminPrimary, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _zoneId = picked);
  }

  Widget _lockedDateRow({
    required String label,
    required DateTime? date,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null ? 'Not set' : _lockedFormat.format(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline,
              size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _editableDateRow({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.adminPrimary),
                      const SizedBox(width: 8),
                      Text(
                        date == null
                            ? 'Select date'
                            : _editableFormat.format(date),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_outlined,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}

class _CalendarResult {
  final DateTime? date;
  const _CalendarResult(this.date);
}

class _CalendarPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _CalendarPickerDialog({required this.initialDate});

  @override
  State<_CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<_CalendarPickerDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selected = DateTime(widget.initialDate.year, widget.initialDate.month,
        widget.initialDate.day);
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final leading = firstOfMonth.weekday % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_monthNames[_visibleMonth.month - 1]}, ${_visibleMonth.year}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down,
                        size: 20, color: AppColors.textPrimary),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: _prevMonth,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.arrow_upward,
                        size: 20, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _nextMonth,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.arrow_downward,
                        size: 20, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: _weekdayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            for (int week = 0; week < 6; week++)
              Row(
                children: List.generate(7, (dow) {
                  final date = gridStart.add(Duration(days: week * 7 + dow));
                  final isCurrentMonth = date.month == _visibleMonth.month;
                  final isSelected = _sameDay(date, _selected);
                  final isToday = _sameDay(date, todayNorm);
                  return Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: InkWell(
                        onTap: () {
                          setState(() => _selected = date);
                          Navigator.of(context).pop(_CalendarResult(date));
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: isSelected
                              ? BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.textPrimary, width: 1.4),
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: !isCurrentMonth
                                  ? AppColors.textTertiary
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                InkWell(
                  onTap: () =>
                      Navigator.of(context).pop(const _CalendarResult(null)),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    final now = DateTime.now();
                    Navigator.of(context).pop(_CalendarResult(
                        DateTime(now.year, now.month, now.day)));
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
