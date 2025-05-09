import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/database/models/coupon_dto.dart';
import 'package:e_commerce_app/database/services/coupon_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoucherSelector extends StatefulWidget {
  final VoucherData? currentVoucher;
  final Function(VoucherData?) onVoucherSelected;

  const VoucherSelector({
    Key? key,
    required this.currentVoucher,
    required this.onVoucherSelected,
  }) : super(key: key);

  @override
  State<VoucherSelector> createState() => _VoucherSelectorState();
}

class _VoucherSelectorState extends State<VoucherSelector> {
  final TextEditingController _codeController = TextEditingController();
  VoucherData? _selectedVoucherInDialog;
  String? _errorMessage;

  final NumberFormat _currencyFormatter = NumberFormat("#,###", "vi_VN");

  late CouponService _couponService;
  List<VoucherData> _internalVoucherList = [];
  bool _isLoadingCoupons = true;
  String? _fetchCouponsError;

  @override
  void initState() {
    super.initState();
    _couponService = CouponService();
    _fetchAndMapCoupons();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _couponService.dispose();
    super.dispose();
  }

  void _applyEnteredCode() {
    final code = _codeController.text.trim().toUpperCase();
    setState(() {
      _errorMessage = null;
    });

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã voucher');
      return;
    }

    try {
      final voucher = _internalVoucherList.firstWhere(
        (v) => v.code.toUpperCase() == code,
      );

      setState(() {
        _selectedVoucherInDialog = voucher;
        _errorMessage = null;
        if (kDebugMode) {
          print(
              "VoucherSelector: Code '$code' applied successfully, selected voucher: ${voucher.code}");
        }
        FocusScope.of(context).unfocus();
        _codeController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Mã không hợp lệ hoặc không áp dụng được.';
        if (kDebugMode) {
          print(
              "VoucherSelector: Code '$code' not found in _internalVoucherList.");
        }
      });
    }
  }

  void _toggleVoucherSelection(VoucherData voucher) {
    setState(() {
      if (_selectedVoucherInDialog == voucher) {
        _selectedVoucherInDialog = null;
        if (kDebugMode) {
          print("VoucherSelector: Deselected voucher: ${voucher.code}");
        }
      } else {
        _selectedVoucherInDialog = voucher;
        if (kDebugMode) {
          print("VoucherSelector: Selected voucher from list: ${voucher.code}");
        }
      }
      _errorMessage = null;
    });
  }

  void _confirmSelection() {
    if (kDebugMode) {
      print(
          "VoucherSelector: Confirming selection: ${_selectedVoucherInDialog?.code}");
    }
    widget.onVoucherSelected(_selectedVoucherInDialog);
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
          "VoucherSelector build: Selected voucher in dialog: ${_selectedVoucherInDialog?.code}");
    }
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 550,
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildCodeInputRow(),
          if (_errorMessage != null)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          Expanded(
            child: _buildVoucherList(),
          ),
          const Divider(height: 1),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Chọn Shop Voucher',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey),
            tooltip: 'Đóng',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInputRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Nhập mã Shop Voucher',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.5),
                ),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _applyEnteredCode(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _applyEnteredCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 1,
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    if (_isLoadingCoupons) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fetchCouponsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _fetchCouponsError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 15),
          ),
        ),
      );
    }

    if (_internalVoucherList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Không có voucher nào khả dụng cho bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _internalVoucherList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemBuilder: (context, index) {
        final voucher = _internalVoucherList[index];
        final isSelected = _selectedVoucherInDialog == voucher;
        return _buildVoucherItem(voucher, isSelected);
      },
    );
  }

  Widget _buildVoucherItem(VoucherData voucher, bool isSelected) {
    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: isSelected ? Colors.red.shade400 : Colors.grey.shade200,
          width: isSelected ? 1.5 : 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleVoucherSelection(voucher),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      voucher.isPercent ? Icons.percent : Icons.local_offer,
                      color: Colors.red.shade600,
                      size: 30,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      voucher.displayDiscount(_currencyFormatter),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.description,
                        style: TextStyle(
                            fontSize: 13.5, color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (voucher.remainingUses != null)
                        Text(
                          'Lượt dùng còn lại: ${voucher.remainingUses}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (voucher.displayCondition().isNotEmpty)
                            Text(
                              voucher.displayCondition(),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Radio<VoucherData?>(
                value: voucher,
                groupValue: _selectedVoucherInDialog,
                activeColor: Colors.red,
                onChanged: (VoucherData? value) {
                  if (value != null) {
                    _toggleVoucherSelection(value);
                  }
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        onPressed: _confirmSelection,
        child: const Text(
          'Xác nhận',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndMapCoupons() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCoupons = true;
      _fetchCouponsError = null;
    });

    try {
      final List<CouponResponseDTO> couponDTOs =
          await _couponService.getAvailableCoupons();
      if (!mounted) return;

      List<VoucherData> mappedVouchers = couponDTOs.map((dto) {
        String descriptionText = (dto.discountType == "PERCENTAGE"
            ? 'Giảm ${dto.discountValue}%'
            : 'Giảm ${_currencyFormatter.format(dto.discountValue)}₫');

        if (dto.minOrderValue != null && dto.minOrderValue! > 0) {
          descriptionText +=
              ' cho đơn từ ${_currencyFormatter.format(dto.minOrderValue)}₫';
        }

        String finalDescription = dto.description?.isNotEmpty == true
            ? "${dto.description!} ($descriptionText)"
            : descriptionText;

        return VoucherData(
          code: dto.code,
          description: finalDescription,
          discountAmount: dto.discountValue,
          expiryDate: dto.endDate?.toLocal() ??
              DateTime.now().add(const Duration(days: 365 * 2)),
          isPercent: dto.discountType == "PERCENTAGE",
          minSpend: dto.minOrderValue ?? 0.0,
          remainingUses: dto.maxUsageCount - dto.usageCount,
        );
      }).toList();

      final now = DateTime.now();
      mappedVouchers = mappedVouchers.where((voucher) {
        CouponResponseDTO? originalDto;
        try {
          originalDto =
              couponDTOs.firstWhere((dto) => dto.code == voucher.code);
        } catch (e) {
          originalDto = null; // Set to null if not found
          if (kDebugMode) {
            print(
                "VoucherSelector: Original DTO for voucher code ${voucher.code} not found. Error: $e");
          }
        }

        bool hasStarted = true;
        if (originalDto?.startDate != null) {
          hasStarted = !originalDto!.startDate!.toLocal().isAfter(now);
        }

        final bool isExpired = voucher.expiryDate.isBefore(now);
        final bool noUsesLeft =
            voucher.remainingUses != null && voucher.remainingUses! <= 0;

        return hasStarted && !isExpired && !noUsesLeft;
      }).toList();

      mappedVouchers.sort((a, b) {
        final int usesA = a.remainingUses ?? 0;
        final int usesB = b.remainingUses ?? 0;
        int comparison = usesB.compareTo(usesA);
        if (comparison == 0) {
          comparison = a.expiryDate.compareTo(b.expiryDate);
        }
        return comparison;
      });

      if (!mounted) return;
      setState(() {
        _internalVoucherList = mappedVouchers;

        if (widget.currentVoucher != null) {
          try {
            _selectedVoucherInDialog = _internalVoucherList
                .firstWhere((v) => v.code == widget.currentVoucher!.code);
          } catch (e) {
            _selectedVoucherInDialog = null;
            if (kDebugMode) {
              print(
                  "VoucherSelector: Current voucher ${widget.currentVoucher!.code} not found in fetched list.");
            }
          }
        } else {
          _selectedVoucherInDialog = null;
        }
        if (kDebugMode) {
          print(
              "VoucherSelector initState: Initial selected voucher after fetch: ${_selectedVoucherInDialog?.code}");
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        print('Error fetching or mapping coupons: $e');
      }
      setState(() {
        _fetchCouponsError = 'Lỗi tải voucher: ${e.toString()}';
        _internalVoucherList = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCoupons = false;
        });
      }
    }
  }
}

Future<void> showVoucherSelectorDialog(
  BuildContext context, {
  required VoucherData? currentVoucher,
  required Function(VoucherData?) onVoucherSelected,
}) async {
  if (kDebugMode) {
    print("PagePayment (caller): Opening VoucherSelector Dialog...");
  }
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: VoucherSelector(
          currentVoucher: currentVoucher,
          onVoucherSelected: onVoucherSelected,
        ),
      );
    },
  ).then((_) {
    if (kDebugMode) {
      print("PagePayment (caller): Voucher Selector Dialog closed.");
    }
  });
}
