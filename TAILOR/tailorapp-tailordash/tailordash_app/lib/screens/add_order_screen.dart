import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({Key? key}) : super(key: key);

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  String _customerName = '';
  String _customerPhone = '';
  String _clothingType = '';
  String _description = '';
  String _notes = '';
  DateTime? _dueDate;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await _apiService.createOrder({
        'customer_name': _customerName,
        'customer_phone': _customerPhone,
        'clothing_type': _clothingType,
        'description': _description,
        'notes': _notes,
        'due_date': _dueDate?.toIso8601String().split('T')[0], // YYYY-MM-DD
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully!'), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _customerName = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)', border: OutlineInputBorder()),
                onSaved: (v) => _customerPhone = v ?? '',
              ),
              
              const SizedBox(height: 24),
              const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Clothing Type (e.g., Suit, Dress)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _clothingType = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description / Instructions', border: OutlineInputBorder()),
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 12),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate == null ? 'Select Due Date' : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryPurple),
                onTap: () => _selectDueDate(context),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save Order', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
