import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/address_service.dart';
import 'package:flutter/material.dart';

class AddressDisplay extends StatefulWidget {
  final AddressData? currentAddress;
  final Function(AddressData) onAddressSelected;

  const AddressDisplay({
    Key? key,
    this.currentAddress,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressDisplay> createState() => _AddressDisplayState();
}

class _AddressDisplayState extends State<AddressDisplay> {
  bool _isLoading = false;
  String? _errorMessage;
  final AddressService _addressService = AddressService();

  @override
  void initState() {
    super.initState();
    // If no address is provided, try to fetch the default address
    if (widget.currentAddress == null) {
      _fetchDefaultAddress();
    }
  }

  Future<void> _fetchDefaultAddress() async {
    // Check if user is logged in
    final bool isLoggedIn = UserInfo().currentUser != null;
    if (!isLoggedIn) {
      return; // Don't fetch if not logged in
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch addresses from service
      final addresses = await _addressService.getUserAddresses();

      // Find default address or use first address
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => addresses.first,
        );

        // Convert to AddressData format
        final addressData = AddressData(
          id: defaultAddress.id, // Add this line to pass the id
          name: defaultAddress.recipientName,
          phone: defaultAddress.phoneNumber,
          address: _extractAddress(defaultAddress.specificAddress),
          province: _extractProvince(defaultAddress.specificAddress),
          district: _extractDistrict(defaultAddress.specificAddress),
          ward: _extractWard(defaultAddress.specificAddress),
          isDefault: defaultAddress.isDefault,
        );

        // Notify parent widget
        widget.onAddressSelected(addressData);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải địa chỉ mặc định';
      });
      print('Error fetching default address: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods to extract address parts
  String _extractAddress(String fullAddress) {
    final parts = fullAddress.split(',');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  String _extractWard(String fullAddress) {
    final parts = fullAddress.split(',');
    return parts.length > 1 ? parts[1].trim() : '';
  }

  String _extractDistrict(String fullAddress) {
    final parts = fullAddress.split(',');
    return parts.length > 2 ? parts[2].trim() : '';
  }

  String _extractProvince(String fullAddress) {
    final parts = fullAddress.split(',');
    return parts.length > 3 ? parts[3].trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    // Check login status
    final bool isLoggedIn = UserInfo().currentUser != null;

    // Show loading indicator if fetching address
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Địa Chỉ Nhận Hàng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      );
    }

    // Show error message if any
    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Địa Chỉ Nhận Hàng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // If address exists, show address details
    if (widget.currentAddress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.currentAddress!.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 15.0),
              ),
              const SizedBox(width: 12),
              Text(
                widget.currentAddress!.phone,
                style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.currentAddress!.fullAddress,
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // Otherwise show the default message if no address is available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vui lòng thêm địa chỉ nhận hàng',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
