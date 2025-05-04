// lib/widgets/location_selection.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Bỏ Provider imports


class LocationSelection extends StatefulWidget {
  // Callback vẫn nhận TÊN của tỉnh, huyện, xã
  final Function(String provinceName, String districtName, String wardName) onLocationSelected;
  // Initial values NÊN là TÊN để LocationSelection hiển thị đúng
  final String initialProvinceName; // Đổi tên tham số
  final String initialDistrictName; // Đổi tên tham số
  final String initialWardName;     // Đổi tên tham số

  const LocationSelection({
    Key? key,
    required this.onLocationSelected,
    this.initialProvinceName = '', // Initial values là TÊN
    this.initialDistrictName = '',
    this.initialWardName = '',
  }) : super(key: key);

  @override
  State<LocationSelection> createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> wards = [];

  // Các biến state nội bộ lưu trữ CODE của lựa chọn hiện tại
  String? selectedProvinceCode;
  String? selectedDistrictCode;
  String? selectedWardCode;

  bool isLoadingProvinces = true;
  bool isLoadingDistricts = false;
  bool isLoadingWards = false;

  @override
  void initState() {
    super.initState();
    // Fetch provinces first
    fetchProvinces().then((_) {
      // Sau khi provinces được fetch, thử tìm code cho initial name
      if (widget.initialProvinceName.isNotEmpty) {
        final initialProvince = provinces.firstWhere(
          (p) => p['name'] == widget.initialProvinceName,
          orElse: () => null, // Return null if not found
        );
        if (initialProvince != null) {
          final provinceCode = initialProvince['code'].toString();
          setState(() {
            selectedProvinceCode = provinceCode;
          });

          // Nếu có initial District Name, fetch districts
          if (widget.initialDistrictName.isNotEmpty) {
            fetchDistrictsForProvince(provinceCode).then((_) {
              // Sau khi districts được fetch, thử tìm code cho initial District Name
              final initialDistrict = districts.firstWhere(
                (d) => d['name'] == widget.initialDistrictName,
                 orElse: () => null,
              );
              if (initialDistrict != null) {
                 final districtCode = initialDistrict['code'].toString();
                 setState(() {
                    selectedDistrictCode = districtCode;
                 });

                 // Nếu có initial Ward Name, fetch wards
                 if (widget.initialWardName.isNotEmpty) {
                   fetchWardsForDistrict(districtCode).then((_) {
                     // Sau khi wards được fetch, thử tìm code cho initial Ward Name
                     final initialWard = wards.firstWhere(
                       (w) => w['name'] == widget.initialWardName,
                        orElse: () => null,
                     );
                     if (initialWard != null) {
                       final wardCode = initialWard['code'].toString();
                       setState(() {
                          selectedWardCode = wardCode;
                       });
                       // Sau khi tất cả initial codes được set, gọi callback với initial NAMES
                       // Chỉ gọi khi tìm thấy cả 3 cấp ban đầu
                       widget.onLocationSelected(
                           widget.initialProvinceName,
                           widget.initialDistrictName,
                           widget.initialWardName);
                     } else {
                        // Nếu không tìm thấy initial ward, gọi callback với các tên đã tìm thấy (hoặc rỗng)
                         widget.onLocationSelected(
                           widget.initialProvinceName,
                           widget.initialDistrictName,
                           '');
                     }
                   });
                 } else {
                    // Nếu không có initial ward name, gọi callback với các tên đã tìm thấy (hoặc rỗng)
                      widget.onLocationSelected(
                           widget.initialProvinceName,
                           widget.initialDistrictName,
                           '');
                 }
              } else {
                 // Nếu không tìm thấy initial district, gọi callback với tên tỉnh (hoặc rỗng)
                 widget.onLocationSelected(
                           widget.initialProvinceName,
                           '',
                           '');
              }
            });
          } else {
             // Nếu không có initial district/ward name, gọi callback với tên tỉnh (hoặc rỗng)
               widget.onLocationSelected(
                           widget.initialProvinceName,
                           '',
                           '');
          }
        } else {
           // Nếu không tìm thấy initial province name, gọi callback với rỗng
           widget.onLocationSelected('', '', '');
        }
      } else {
         // Nếu không có initial province name, gọi callback với rỗng ngay
         widget.onLocationSelected('', '', '');
      }
    });
  }

