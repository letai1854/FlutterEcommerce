import 'package:e_commerce_app/Screens/Admin/discount/AddDiscountScreen.dart';
import 'package:e_commerce_app/database/models/coupon_dto.dart';
import 'package:e_commerce_app/database/services/coupon_service.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({Key? key}) : super(key: key);

  @override
  _DiscountScreenState createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final CouponService _couponService = CouponService();
  List<CouponResponseDTO> _coupons = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _requiresLogin = false;

  @override
  void initState() {
    super.initState();
    UserInfo().addListener(_onAuthStateChanged);
    _checkAuthAndFetch();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      _checkAuthAndFetch();
    }
  }

  void _checkAuthAndFetch() {
    if (!UserInfo().isLoggedIn) {
      setState(() {
        _isLoading = false;
        _requiresLogin = true;
        _coupons = [];
        _errorMessage = null;
      });
    } else {
      setState(() {
        _requiresLogin = false;
      });
      if (!_isLoading || _coupons.isEmpty) {
        _fetchCoupons();
      }
    }
  }

  Future<void> _fetchCoupons() async {
    if (!UserInfo().isLoggedIn) {
      setState(() {
        _isLoading = false;
        _requiresLogin = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _requiresLogin = false;
    });
    try {
      final coupons = await _couponService.getCoupons();
      if (mounted) {
        setState(() {
          _coupons = coupons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('401') || e.toString().contains('403')) {
            _requiresLogin = true;
            _errorMessage = null;
          } else {
            _errorMessage = e.toString();
          }
          _isLoading = false;
        });
      }
      print('Error fetching coupons: $e');
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  void _showCouponDetailsDialog(CouponResponseDTO coupon) {
    final remainingUses = coupon.maxUsageCount - coupon.usageCount;
    
    // Kiểm tra nếu đang chạy trên web
    if (kIsWeb) {
      // Sử dụng Dialog tùy chỉnh cho web
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            // Giới hạn kích thước dialog
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Chi tiết mã: ${coupon.code}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Divider(),
                    
                    // Nội dung
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRowDialog(
                                'Giá trị giảm:', _formatCurrency(coupon.discountValue)),
                            if (coupon.createdDate != null)
                              _buildDetailRowDialog(
                                  'Ngày tạo:',
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(coupon.createdDate!)),
                            _buildDetailRowDialog(
                                'Số lần sử dụng tối đa:', '${coupon.maxUsageCount}'),
                            _buildDetailRowDialog(
                                'Số lần đã sử dụng:', '${coupon.usageCount}'),
                            _buildDetailRowDialog(
                                'Số lần sử dụng còn lại:', '$remainingUses',
                                isHighlighted: true),
                            const SizedBox(height: 12),
                            const Text(
                              'Đơn hàng đã áp dụng:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Divider(),
                            
                            // Danh sách đơn hàng - sử dụng Column thay vì ListView.builder
                            if (coupon.orders == null || coupon.orders!.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text('Chưa có đơn hàng nào áp dụng mã này.'),
                              )
                            else
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: coupon.orders!.map((order) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.receipt_long,
                                        color: Colors.teal, size: 20),
                                    title: Text('Mã đơn hàng: ${order.orderId}'),
                                    subtitle: Text(
                                        'Giá trị đơn: ${_formatCurrency(order.orderValue)}'),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Nút đóng
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: const Text('Đóng'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Sử dụng AlertDialog gốc cho mobile và desktop
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Chi tiết mã: ${coupon.code}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  _buildDetailRowDialog(
                      'Giá trị giảm:', _formatCurrency(coupon.discountValue)),
                  if (coupon.createdDate != null)
                    _buildDetailRowDialog(
                        'Ngày tạo:',
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(coupon.createdDate!)),
                  _buildDetailRowDialog(
                      'Số lần sử dụng tối đa:', '${coupon.maxUsageCount}'),
                  _buildDetailRowDialog(
                      'Số lần đã sử dụng:', '${coupon.usageCount}'),
                  _buildDetailRowDialog(
                      'Số lần sử dụng còn lại:', '$remainingUses',
                      isHighlighted: true),
                  const SizedBox(height: 12),
                  const Text(
                    'Đơn hàng đã áp dụng:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Divider(),
                  if (coupon.orders == null || coupon.orders!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Chưa có đơn hàng nào áp dụng mã này.'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: coupon.orders!.length,
                      itemBuilder: (context, orderIndex) {
                        final order = coupon.orders![orderIndex];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.receipt_long,
                              color: Colors.teal, size: 20),
                          title: Text('Mã đơn hàng: ${order.orderId}'),
                          subtitle: Text(
                              'Giá trị đơn: ${_formatCurrency(order.orderValue)}'),
                        );
                      },
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildDetailRowDialog(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: const Text('Quản lý Mã giảm giá'),
        actions: [
          TextButton(
            onPressed: () async {
              if (!UserInfo().isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng đăng nhập để thêm mã giảm giá.')),
                );
                Navigator.pushNamed(context, '/login').then((_) {
                  _checkAuthAndFetch();
                });
                return;
              }
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddDiscountScreen()),
              );
              if (result == true && UserInfo().isLoggedIn) {
                _fetchCoupons();
              }
            },
            child: Text(
              'Thêm',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requiresLogin
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 20),
                        const Text(
                          'Vui lòng đăng nhập để quản lý mã giảm giá.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/login').then((_) {
                              _checkAuthAndFetch();
                            });
                          },
                          child: const Text('Đăng nhập',
                              style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 50),
                            const SizedBox(height: 10),
                            Text(
                              'Không có kết nối internet',
                              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                                onPressed: _fetchCoupons,
                                child: const Text('Thử lại'))
                          ],
                        ),
                      ),
                    )
                  : _coupons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer_outlined,
                                  size: 50, color: Colors.grey[500]),
                              const SizedBox(height: 10),
                              const Text('Không tìm thấy mã giảm giá nào.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _coupons.length,
                          itemBuilder: (context, index) {
                            final coupon = _coupons[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.local_offer,
                                      color: Theme.of(context).primaryColor),
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                ),
                                title: Text(
                                  coupon.code,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                    'Giá trị: ${_formatCurrency(coupon.discountValue)}. SL còn lại: ${coupon.maxUsageCount - coupon.usageCount}'),
                                trailing: const Icon(Icons.info_outline,
                                    color: Colors.blueGrey),
                                onTap: () {
                                  _showCouponDetailsDialog(coupon);
                                },
                              ),
                            );
                          },
                        ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    UserInfo().removeListener(_onAuthStateChanged);
    _couponService.dispose();
    super.dispose();
  }
}
