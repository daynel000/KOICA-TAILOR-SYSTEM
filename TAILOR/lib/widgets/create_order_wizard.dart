// widgets/create_order_wizard.dart - 3-step wizard for creating a new order
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/tailor_model.dart';
import '../models/scan_result_model.dart';

class CreateOrderWizard extends StatefulWidget {
  final List<TailorModel> tailors;
  final ScanResultModel? savedScanResult;
  final void Function(int) onNavigateToTab;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic> formData) onSubmit;

  const CreateOrderWizard({super.key, required this.tailors, required this.savedScanResult, required this.onNavigateToTab, required this.onCancel, required this.onSubmit});

  @override
  State<CreateOrderWizard> createState() => _CreateOrderWizardState();
}

class _CreateOrderWizardState extends State<CreateOrderWizard> {
  int _currentStep = 1; // 1, 2, or 3
  bool _isSubmitting = false;

  // Step 1: Measurements
  late double _bodyLength;
  late double _shoulderWidth;
  late double _chestWidth;
  late double _chestCircumference;
  late double _armLength;
  late double _bicepCircumference;
  late double _waistCircumference;
  late double _hipsCircumference;

  // Controllers for manual inputs
  late TextEditingController _chestController;
  late TextEditingController _waistController;
  late TextEditingController _hipsController;
  late TextEditingController _shouldersController;
  late TextEditingController _inseamController;

  // Step 2: Tailor selection
  String _selectedTailorId = '';

  // Step 3: Garment details
  String _garmentType = 'Evening Gown';
  String _fabricMaterial = 'Premium Satin';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customGarmentController = TextEditingController();
  final TextEditingController _customFabricController = TextEditingController();

  final _garmentTypes = ['Evening Gown', 'Barong Tagalog', 'Wedding Dress', 'Business Suit', 'Modern Alterations', 'Jersey', 'Other (Custom)'];
  final _fabricOptions = ['Premium Satin', 'Piña Silk Fiber', 'French Lace', 'Fine Cotton', 'Wool Blend', 'Linen Classic', 'Other (Custom)'];

  @override
  void initState() {
    super.initState();
    final scan = widget.savedScanResult;
    _bodyLength = scan?.bodyLength ?? 28.0;
    _shoulderWidth = scan?.shoulderWidth ?? 18.0;
    _chestWidth = scan?.chestWidth ?? 20.0;
    _chestCircumference = scan?.chestCircumference ?? 40.0;
    _armLength = scan?.armLength ?? 25.0;
    _bicepCircumference = scan?.bicepCircumference ?? 14.0;
    _waistCircumference = scan?.waistCircumference ?? 32.0;
    _hipsCircumference = scan?.hipsCircumference ?? 38.0;

    _chestController = TextEditingController(text: _chestCircumference.toStringAsFixed(1));
    _waistController = TextEditingController(text: _waistCircumference.toStringAsFixed(1));
    _hipsController = TextEditingController(text: _hipsCircumference.toStringAsFixed(1));
    _shouldersController = TextEditingController(text: _shoulderWidth.toStringAsFixed(1));
    _inseamController = TextEditingController(text: _bodyLength.toStringAsFixed(1));

    _selectedTailorId = widget.tailors.isNotEmpty ? widget.tailors.first.tailorId : '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _shouldersController.dispose();
    _inseamController.dispose();
    _customGarmentController.dispose();
    _customFabricController.dispose();
    super.dispose();
  }

  void _updateFieldValue(String fieldName, double newValue) {
    setState(() {
      if (fieldName == 'Chest Circ.') {
        _chestCircumference = newValue;
        _chestController.text = newValue.toStringAsFixed(1);
      } else if (fieldName == 'Waist') {
        _waistCircumference = newValue;
        _waistController.text = newValue.toStringAsFixed(1);
      } else if (fieldName == 'Hips') {
        _hipsCircumference = newValue;
        _hipsController.text = newValue.toStringAsFixed(1);
      } else if (fieldName == 'Shoulders') {
        _shoulderWidth = newValue;
        _shouldersController.text = newValue.toStringAsFixed(1);
      } else if (fieldName == 'Body Length') {
        _bodyLength = newValue;
        _inseamController.text = newValue.toStringAsFixed(1);
      }
    });
  }

