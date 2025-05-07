import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Payment/bodyPayment.dart'; // Đổi tên file nếu cần
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/Payment/AddressSelector.dart';
import 'package:e_commerce_app/widgets/Payment/VoucherSelector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PagePayment extends StatefulWidget {
  const PagePayment({super.key});

  @override
  State<PagePayment> createState() => _PagePaymentState();
}

class _PagePaymentState extends State<PagePayment> {
  // --- Address State ---
  final List<AddressData> _addresses = []; // Initialize as empty list
  AddressData? _currentAddress; // Make nullable to handle no addresses case

  // --- Product State ---
  final List<Map<String, dynamic>> _products = [
    // Dữ liệu sản phẩm (có thể lấy từ giỏ hàng)
    {
      'image': 'https://i.imgur.com/kZTgHwQ.png',
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho...',
      'price': 42000,
      'quantity': 1,
    },
    {
      'image': 'https://via.placeholder.com/60',
      'name': 'Sản phẩm B - Mô tả dài hơn một chút',
      'price': 150000,
      'quantity': 2,
    },
  ];

  // --- Voucher State ---
  final List<VoucherData> _availableVouchers = [
    // Danh sách voucher khả dụng
    VoucherData(
      code: 'WELCOME10',
      description: 'Giảm 10% cho đơn hàng đầu tiên',
      discountAmount: 10, // Sửa thành 10 (đơn vị %)
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      isPercent: true,
      minSpend: 0, // Ngưỡng tối thiểu
    ),
    VoucherData(
      code: 'FREESHIP',
      description: 'Miễn phí vận chuyển cho đơn hàng từ 200K',
      discountAmount: 30000, // Giảm trực tiếp 30k tiền ship
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      isPercent: false, // Đây là giảm tiền trực tiếp
      minSpend: 200000, // Ngưỡng tối thiểu
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
  VoucherData? _currentVoucher; // Voucher đang được chọn
  final TextEditingController _voucherCodeController =
      TextEditingController(); // Chỉ dùng khi áp dụng mã thủ công (có thể không cần nếu chỉ chọn từ list)
  String? _voucherErrorMessage; // Thông báo lỗi voucher

  // --- Payment Method State ---
  String _selectedPaymentMethod =
      'Thanh toán khi nhận hàng'; // Phương thức thanh toán mặc định

  // --- Calculation Constants ---
  final double _taxRate = 0.1; // 10% tax (Giả sử VAT là 10%)
  final double _shippingFee = 30000; // Phí vận chuyển cố định (ví dụ)
  // --- UI State ---
  bool _isProcessing = false; // Trạng thái đang xử lý đặt hàng
  bool _isLoggedIn = true; // Trạng thái đăng nhập
  // Scroll controller và key nếu cần cho logic cuộn phức tạp ở PagePayment
  // final ScrollController _scrollController = ScrollController();
  // final GlobalKey _paymentInfoKey = GlobalKey();

  //============================================================================
  // LIFECYCLE METHODS
  //============================================================================

  @override
  void initState() {
    super.initState();
    // Only set _currentAddress if addresses are available
    if (_addresses.isNotEmpty) {
      _currentAddress = _addresses.firstWhere((addr) => addr.isDefault,
          orElse: () => _addresses.first);
    }
    // Otherwise, _currentAddress remains null
  }

  @override
  void dispose() {
    _voucherCodeController.dispose();
    // _scrollController.dispose(); // Dispose nếu dùng
    super.dispose();
  }

  //============================================================================
  // CALCULATION LOGIC (Logic tính toán tập trung)
  //============================================================================

  double _calculateSubtotal() {
    return _products.fold(
        0.0, (sum, product) => sum + (product['price'] * product['quantity']));
  }

  double _calculateDiscount() {
    if (_currentVoucher == null) return 0;

    double subtotal = _calculateSubtotal();

    // Kiểm tra ngưỡng chi tiêu tối thiểu
    if (subtotal < _currentVoucher!.minSpend) {
      // Có thể hiển thị thông báo hoặc đơn giản là không áp dụng giảm giá
      print(
          "Subtotal doesn't meet minimum spend for voucher ${_currentVoucher!.code}");
      return 0;
    }

    if (_currentVoucher!.isPercent) {
      // Tính toán giảm giá phần trăm
      return (subtotal * _currentVoucher!.discountAmount / 100.0);
    } else {
      // Giảm giá số tiền cố định
      return _currentVoucher!.discountAmount.toDouble();
    }
  }

  double _calculateTax() {
    // Thuế tính trên tổng tiền hàng sau khi đã trừ voucher hay trước?
    // Thông thường, thuế tính trên giá trị hàng hóa TRƯỚC khi giảm giá vận chuyển/voucher tổng.
    // Tuy nhiên, luật có thể khác nhau. Ở đây giả sử tính trên subtotal.
    return _calculateSubtotal() * _taxRate;
    // Hoặc nếu thuế tính sau khi giảm giá voucher:
    // return (_calculateSubtotal() - _calculateDiscount()) * _taxRate;
  }

  double _calculateTotal() {
    double subtotal = _calculateSubtotal();
    double discount = _calculateDiscount();
    double tax = _calculateTax();
    // Đảm bảo tổng không âm
    double total = subtotal + _shippingFee + tax - discount;
    return total < 0 ? 0 : total;
  }

  // Helper định dạng tiền tệ
  String _formatCurrency(num amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return '₫${formatter.format(amount)}';
  }

  // Function to check if we have a valid address
  bool _hasValidAddress() {
    return _currentAddress != null;
  }

  //============================================================================
  // ACTION HANDLERS (Hàm xử lý sự kiện tập trung)
  //============================================================================

  // --- Address Actions ---
  void _updateSelectedAddress(AddressData newAddress) {
    setState(() {
      _currentAddress = newAddress;
      // Cập nhật trạng thái isDefault nếu cần (logic phức tạp hơn)
      // Ví dụ: bỏ default cũ, đặt default mới
    });
    print("PagePayment: Address updated to ${newAddress.name}");
  }

  void _addNewAddressToList(AddressData newAddress) {
    // Kiểm tra trùng lặp cơ bản (có thể cần logic phức tạp hơn)
    if (_addresses.any((addr) =>
        addr.fullAddress == newAddress.fullAddress &&
        addr.name == newAddress.name)) {
      print("PagePayment: Address already exists.");
      // Có thể hiển thị SnackBar thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Địa chỉ này đã tồn tại.')),
      );
      return;
    }
    setState(() {
      _addresses.add(newAddress);
      // Tự động chọn địa chỉ mới thêm làm địa chỉ hiện tại? (Tùy yêu cầu)
      // _currentAddress = newAddress;
      print("PagePayment: Added new address - ${newAddress.name}");
    });
  }

  void _updateExistingAddress(int index, AddressData updatedAddress) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        // Giữ lại trạng thái isDefault của địa chỉ gốc nếu không có logic thay đổi default
        final bool wasDefault = _addresses[index].isDefault;
        _addresses[index] = AddressData(
          name: updatedAddress.name,
          phone: updatedAddress.phone,
          address: updatedAddress.address,
          province: updatedAddress.province,
          district: updatedAddress.district,
          ward: updatedAddress.ward,
          isDefault: wasDefault, // Giữ lại trạng thái default cũ
        );
        // Nếu địa chỉ được cập nhật là địa chỉ hiện tại, cập nhật _currentAddress
        if (_currentAddress?.name == _addresses[index].name &&
            _currentAddress?.phone == _addresses[index].phone) {
          // Cần cách xác định địa chỉ chính xác hơn ID duy nhất
          _currentAddress = _addresses[index];
        }
        print(
            "PagePayment: Updated address at index $index - ${updatedAddress.name}");
      });
    } else {
      print("PagePayment: Invalid index for address update ($index)");
    }
  }

  void _deleteAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      // Không cho xóa địa chỉ mặc định hoặc địa chỉ đang được chọn? (Tùy logic)
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
        // Nếu danh sách rỗng sau khi xóa? Xử lý...
      });
    } else {
      print("PagePayment: Invalid index for address deletion ($index)");
    }
  }

  void _setAddressAsDefault(int index) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        // Bỏ default của địa chỉ hiện tại
        for (int i = 0; i < _addresses.length; i++) {
          if (_addresses[i].isDefault) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
            break; // Chỉ có 1 default
          }
        }
        // Đặt default cho địa chỉ mới
        _addresses[index] = _addresses[index].copyWith(isDefault: true);
        // Cập nhật luôn địa chỉ đang chọn là địa chỉ mặc định mới
        _currentAddress = _addresses[index];
        print(
            "PagePayment: Set address at index $index as default - ${_addresses[index].name}");
      });
    }
  }

  // --- Voucher Actions ---
  void _updateSelectedVoucher(VoucherData? voucher) {
    setState(() {
      _currentVoucher = voucher;
      _voucherErrorMessage = null; // Xóa lỗi cũ khi chọn voucher mới
      print("PagePayment: Voucher selected - ${voucher?.code}");
    });
  }

  // Hàm này có thể dùng nếu có ô nhập mã voucher trực tiếp trong PagePayment
  // Hoặc logic kiểm tra voucher khi chọn từ VoucherSelector
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
            v.expiryDate.isAfter(DateTime.now()), // Kiểm tra cả hạn sử dụng
      );

      // Kiểm tra điều kiện tối thiểu (nếu có)
      if (_calculateSubtotal() < voucher.minSpend) {
        setState(() {
          _currentVoucher = null; // Không áp dụng
          _voucherErrorMessage =
              'Đơn hàng chưa đạt giá trị tối thiểu ${_formatCurrency(voucher.minSpend)} để dùng voucher này.';
        });
        return;
      }

      // Áp dụng thành công
      setState(() {
        _currentVoucher = voucher;
        _voucherErrorMessage = null;
        _voucherCodeController.clear(); // Xóa ô input nếu có
        print("PagePayment: Voucher applied successfully - ${voucher.code}");
      });
    } catch (e) {
      // 'firstWhere' ném lỗi nếu không tìm thấy
      setState(() {
        _currentVoucher = null; // Xóa voucher cũ nếu có
        _voucherErrorMessage =
            'Mã voucher không hợp lệ, hết hạn hoặc không tồn tại.';
        print("PagePayment: Invalid voucher code - $code");
      });
    }
  }

  // --- Payment Method Actions ---
  void _updatePaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
      print("PagePayment: Payment method changed to $method");
    });
  }

  // --- Order Processing Action ---
  Future<void> _processPayment() async {
    if (_isProcessing) return; // Ngăn chặn nhấn nhiều lần

    setState(() => _isProcessing = true);
    print("PagePayment: Processing payment...");
    print(
        "   Address: ${_currentAddress?.fullAddress ?? 'No address selected'}");
    print("   Products: ${_products.length} items");
    print("   Subtotal: ${_formatCurrency(_calculateSubtotal())}");
    print("   Shipping: ${_formatCurrency(_shippingFee)}");
    print("   Tax: ${_formatCurrency(_calculateTax())}");
    print(
        "   Voucher: ${_currentVoucher?.code ?? 'None'} (${_formatCurrency(_calculateDiscount())})");
    print("   Total: ${_formatCurrency(_calculateTotal())}");
    print("   Payment Method: $_selectedPaymentMethod");

    // Simulate API call or actual payment logic
    await Future.delayed(const Duration(seconds: 2));

    // Sau khi xử lý xong
    setState(() => _isProcessing = false);

    // Hiển thị thông báo thành công
    showDialog(
      context: context,
      barrierDismissible: false, // Không đóng khi chạm bên ngoài
      builder: (context) => AlertDialog(
        title: const Text('Đặt hàng thành công'),
        content: const Text(
            'Cảm ơn bạn đã mua hàng! Chúng tôi sẽ xử lý đơn hàng của bạn sớm nhất.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              // TODO: Chuyển hướng đến trang xác nhận đơn hàng hoặc trang chủ
              Navigator.pushReplacementNamed(context, '/payment_success');
              print(
                  "PagePayment: Order placed successfully. Navigating away...");
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    Navigator.pushReplacementNamed(context, '/payment_success');
  }

  void _showAddressSelectionDialog() {
    print("PagePayment: Opening Address Selector Dialog...");

    // Check login status from UserInfo
    bool isLoggedIn = UserInfo().isLoggedIn;

    if (!isLoggedIn) {
      // User is logged in, show the normal address selector
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: AddressSelector(
              // Pass data and callbacks to AddressSelector
              addresses: _addresses,
              selectedAddress: _currentAddress,
              isLoggedIn: true, // Always true in this branch
              onAddressSelected: (selectedAddress) {
                _updateSelectedAddress(selectedAddress);
                Navigator.of(dialogContext)
                    .pop(); // Close dialog after selection
              },
              onAddNewAddress: (newAddressData) {
                // Process new address directly in PagePayment
                _addNewAddressToList(newAddressData);
              },
              onUpdateAddress: (index, updatedAddressData) {
                // Process address update directly in PagePayment
                _updateExistingAddress(index, updatedAddressData);
              },
              onDeleteAddress: (index) {
                // Process address deletion in PagePayment
                _deleteAddress(index);
              },
              onSetDefaultAddress: (index) {
                _setAddressAsDefault(index);
              },
            ),
          );
        },
      ).then((_) => print("PagePayment: Address Selector Dialog closed."));
    } else {}
  }

  void _showVoucherSelectionDialog() {
    print("PagePayment: Opening Voucher Selector Dialog...");
    // Lọc voucher hợp lệ (ví dụ: còn hạn, đủ điều kiện tối thiểu - có thể lọc trước)
    final applicableVouchers = _availableVouchers
        .where((v) => v.expiryDate.isAfter(DateTime.now()))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: VoucherSelector(
            // Truyền dữ liệu và callbacks xuống VoucherSelector
            availableVouchers: applicableVouchers, // Chỉ truyền voucher hợp lệ
            currentVoucher: _currentVoucher,
            onVoucherSelected: (selectedVoucher) {
              // PagePayment nhận voucher được chọn từ dialog
              _updateSelectedVoucher(selectedVoucher);
              Navigator.of(dialogContext).pop(); // Đóng dialog
            },
            // Có thể thêm callback onApplyCode nếu muốn xử lý mã nhập tay từ dialog ở đây
            // onApplyCode: (code) {
            //   _validateAndApplyVoucher(code);
            // }
          ),
        );
      },
    ).then((_) => print("PagePayment: Voucher Selector Dialog closed."));
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán các giá trị cần thiết để truyền xuống BodyPayment
    final double subtotal = _calculateSubtotal();
    final double discount = _calculateDiscount();
    final double tax = _calculateTax();
    final double total = _calculateTotal();
    Widget appBar;

    // Create widget BodyPayment and pass the null-safe current address
    Widget body = BodyPayment(
      // --- Data ---
      currentAddress: _currentAddress, // Can be null now
      products: _products,
      currentVoucher: _currentVoucher,
      selectedPaymentMethod: _selectedPaymentMethod,
      subtotal: subtotal,
      shippingFee: _shippingFee,
      taxAmount: tax,
      taxRate: _taxRate,
      discountAmount: discount,
      totalAmount: total,
      isProcessingOrder: _isProcessing, // Trạng thái xử lý

      // --- Callbacks ---
      onChangeAddress:
          _showAddressSelectionDialog, // Callback mở dialog địa chỉ
      onSelectVoucher:
          _showVoucherSelectionDialog, // Callback mở dialog voucher
      onChangePaymentMethod:
          _updatePaymentMethod, // Callback thay đổi phương thức TT
      onPlaceOrder: _processPayment, // Callback đặt hàng
      formatCurrency: _formatCurrency, // Hàm định dạng tiền tệ
      onAddressSelected: _updateSelectedAddress, // Add this callback
    );

    // Layout Builder để chọn Navbar phù hợp
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFormobile(
            // Giả sử NavbarFixmobile là Scaffold chứa AppBar và body
            body: body,
            // title: 'Thanh toán', // Có thể thêm title cho AppBar
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
            // Giả sử NavbarFixTablet tương tự
            body: body,
            // title: 'Thanh toán',
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
  final String name;
  final String phone;
  final String address; // Địa chỉ chi tiết (số nhà, tên đường)
  final String province;
  final String district;
  final String ward;
  final bool isDefault;

  AddressData({
    required this.name,
    required this.phone,
    required this.address,
    required this.province,
    required this.district,
    required this.ward,
    this.isDefault = false,
  });

  String get fullAddress {
    // Tạo địa chỉ đầy đủ, loại bỏ phần tử rỗng
    final parts = [address, ward, district, province]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  // Thêm phương thức copyWith để dễ dàng cập nhật (ví dụ: thay đổi isDefault)
  AddressData copyWith({
    String? name,
    String? phone,
    String? address,
    String? province,
    String? district,
    String? ward,
    bool? isDefault,
  }) {
    return AddressData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Thêm == và hashCode để so sánh đối tượng (quan trọng khi dùng trong List, Set, Map)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          phone == other.phone &&
          address == other.address &&
          province == other.province &&
          district == other.district &&
          ward == other.ward &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
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
  final num discountAmount; // Có thể là int (tiền) hoặc double (phần trăm)
  final DateTime expiryDate;
  final bool isPercent;
  final double minSpend; // Thêm ngưỡng chi tiêu tối thiểu

  VoucherData({
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.expiryDate,
    this.isPercent = false,
    this.minSpend = 0.0, // Mặc định không có ngưỡng
  });

  // String get displayValue {
  //   final formatter = NumberFormat("#,###", "vi_VN");
  //   return isPercent ? '$discountAmount%' : '₫${formatter.format(discountAmount)}';
  // }

  // Cải thiện displayValue để hiển thị rõ ràng hơn
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

  // Thêm == và hashCode
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherData &&
          runtimeType == other.runtimeType &&
          code == other.code; // Thường mã voucher là duy nhất

  @override
  int get hashCode => code.hashCode;
}
