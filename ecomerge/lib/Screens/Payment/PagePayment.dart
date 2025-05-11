import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/coupon_service.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Payment/bodyPayment.dart'; // Đổi tên file nếu cần
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/Payment/AddressSelector.dart';
import 'package:e_commerce_app/widgets/Payment/VoucherSelector.dart';
import 'package:e_commerce_app/widgets/Payment/LoggedInAddressSelector.dart';
import 'package:e_commerce_app/widgets/Payment/GuestAddressSelector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_app/database/models/cart_item_model.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:e_commerce_app/database/models/order/CreateOrderRequestDTO.dart';
import 'package:e_commerce_app/database/models/order/OrderDetailRequestDTO.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';

// Update the constructor to accept sourceProductId
class PagePayment extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final int? sourceProductId; // ID of the product page that led here
  final bool sourceCartPage; // New flag to indicate if coming from cart page

  const PagePayment({
    Key? key,
    required this.cartItems,
    this.sourceProductId, // Optional parameter
    this.sourceCartPage = false, // Default to false
  }) : super(key: key);

  @override
  State<PagePayment> createState() => _PagePaymentState();
}

// Make sure to use this parameter in the state class
class _PagePaymentState extends State<PagePayment> {
  int? get sourceProductId => widget.sourceProductId;
  bool get sourceCartPage => widget.sourceCartPage;

  // --- Address State ---
  final List<AddressData> _addresses = [];
  AddressData? _currentAddress;

  // --- Voucher State ---
  final List<VoucherData> _availableVouchers = [
    VoucherData(
      code: 'WELCOME10',
      description: 'Giảm 10% cho đơn hàng đầu tiên',
      discountAmount: 10,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      isPercent: true,
      minSpend: 0,
    ),
    VoucherData(
      code: 'FREESHIP',
      description: 'Miễn phí vận chuyển cho đơn hàng từ 200K',
      discountAmount: 30000,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      isPercent: false,
      minSpend: 200000,
    ),
    VoucherData(
      code: 'SALE50K',
      description: 'Giảm 50K cho đơn hàng từ 500K',
      discountAmount: 50000,
      expiryDate: DateTime.now().add(const Duration(days: 15)),
      isPercent: false,
      minSpend: 500000,
    ),
  ];
  VoucherData? _currentVoucher;
  final TextEditingController _voucherCodeController = TextEditingController();
  String? _voucherErrorMessage;

  // --- Accumulated Points State ---
  bool _useAccumulatedPoints = false;
  double _pointsDiscountAmount = 0.0;

  // --- Payment Method State ---
  String _selectedPaymentMethod = 'Thanh toán khi nhận hàng';

  // --- Calculation Constants ---
  final double _taxRate = 0.05;
  final double _shippingFee = 20000;

  // --- UI State ---
  bool _isProcessing = false;
  bool _isLoggedIn = true;

