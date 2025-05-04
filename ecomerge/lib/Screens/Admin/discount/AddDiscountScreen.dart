import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters

class AddDiscountScreen extends StatefulWidget {
  // Optional discount data for editing
  final Map<String, dynamic>? discount;

  const AddDiscountScreen({Key? key, this.discount}) : super(key: key);

  @override
  _AddDiscountScreenState createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _maxUsageController = TextEditingController();

  // Fixed discount value options
  final List<double> _discountValueOptions = [10000, 20000, 50000, 100000];
  double? _selectedDiscountValue; // Stored as double

  // Keep track of original code if editing to prevent changing unique key
  String? _originalCode;


  @override
  void initState() {
    super.initState();
    if (widget.discount != null) {
      // Editing existing discount
      _originalCode = widget.discount!['ma_code']?.toString();
      _codeController.text = _originalCode ?? ''; // Code cannot be changed in edit mode (typically)
      _maxUsageController.text = widget.discount!['so_lan_su_dung_toi_da']?.toString() ?? '10';

      // Find the matching discount value in our options
      final existingValue = (widget.discount!['gia_tri_giam'] as num?)?.toDouble();
      if (existingValue != null && _discountValueOptions.contains(existingValue)) {
          _selectedDiscountValue = existingValue;
      } else {
         // Handle case where existing value is not in options, maybe default or show error
         _selectedDiscountValue = null; // User must re-select
      }

      // Note: 'so_lan_da_su_dung' and 'ngay_tao' are for display in list/detail, not edited here.
      // 'ngay_het_han' is explicitly not included as per requirement.

    } else {
      // Adding new discount
      _maxUsageController.text = '10'; // Default max usage as per schema default
      _selectedDiscountValue = null; // No default value selected for new
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _maxUsageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Validation passed

      // Collect data
      final newDiscountData = {
        'ma_code': _codeController.text.toUpperCase(), // Save code in uppercase maybe?
        'gia_tri_giam': _selectedDiscountValue, // Already a double
        'so_lan_su_dung_toi_da': int.parse(_maxUsageController.text), // Validated as int
        // When adding, so_lan_da_su_dung will be 0 and ngay_tao will be current time on backend.
        // When editing, these values (and original 'id') should be preserved from widget.discount
        // and sent back to the backend along with the updated fields.
        // For this sample, we'll just print the *new* or *updated* fields.
        'id': widget.discount?['id'], // Include ID if editing
        'so_lan_da_su_dung': widget.discount?['so_lan_da_su_dung'] ?? 0, // Preserve used count if editing
        'ngay_tao': widget.discount?['ngay_tao'], // Preserve creation date if editing
         // Add other original fields if needed for update API call
      };

      print('Form submitted for discount:');
      print(newDiscountData);

      // TODO: Send newDiscountData to your backend API to create or update the discount

      // Navigate back after saving
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.discount != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Cập nhật Mã giảm giá' : 'Thêm Mã giảm giá'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                isEditing ? 'Thông tin Mã giảm giá' : 'Nhập thông tin Mã giảm giá mới:',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Mã Code
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Mã code (5 ký tự chữ và số)',
                   // Disable editing code if in edit mode
                   enabled: !isEditing, // Disable if editing
                ),
                maxLength: 5,
                // Input formatter to allow only alphanumeric characters
                 inputFormatters: [
                   FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                 ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã code';
                  }
                  if (value.length != 5) {
                     return 'Mã code phải có đúng 5 ký tự';
                  }
                   // Can add more validation here if needed (e.g., check uniqueness on backend)
                  return null;
                },
                 // Show initial code if editing, but don't allow changing it
                 initialValue: isEditing ? _originalCode : null,
                 // Don't show controller and initialValue at the same time
                 // initialValue is for display when field is disabled/not controlled manually initially
                 // We use controller, so 'enabled: !isEditing' handles it.
              ),
              const SizedBox(height: 16),

              // Giá trị giảm cố định
              DropdownButtonFormField<double>(
                value: _selectedDiscountValue,
                decoration: const InputDecoration(labelText: 'Giá trị giảm (VNĐ)'),
                items: _discountValueOptions.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text('${value.toStringAsFixed(0)} VNĐ'),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDiscountValue = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn giá trị giảm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Số lần sử dụng tối đa
              TextFormField(
                controller: _maxUsageController,
                decoration: const InputDecoration(labelText: 'Số lần sử dụng tối đa (<= 10)'),
                keyboardType: TextInputType.number,
                maxLength: 2, // Max 2 digits for <= 10
                // Input formatter to allow only digits
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                 ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lần tối đa';
                  }
                  final int? maxUsage = int.tryParse(value);
                  if (maxUsage == null) {
                     return 'Số lần tối đa phải là số nguyên';
                  }
                  if (maxUsage <= 0 || maxUsage > 10) {
                    return 'Phải là số nguyên từ 1 đến 10';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // TODO: If editing, display 'Số lần đã sử dụng' and 'Ngày tạo' here for info

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(isEditing ? 'Cập nhật Mã giảm giá' : 'Thêm Mã giảm giá'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