  // Helper function to find name by code
  String _findNameByCode(String code, List<dynamic> list) {
    try {
      final item = list.firstWhere((item) => item['code'].toString() == code);
      return item['name'] ?? '';
    } catch (e) {
      return ''; // Return empty string if code not found
    }
  }


  Future<void> fetchProvinces() async {
    setState(() {
      isLoadingProvinces = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/p/'),
        headers: {'Accept-Charset': 'UTF-8'},
      );

      if (response.statusCode == 200) {
        final decodedData = utf8.decode(response.bodyBytes);
        setState(() {
          provinces = json.decode(decodedData);
          isLoadingProvinces = false;
        });
      } else {
        setState(() {
          isLoadingProvinces = false;
        });
        print('Failed to load provinces: ${response.statusCode}');
        // Consider showing an error to the user
      }
    } catch (e) {
      setState(() {
        isLoadingProvinces = false;
      });
      print('Exception when fetching provinces: $e');
      // Consider showing an error to the user
    }
  }

  Future<void> fetchDistrictsForProvince(String provinceCode) async {
    if (provinceCode.isEmpty) return;

    setState(() {
      isLoadingDistricts = true;
      districts = [];
      selectedDistrictCode = null; // Reset selected district code
      selectedWardCode = null;     // Reset selected ward code
      wards = [];
    });

    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/p/$provinceCode?depth=2'),
        headers: {'Accept-Charset': 'UTF-8'},
      );

