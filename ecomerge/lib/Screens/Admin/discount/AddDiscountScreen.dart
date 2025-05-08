import 'package:e_commerce_app/database/models/coupon_dto.dart';
import 'package:e_commerce_app/database/services/coupon_service.dart';
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
  final CouponService _couponService =
      CouponService(); // Instantiate CouponService
  bool _isSubmitting = false; // To prevent multiple submissions

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
      _codeController.text = _originalCode ??
          ''; // Code cannot be changed in edit mode (typically)
      _maxUsageController.text =
          widget.discount!['so_lan_su_dung_toi_da']?.toString() ?? '10';

      // Find the matching discount value in our options
      final existingValue =
          (widget.discount!['gia_tri_giam'] as num?)?.toDouble();
      if (existingValue != null &&
          _discountValueOptions.contains(existingValue)) {
        _selectedDiscountValue = existingValue;
      } else {
        // Handle case where existing value is not in options, maybe default or show error
        _selectedDiscountValue = null; // User must re-select
      }

      // Note: Editing functionality for existing coupons via API is not covered by the provided CouponController.
      // The backend only has POST for create and GET for search.
      // This screen will primarily focus on ADDING new coupons.
      // If editing were supported, you'd need a PUT endpoint and corresponding service method.
    } else {
      // Adding new discount
      _maxUsageController.text =
          '10'; // Default max usage as per schema default
      _selectedDiscountValue = null; // No default value selected for new
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _maxUsageController.dispose();
    _couponService.dispose(); // Dispose the service
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      final createRequest = CreateCouponRequestDTO(
        code: _codeController.text.toUpperCase(),
        discountValue: _selectedDiscountValue!,
        maxUsageCount: int.parse(_maxUsageController.text),
      );

      try {
        // For new coupons (widget.discount == null)
        if (widget.discount == null) {
          await _couponService.createCoupon(createRequest);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Mã giảm giá "${createRequest.code}" đã được tạo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          // Editing existing discount - NOT SUPPORTED BY CURRENT BACKEND
          // If backend supported PUT /api/coupons/{id}
          // final updateRequest = UpdateCouponRequestDTO(...);
          // await _couponService.updateCoupon(widget.discount!['id'], updateRequest);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Mã giảm giá đã được cập nhật!'), backgroundColor: Colors.green),
          // );
          // Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chức năng cập nhật mã giảm giá chưa được hỗ trợ.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
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
                isEditing
                    ? 'Thông tin Mã giảm giá'
                    : 'Nhập thông tin Mã giảm giá mới:',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  // Check for at least one letter
                  if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                    return 'Mã code phải chứa ít nhất một chữ cái';
                  }
                  // Check for at least one number
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Mã code phải chứa ít nhất một chữ số';
                  }
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
                decoration:
                    const InputDecoration(labelText: 'Giá trị giảm (VNĐ)'),
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
                decoration: const InputDecoration(
                    labelText: 'Số lần sử dụng tối đa (<= 10)'),
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

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: _isSubmitting ? Colors.grey : null,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(isEditing
                        ? 'Cập nhật Mã giảm giá'
                        : 'Thêm Mã giảm giá'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