  void _onFieldTextChanged(String fieldName, String text) {
    final parsed = double.tryParse(text);
    if (parsed != null) {
      if (fieldName == 'Chest Circ.') {
        _chestCircumference = parsed;
      } else if (fieldName == 'Waist') {
        _waistCircumference = parsed;
      } else if (fieldName == 'Hips') {
        _hipsCircumference = parsed;
      } else if (fieldName == 'Shoulders') {
        _shoulderWidth = parsed;
      } else if (fieldName == 'Body Length') {
        _bodyLength = parsed;
      }
    }
  }

  Future<void> _submitOrder() async {
    setState(() => _isSubmitting = true);
    final finalGarmentType = _garmentType == 'Other (Custom)' 
        ? _customGarmentController.text.trim() 
        : _garmentType;
    final finalFabricMaterial = _fabricMaterial == 'Other (Custom)' 
        ? _customFabricController.text.trim() 
        : _fabricMaterial;

    await widget.onSubmit({
      'tailor_id': _selectedTailorId,
      'garment_type': finalGarmentType.isEmpty ? 'Custom Garment' : finalGarmentType,
      'fabric_material': finalFabricMaterial.isEmpty ? 'Custom Fabric' : finalFabricMaterial,
      'customer_notes': _notesController.text,
      'body_length': _bodyLength,
      'shoulder_width': _shoulderWidth,
      'chest_width': _chestWidth,
      'chest_circumference': _chestCircumference,
      'arm_length': _armLength,
      'bicep_circumference': _bicepCircumference,
      'waist_circumference': _waistCircumference,
      'hips_circumference': _hipsCircumference,
    });
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(children: [
          IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textSecondary), onPressed: widget.onCancel),
          const Expanded(child: Text('Create New Request', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
          const SizedBox(width: 40),
        ])),
        // Step indicators
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [
          Text('Step $_currentStep of 3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const Spacer(),
          Row(children: List.generate(3, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            height: 5, width: _currentStep == i + 1 ? 20 : 8,
            decoration: BoxDecoration(
              color: _currentStep > i + 1 ? AppColors.emerald : _currentStep == i + 1 ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ))),
        ])),
        Divider(color: AppColors.border, height: 20),
        // Step content
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _currentStep == 1 ? _buildStep1() : _currentStep == 2 ? _buildStep2() : _buildStep3(),
        )),
        // Footer buttons
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: _currentStep == 1 ? widget.onCancel : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(_currentStep == 1 ? 'Cancel' : 'Back'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _isSubmitting ? null : () {
                if (_currentStep < 3) { setState(() => _currentStep++); }
                else { _submitOrder(); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_currentStep < 3 ? 'Next Step' : 'Submit Request', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (_currentStep < 3) const Icon(Icons.chevron_right_rounded, size: 18),
                  ]),
            )),
          ]),
        ),
      ])),
    );
  }

  Widget _buildStep1() {
    final hasScan = widget.savedScanResult != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: Icon(Icons.straighten_rounded, size: 28, color: AppColors.primaryLight)),
        const SizedBox(height: 8),
        const Text('Calibrate Body Dimensions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
        Text('Apply scanned or manual measurements', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ])),
      const SizedBox(height: 20),
      if (hasScan)
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.3))), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('✨ Active AI Scan Results', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text('Size: ${widget.savedScanResult!.recommendedSize}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryLight))),
          ]),
          const SizedBox(height: 10),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 3,
            children: [
              _ScanInfoCell('Body Length', '${widget.savedScanResult!.bodyLength}"', AppColors.primaryLight),
              _ScanInfoCell('Shoulders', '${widget.savedScanResult!.shoulderWidth}"', AppColors.textSecondary),
              _ScanInfoCell('Chest Circ.', '${widget.savedScanResult!.chestCircumference}"', AppColors.primaryLight),
              _ScanInfoCell('Waist', '${widget.savedScanResult!.waistCircumference}"', AppColors.emerald),
              _ScanInfoCell('Hips', '${widget.savedScanResult!.hipsCircumference}"', AppColors.amber),
              _ScanInfoCell('Size', widget.savedScanResult!.recommendedSize, AppColors.textSecondary),
            ],
          ),
        ])),
      if (!hasScan)
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Column(children: [
          Text('No AI scan saved yet. Scan first for best accuracy!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () { widget.onCancel(); widget.onNavigateToTab(3); }, style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryLight, side: BorderSide(color: AppColors.primary.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Start AI Scan Now')),
        ])),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MANUAL ADJUSTMENT (inches)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        for (final field in [
          ('Body Length', _bodyLength, _inseamController),
          ('Shoulders', _shoulderWidth, _shouldersController),
          ('Chest Circ.', _chestCircumference, _chestController),
          ('Waist', _waistCircumference, _waistController),
          ('Hips', _hipsCircumference, _hipsController),
        ]) Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(field.$1, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.background, 
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(), 
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                    icon: Icon(Icons.remove, size: 14, color: AppColors.textMuted), 
                    onPressed: () {
                      final currentVal = double.tryParse(field.$3.text) ?? field.$2;
                      _updateFieldValue(field.$1, (currentVal - 0.5).clamp(10, 80));
                    },
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        controller: field.$3,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w700, 
                          color: Color(0xFF132238), 
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          suffixText: '"',
                          suffixStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        onChanged: (val) => _onFieldTextChanged(field.$1, val),
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(), 
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                    icon: Icon(Icons.add, size: 14, color: AppColors.textMuted), 
                    onPressed: () {
                      final currentVal = double.tryParse(field.$3.text) ?? field.$2;
                      _updateFieldValue(field.$1, (currentVal + 0.5).clamp(10, 80));
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ])),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        const Text('Match with Local Tailor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
        const SizedBox(height: 4),
        const Text('Select a premium tailoring shop', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ])),
      const SizedBox(height: 20),
      ...widget.tailors.map((tailor) => GestureDetector(
        onTap: () => setState(() => _selectedTailorId = tailor.tailorId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _selectedTailorId == tailor.tailorId ? AppColors.primary : AppColors.border, width: _selectedTailorId == tailor.tailorId ? 1.5 : 1),
          ),
          child: Row(children: [
            CircleAvatar(radius: 4, backgroundColor: _selectedTailorId == tailor.tailorId ? AppColors.primary : AppColors.border),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tailor.shopName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF132238))),
                Text(tailor.distanceFromCustomer, style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 2),
              Text(tailor.location, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4, children: tailor.specialties.take(3).map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)), child: Text(s, style: TextStyle(fontSize: 8, color: AppColors.textSecondary)))).toList()),
            ])),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        const Text('Garment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF132238))),
        const SizedBox(height: 4),
        const Text('Configure fabric and customization notes', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ])),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GARMENT TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _garmentType,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Color(0xFF132238), fontSize: 13),
          decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: _garmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _garmentType = v!),
        ),
        if (_garmentType == 'Other (Custom)') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customGarmentController,
            style: const TextStyle(color: Color(0xFF132238), fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Enter custom garment type (e.g. Silk Kimono, Tuxedo)',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('FABRIC SELECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 3.5,
          children: _fabricOptions.map((fab) => GestureDetector(
            onTap: () => setState(() => _fabricMaterial = fab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _fabricMaterial == fab ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fabricMaterial == fab ? AppColors.primary : AppColors.border),
              ),
              child: Text(fab, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _fabricMaterial == fab ? AppColors.primaryLight : AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )).toList(),
        ),
        if (_fabricMaterial == 'Other (Custom)') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customFabricController,
            style: const TextStyle(color: Color(0xFF132238), fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Enter custom fabric material (e.g. Velvet Corduroy, Heavy Denim)',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('INSTRUCTIONS & NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController, maxLines: 4,
          style: const TextStyle(color: Color(0xFF132238), fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Custom notes: color, collar style, hem preferences, beadwork...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ])),
    ]);
  }
}

class _ScanInfoCell extends StatelessWidget {
  final String label; final String value; final Color color;
  const _ScanInfoCell(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
    ]),
  );
}