      if (response.statusCode == 200) {
        final decodedData = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedData);
        setState(() {
          districts = data['districts'] ?? [];
          isLoadingDistricts = false;
        });
      } else {
        setState(() {
          isLoadingDistricts = false;
        });
        print('Failed to load districts: ${response.statusCode}');
         // Consider showing an error to the user
      }
    } catch (e) {
      setState(() {
        isLoadingDistricts = false;
      });
      print('Exception when fetching districts: $e');
       // Consider showing an error to the user
    }
  }

  Future<void> fetchWardsForDistrict(String districtCode) async {
    if (districtCode.isEmpty) return;

    setState(() {
      isLoadingWards = true;
      wards = [];
      selectedWardCode = null; // Reset selected ward code
    });

    try {
      final response = await http.get(
        Uri.parse('https://provinces.open-api.vn/api/d/$districtCode?depth=2'),
        headers: {'Accept-Charset': 'UTF-8'},
      );

      if (response.statusCode == 200) {
        final decodedData = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedData);
        setState(() {
          wards = data['wards'] ?? [];
          isLoadingWards = false;
        });
      } else {
        setState(() {
          isLoadingWards = false;
        });
        print('Failed to load wards: ${response.statusCode}');
         // Consider showing an error to the user
      }
    } catch (e) {
      setState(() {
        isLoadingWards = false;
      });
      print('Exception when fetching wards: $e');
       // Consider showing an error to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng IntrinsicHeight có thể gây vấn đề hiệu năng, cân nhắc Column + Expanded nếu cần
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Province Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                // REMOVED labelText: 'Tỉnh/TP',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
              // Value của Dropdown là CODE đã lưu
              value: selectedProvinceCode,
              icon: isLoadingProvinces
                  ? const SizedBox( // Show loading indicator
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              items: provinces.map<DropdownMenuItem<String>>((province) {
                 // items map từ list province (đã chứa code và name)
                String name = province['name'] ?? '';
                String code = province['code'].toString();
                return DropdownMenuItem<String>(
                  value: code, // Value là CODE
                  child: Text(
                    name, // Hiển thị TÊN
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: isLoadingProvinces ? null : (value) { // Disable if loading
                if (value != null) {
                  // Tìm TÊN từ CODE vừa chọn
                  final selectedProvinceName = _findNameByCode(value, provinces);
                  setState(() {
                    selectedProvinceCode = value; // Lưu CODE
                    selectedDistrictCode = null; // Reset selected district
                    selectedWardCode = null;     // Reset selected ward
                    districts = []; // Clear districts
                    wards = []; // Clear wards
                  });
                  fetchDistrictsForProvince(value); // Fetch dùng CODE
                  // Gọi callback với TÊN TỈNH đã tìm được, và các cấp dưới là rỗng
                  widget.onLocationSelected(selectedProvinceName, '', '');
                }
              },
              dropdownColor: Colors.white,
              // Thêm hintText khi chưa có giá trị
              hint: isLoadingProvinces ? const Text('Đang tải...') : const Text('Chọn Tỉnh/TP'),
            ),
          ),
          const SizedBox(width: 8),

          // District Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                 // REMOVED labelText: 'Quận/Huyện',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
               // Value của Dropdown là CODE đã lưu
              value: selectedDistrictCode,
               icon: isLoadingDistricts
                  ? const SizedBox( // Show loading indicator
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              items: districts.map<DropdownMenuItem<String>>((district) {
                String name = district['name'] ?? '';
                String code = district['code'].toString();
                return DropdownMenuItem<String>(
                  value: code, // Value là CODE
                  child: Text(
                    name, // Hiển thị TÊN
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              // Disable nếu chưa chọn tỉnh hoặc đang tải huyện
              onChanged: selectedProvinceCode == null || isLoadingDistricts ? null : (value) {
                      if (value != null) {
                        // Tìm TÊN huyện từ CODE vừa chọn
                        final selectedDistrictName = _findNameByCode(value, districts);
                        // Tìm TÊN Tỉnh từ CODE tỉnh đang lưu (lấy từ state)
                        final currentProvinceName = _findNameByCode(selectedProvinceCode!, provinces);
                        setState(() {
                          selectedDistrictCode = value; // Lưu CODE
                          selectedWardCode = null;     // Reset selected ward
                          wards = []; // Clear wards
                        });
                        fetchWardsForDistrict(value); // Fetch dùng CODE
                         // Gọi callback với TÊN TỈNH, TÊN HUYỆN đã tìm được, và xã là rỗng
                        widget.onLocationSelected(
                            currentProvinceName, selectedDistrictName, '');
                      }
                    },
              dropdownColor: Colors.white,
              // Thêm hintText
               hint: isLoadingDistricts ? const Text('Đang tải...') : const Text('Chọn Quận/Huyện'),
            ),
          ),
          const SizedBox(width: 8),

          // Ward Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                 // REMOVED labelText: 'Phường/Xã',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
              // Value của Dropdown là CODE đã lưu
              value: selectedWardCode,
               icon: isLoadingWards
                  ? const SizedBox( // Show loading indicator
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              items: wards.map<DropdownMenuItem<String>>((ward) {
                String name = ward['name'] ?? '';
                String code = ward['code'].toString();
                return DropdownMenuItem<String>(
                  value: code, // Value là CODE
                  child: Text(
                    name, // Hiển thị TÊN
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
               // Disable nếu chưa chọn huyện hoặc đang tải xã
              onChanged: selectedDistrictCode == null || isLoadingWards ? null : (value) {
                      if (value != null) {
                        // Tìm TÊN xã từ CODE vừa chọn
                        final selectedWardName = _findNameByCode(value, wards);
                         // Tìm TÊN Tỉnh từ CODE tỉnh đang lưu (lấy từ state)
                        final currentProvinceName = _findNameByCode(selectedProvinceCode!, provinces);
                        // Tìm TÊN Huyện từ CODE huyện đang lưu (lấy từ state)
                        final currentDistrictName = _findNameByCode(selectedDistrictCode!, districts);
                        setState(() {
                          selectedWardCode = value; // Lưu CODE
                        });
                        // Gọi callback với TÊN TỈNH, TÊN HUYỆN, TÊN XÃ đã tìm được
                        widget.onLocationSelected(currentProvinceName,
                            currentDistrictName, selectedWardName);
                      }
                    },
              dropdownColor: Colors.white,
               // Thêm hintText
               hint: isLoadingWards ? const Text('Đang tải...') : const Text('Chọn Phường/Xã'),
            ),
          ),
        ],
      ),
    );
  }
}