  // Instantiate OrderService
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    if (_addresses.isNotEmpty) {
      _currentAddress = _addresses.firstWhere((addr) => addr.isDefault,
          orElse: () => _addresses.first);
    }
  }

  @override
  void dispose() {
    _voucherCodeController.dispose();
    _orderService.dispose();
    super.dispose();
  }

  double _calculateSubtotal() {
    return widget.cartItems
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _calculateRawPotentialDiscount(VoucherData voucher, double subtotal) {
    if (voucher.isPercent) {
      return (subtotal * voucher.discountAmount / 100.0);
    } else {
      return voucher.discountAmount.toDouble();
    }
  }

  double _calculateDiscount() {
    if (_currentVoucher == null) return 0;

    double subtotal = _calculateSubtotal();

    if (subtotal < _currentVoucher!.minSpend) {
      print(
          "Warning: _calculateDiscount called with voucher not meeting minSpend. Voucher: ${_currentVoucher!.code}, Subtotal: $subtotal");
      return 0;
    }

    double potentialDiscount =
        _calculateRawPotentialDiscount(_currentVoucher!, subtotal);

    if (potentialDiscount > subtotal) {
      return subtotal;
    }

    return potentialDiscount;
  }

  double _calculateTax() {
    return _calculateSubtotal() * _taxRate;
  }

  double _calculateTotal() {
    double subtotalAfterProductDiscounts = _calculateSubtotal();
    double discount = _calculateDiscount();
    double tax = _calculateTax();
    double total = subtotalAfterProductDiscounts +
        _shippingFee +
        tax -
        discount -
        _pointsDiscountAmount;
    return total < 0 ? 0 : total;
  }

  double _calculateSumOfOriginalItemPrices() {
    return widget.cartItems
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _calculateTotalProductSpecificDiscount() {
    double sumOriginalPrices = 0.0;
    double sumDiscountedPrices = 0.0;
    
    for (var item in widget.cartItems) {
      double price = item.price; // This is already the final discounted price
      double originalPrice = price;
      
      // Calculate the original price if there's a discount percentage
      if (item.discountPercentage != null && item.discountPercentage! > 0) {
        // Original price = discounted price / (1 - discount percentage/100)
        originalPrice = price / (1 - (item.discountPercentage! / 100));
      }
      
      // Add to sums
      sumOriginalPrices += originalPrice * item.quantity;
      sumDiscountedPrices += price * item.quantity;
    }
    
    // Total discount is the difference between original and discounted totals
    return sumOriginalPrices - sumDiscountedPrices;
  }

  String _formatCurrency(num amount) {
    final formatter =
        NumberFormat.decimalPatternDigits(locale: 'vi_VN', decimalDigits: 0);
    return '${formatter.format(amount)} VND';
  }

  bool _hasValidAddress() {
    return _currentAddress != null;
  }

  void _updateSelectedAddress(AddressData newAddress) {
    setState(() {
      _currentAddress = newAddress;
    });
    print("PagePayment: Address updated to ${newAddress.name}");
  }

  void _addNewAddressToList(AddressData newAddress) {
    if (_addresses.any((addr) =>
        addr.fullAddress == newAddress.fullAddress &&
        addr.name == newAddress.name)) {
      print("PagePayment: Address already exists.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Địa chỉ này đã tồn tại.')),
      );
      return;
    }
    setState(() {
      _addresses.add(newAddress);
      print("PagePayment: Added new address - ${newAddress.name}");
    });
  }

  void _updateExistingAddress(int index, AddressData updatedAddress) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        final previousDefault = _addresses[index].isDefault;
        final newIsDefault = updatedAddress.isDefault;

        if (!previousDefault && newIsDefault) {
          for (int i = 0; i < _addresses.length; i++) {
            if (i != index && _addresses[i].isDefault) {
              _addresses[i] = _addresses[i].copyWith(isDefault: false);
            }
          }
        }

        _addresses[index] = updatedAddress;

        if (previousDefault || newIsDefault || _currentAddress == null) {
          _currentAddress = _addresses.firstWhere((addr) => addr.isDefault,
              orElse: () => _addresses.first);
        }

        print(
            "PagePayment: Updated address at index $index - ${updatedAddress.name}, isDefault: ${updatedAddress.isDefault}");
        print(
            "PagePayment: Current selected address: ${_currentAddress?.name}, isDefault: ${_currentAddress?.isDefault}");
      });
    } else {
      print("PagePayment: Invalid index for address update ($index)");
    }
  }

  void _deleteAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      if (_addresses[index].isDefault) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa địa chỉ mặc định.')),
        );
        return;
      }
      if (_addresses[index] == _currentAddress) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể xóa địa chỉ đang được chọn.')),
        );
        return;
      }

      setState(() {
        final removedAddress = _addresses.removeAt(index);
        print("PagePayment: Removed address - ${removedAddress.name}");
      });
    } else {
      print("PagePayment: Invalid index for address deletion ($index)");
    }
  }

  void _setAddressAsDefault(int index) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        for (int i = 0; i < _addresses.length; i++) {
          if (i != index && _addresses[i].isDefault) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
            print(
                "PagePayment: Removed default status from address ${_addresses[i].name}");
          }
        }

        _addresses[index] = _addresses[index].copyWith(isDefault: true);

        _currentAddress = _addresses[index];

        print(
            "PagePayment: Set address at index $index as default - ${_addresses[index].name}");
        print(
            "PagePayment: Current selected address updated to: ${_currentAddress?.name}");
      });
    }
  }

  void _updateSelectedVoucher(VoucherData? voucher) {
    setState(() {
      if (voucher == null) {
        _currentVoucher = null;
        _voucherErrorMessage = null;
        print("PagePayment: Voucher deselected.");
        return;
      }

      double subtotal = _calculateSubtotal();

      if (subtotal < voucher.minSpend) {
        _currentVoucher = null;
        _voucherErrorMessage =
            'Đơn hàng chưa đạt giá trị tối thiểu ${_formatCurrency(voucher.minSpend)} để dùng voucher này.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_voucherErrorMessage!),
              backgroundColor: Colors.orange),
        );
        print(
            "PagePayment: Voucher ${voucher.code} not applied. Min spend not met.");
        return;
      }

      double potentialDiscount =
          _calculateRawPotentialDiscount(voucher, subtotal);

      if (potentialDiscount > subtotal) {
        _currentVoucher = null;
        _voucherErrorMessage =
            'Giá trị giảm của voucher (${_formatCurrency(potentialDiscount)}) vượt quá tổng tiền hàng (${_formatCurrency(subtotal)}). Không thể áp dụng.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_voucherErrorMessage!),
              backgroundColor: Colors.orange),
        );
        print(
            "PagePayment: Voucher ${voucher.code} not applied. Discount exceeds subtotal.");
        return;
      }

      _currentVoucher = voucher;
      _voucherErrorMessage = null;
      print("PagePayment: Voucher selected - ${voucher.code}");
    });
  }

  void _validateAndApplyVoucher(String code) {
    print('PagePayment: Attempting to apply voucher code: $code');
    if (code.isEmpty) {
      setState(() => _voucherErrorMessage = 'Vui lòng nhập mã voucher');
      return;
    }

    try {
      final voucher = _availableVouchers.firstWhere(
        (v) =>
            v.code.toLowerCase() == code.toLowerCase() &&
            v.expiryDate.isAfter(DateTime.now()),
      );

      double subtotal = _calculateSubtotal();

      if (subtotal < voucher.minSpend) {
        setState(() {
          _currentVoucher = null;
          _voucherErrorMessage =
              'Đơn hàng chưa đạt giá trị tối thiểu ${_formatCurrency(voucher.minSpend)} để dùng voucher này.';
        });
        print(
            "PagePayment: Voucher ${voucher.code} not applied via code. Min spend not met.");
        return;
      }

      double potentialDiscount =
          _calculateRawPotentialDiscount(voucher, subtotal);

      if (potentialDiscount > subtotal) {
        setState(() {
          _currentVoucher = null;
          _voucherErrorMessage =
              'Giá trị giảm của voucher (${_formatCurrency(potentialDiscount)}) vượt quá tổng tiền hàng (${_formatCurrency(subtotal)}). Không thể áp dụng.';
        });
        print(
            "PagePayment: Voucher ${voucher.code} not applied via code. Discount exceeds subtotal.");
        return;
      }

      setState(() {
        _currentVoucher = voucher;
        _voucherErrorMessage = null;
        _voucherCodeController.clear();
        print("PagePayment: Voucher applied successfully - ${voucher.code}");
      });
    } catch (e) {
      setState(() {
        _currentVoucher = null;
        _voucherErrorMessage =
            'Mã voucher không hợp lệ, hết hạn hoặc không tồn tại.';
        print("PagePayment: Invalid voucher code - $code");
      });
    }
  }

  void _updatePaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
      print("PagePayment: Payment method changed to $method");
    });
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    if (_currentAddress == null || _currentAddress!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn hoặc thêm địa chỉ giao hàng hợp lệ.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Giỏ hàng của bạn đang trống.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    print("PagePayment: Processing payment...");
    print(
        "   Address ID: ${_currentAddress?.id}, Address: ${_currentAddress?.fullAddress ?? 'No address selected'}");
    print("   Products: ${widget.cartItems.length} items");
    widget.cartItems.forEach((item) {
      print(
          "     - ProductVariantID: ${item.variantId}, Name: ${item.productName}, Qty: ${item.quantity}, Price: ${item.price}");
    });
    print("   Subtotal: ${_formatCurrency(_calculateSubtotal())}");
    print("   Shipping: ${_formatCurrency(_shippingFee)}");
    print("   Tax: ${_formatCurrency(_calculateTax())}");
    print(
        "   Voucher: ${_currentVoucher?.code ?? 'None'} (${_formatCurrency(_calculateDiscount())})");
    print(
        "   Points Discount: ${_formatCurrency(_pointsDiscountAmount)} (${_useAccumulatedPoints ? 'Used' : 'Not Used'})");
    print("   Total: ${_formatCurrency(_calculateTotal())}");
    print("   Payment Method: $_selectedPaymentMethod");

    List<OrderDetailRequestDTO> orderDetails = widget.cartItems.map((item) {
      return OrderDetailRequestDTO(
        productVariantId: item.variantId,
        quantity: item.quantity,
      );
    }).toList();

    final requestDTO = CreateOrderRequestDTO(
      addressId: _currentAddress!.id!,
      orderDetails: orderDetails,
      couponCode: _currentVoucher?.code,
      paymentMethod: _selectedPaymentMethod,
      pointsToUse: _useAccumulatedPoints && _pointsDiscountAmount > 0
          ? (_pointsDiscountAmount / 1000)
          : 0,
      shippingFee: _shippingFee,
      tax: _calculateTax(),
    );

    try {
      final OrderDTO createdOrder = await _orderService.createOrder(requestDTO);
      print(
          "PagePayment: Order created successfully with ID: ${createdOrder.id}");

      // If using points, update the user's point balance
      if (_useAccumulatedPoints && _pointsDiscountAmount > 0) {
        // Calculate points used (1 point = 1000 VND)
        double pointsUsed = _pointsDiscountAmount / 1000;
        
        // Get current points balance
        double currentPoints = UserInfo().currentUser?.customerPoints ?? 0;
        
        // Calculate and update new points balance
        double newPointsBalance = currentPoints - pointsUsed;
        if (newPointsBalance < 0) newPointsBalance = 0; // Ensure non-negative
        
        // Update points in UserInfo
        UserInfo().updateCustomerPoints(newPointsBalance);
        print("PagePayment: Updated user points balance from $currentPoints to $newPointsBalance");
      }

      Map<String, dynamic> paymentSuccessArgs =
          createdOrder.toMapForPaymentSuccess();

      paymentSuccessArgs['customerID'] =
          UserInfo().currentUser?.id?.toString() ??
              paymentSuccessArgs['customerID'] ??
              'N/A';

      // Calculate product discount properly
      double totalProductDiscount = 0.0;
      for (var item in widget.cartItems) {
        if (item.discountPercentage != null && item.discountPercentage! > 0) {
          // Calculate the original price before discount
          // Original price = discounted price / (1 - discount percentage/100)
          double originalPrice = item.price / (1 - (item.discountPercentage! / 100));
          
          // Calculate the discount amount for this item
          double discountAmount = (originalPrice - item.price) * item.quantity;
          totalProductDiscount += discountAmount;
        }
      }

      paymentSuccessArgs['sumOriginalItemPrices'] = _calculateSumOfOriginalItemPrices();
      paymentSuccessArgs['productDiscount'] = totalProductDiscount;
      paymentSuccessArgs['taxRate'] = _taxRate;
      
      // Add points discount information to payment success arguments
      paymentSuccessArgs['pointsDiscount'] = _pointsDiscountAmount;
      paymentSuccessArgs['usedPoints'] = _useAccumulatedPoints && _pointsDiscountAmount > 0
          ? (_pointsDiscountAmount / 1000) : 0;
      paymentSuccessArgs['updatedPointsBalance'] = UserInfo().currentUser?.customerPoints ?? 0;
      
      print("PagePayment: Product discount: $totalProductDiscount");
      print("PagePayment: Points discount: $_pointsDiscountAmount");
      print("PagePayment: Payment success arguments: $paymentSuccessArgs");
      
      if (mounted) {
        // Correct way to pass all data through a single arguments parameter
        Navigator.pushReplacementNamed(
          context,
          '/payment_success',
          arguments: paymentSuccessArgs,
        );
      }
    } catch (e) {
      print("PagePayment: Error creating order: $e");
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('505')) {
          errorMessage = 'Đặt hàng không thành công. Vui lòng thử lại sau.';
        } else {
          errorMessage = 'Đặt hàng không thành công. Vui lòng thử lại sau.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showAddressSelectionDialog() {
    print("PagePayment: Opening Address Selector Dialog...");

    bool isLoggedIn = UserInfo().isLoggedIn;

    if (!isLoggedIn) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: GuestAddressSelector(
              addresses: _addresses,
              selectedAddress: _currentAddress,
              onAddressSelected: (selectedAddress) {
                _updateSelectedAddress(selectedAddress);
              },
              onAddNewAddress: _addNewAddressToList,
              onUpdateAddress: _updateExistingAddress,
              onDeleteAddress: _deleteAddress,
            ),
          );
        },
      ).then((_) => print("PagePayment: Address Selector Dialog closed."));
    } else {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: LoggedInAddressSelector(
              addresses: _addresses,
              selectedAddress: _currentAddress,
              onAddressSelected: (selectedAddress) {
                _updateSelectedAddress(selectedAddress);
              },
            ),
          );
        },
      ).then((_) => print("PagePayment: Address Selector Dialog closed."));
    }
  }

  void _showVoucherSelectionDialog() {
    print("PagePayment: Opening Voucher Selector Dialog...");
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: VoucherSelector(
            currentVoucher: _currentVoucher,
            onVoucherSelected: (selectedVoucher) {
              _updateSelectedVoucher(selectedVoucher);
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    ).then((_) => print("PagePayment: Voucher Selector Dialog closed."));
  }

  void _toggleUseAccumulatedPoints(bool? value) {
    if (value == null) return;

    // Get customer points as double
    final double customerPoints = UserInfo().currentUser?.customerPoints ?? 0;

    setState(() {
      if (value) {
        if (customerPoints <= 0) {
          _useAccumulatedPoints = false;
          _pointsDiscountAmount = 0.0;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không có điểm tích lũy để sử dụng.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Calculate discount amount (1 point = 1000 VND)
        double potentialPointsDiscount = customerPoints * 1000;
        double currentTotalBeforePoints = _calculateSubtotal() +
            _shippingFee +
            _calculateTax() -
            _calculateDiscount();

        // Limit point usage to the current total
        _pointsDiscountAmount = 
            (potentialPointsDiscount > currentTotalBeforePoints)
                ? currentTotalBeforePoints
                : potentialPointsDiscount;

        if (_pointsDiscountAmount < 0) _pointsDiscountAmount = 0;

        _useAccumulatedPoints = true;
      } else {
        _useAccumulatedPoints = false;
        _pointsDiscountAmount = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = _calculateSubtotal();
    final double discount = _calculateDiscount();
    final double tax = _calculateTax();
    final double total = _calculateTotal();
    Widget appBar;

    // Debug output to verify received items
    print('PagePayment: Building with ${widget.cartItems.length} items');
    for (var item in widget.cartItems) {
      print(
          ' - Item: ${item.productName}, Quantity: ${item.quantity}, Price: ${item.price}');
    }

    Widget body = BodyPayment(
      currentAddress: _currentAddress,
      products: widget.cartItems,
      currentVoucher: _currentVoucher,
      selectedPaymentMethod: _selectedPaymentMethod,
      subtotal: subtotal,
      shippingFee: _shippingFee,
      taxAmount: tax,
      taxRate: _taxRate,
      discountAmount: discount,
      pointsDiscountAmount: _pointsDiscountAmount,
      totalAmount: total,
      isProcessingOrder: _isProcessing,
      useAccumulatedPoints: _useAccumulatedPoints,
      onToggleUseAccumulatedPoints: _toggleUseAccumulatedPoints,
      onChangeAddress: _showAddressSelectionDialog,
      onSelectVoucher: _showVoucherSelectionDialog,
      onChangePaymentMethod: _updatePaymentMethod,
      onPlaceOrder: _processPayment,
      formatCurrency: _formatCurrency,
      onAddressSelected: _updateSelectedAddress,
      sourceProductId: widget.sourceProductId,
      sourceCartPage: widget.sourceCartPage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 768) {
          return NavbarFormobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          return NavbarForTablet(
            body: body,
          );
        } else {
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
            body: body,
          );
        }
      },
    );
  }
}

class AddressData {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String province;
  final String district;
  final String ward;
  final bool isDefault;

  AddressData({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.province,
    required this.district,
    required this.ward,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [address, ward, district, province]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  AddressData copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? province,
    String? district,
    String? ward,
    bool? isDefault,
  }) {
    return AddressData(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          address == other.address &&
          province == other.province &&
          district == other.district &&
          ward == other.ward &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      address.hashCode ^
      province.hashCode ^
      district.hashCode ^
      ward.hashCode ^
      isDefault.hashCode;
}

class VoucherData {
  final String code;
  final String description;
  final num discountAmount;
  final DateTime expiryDate;
  final bool isPercent;
  final double minSpend;
  final int? remainingUses;

  VoucherData({
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.expiryDate,
    this.isPercent = false,
    this.minSpend = 0.0,
    this.remainingUses,
  });

  String displayDiscount(NumberFormat formatter) {
    if (isPercent) {
      return 'Giảm ${discountAmount}%';
    } else {
      return 'Giảm ${formatter.format(discountAmount)}₫';
    }
  }

  String displayExpiry() {
    final formatter = DateFormat('dd/MM/yyyy');
    return 'HSD: ${formatter.format(expiryDate)}';
  }

  String displayCondition() {
    if (minSpend > 0) {
      final formatter = NumberFormat("#,###", "vi_VN");
      return 'Đơn tối thiểu ${formatter.format(minSpend)}₫';
    }
    return 'Cho mọi đơn hàng';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherData &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
