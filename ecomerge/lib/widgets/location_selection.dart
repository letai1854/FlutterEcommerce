import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:e_commerce_app/providers/signup_form_provider.dart';

class LocationSelection extends StatefulWidget {
  final Function(String, String, String) onLocationSelected;
  final String initialProvince;
  final String initialDistrict;
  final String initialWard;

  const LocationSelection({
    Key? key,
    required this.onLocationSelected,
    this.initialProvince = '',
    this.initialDistrict = '',
    this.initialWard = '',
  }) : super(key: key);

  @override
  State<LocationSelection> createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> wards = [];

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedWard;

  bool isLoadingProvinces = true;
  bool isLoadingDistricts = false;
  bool isLoadingWards = false;

  @override
  void initState() {
    super.initState();
    fetchProvinces().then((_) {
      if (widget.initialProvince.isNotEmpty) {
        setState(() {
          selectedProvince = widget.initialProvince;
        });

        if (widget.initialDistrict.isNotEmpty) {
          fetchDistrictsForProvince(widget.initialProvince).then((_) {
            setState(() {
              selectedDistrict = widget.initialDistrict;
            });

            if (widget.initialWard.isNotEmpty) {
              fetchWardsForDistrict(widget.initialDistrict).then((_) {
                setState(() {
                  selectedWard = widget.initialWard;
                });
                widget.onLocationSelected(selectedProvince ?? '',
                    selectedDistrict ?? '', selectedWard ?? '');
              });
            }
          });
        }
      }
    });
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
      }
    } catch (e) {
      setState(() {
        isLoadingProvinces = false;
      });
      print('Exception when fetching provinces: $e');
    }
  }

  Future<void> fetchDistrictsForProvince(String provinceCode) async {
    if (provinceCode.isEmpty) return;

    setState(() {
      isLoadingDistricts = true;
      districts = [];
      selectedDistrict = null;
      selectedWard = null;
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
      }
    } catch (e) {
      setState(() {
        isLoadingDistricts = false;
      });
      print('Exception when fetching districts: $e');
    }
  }

  Future<void> fetchWardsForDistrict(String districtCode) async {
    if (districtCode.isEmpty) return;

    setState(() {
      isLoadingWards = true;
      wards = [];
      selectedWard = null;
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
      }
    } catch (e) {
      setState(() {
        isLoadingWards = false;
      });
      print('Exception when fetching wards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Province Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tỉnh/TP',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
              value: selectedProvince,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              items: provinces.map((province) {
                String name = province['name'] ?? '';
                return DropdownMenuItem<String>(
                  value: province['code'].toString(),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedProvince = value;
                    selectedDistrict = null;
                    selectedWard = null;
                  });
                  fetchDistrictsForProvince(value);
                  widget.onLocationSelected(value, '', '');
                }
              },
              dropdownColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),

          // District Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Quận/Huyện',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
              value: selectedDistrict,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              items: districts.map((district) {
                String name = district['name'] ?? '';
                return DropdownMenuItem<String>(
                  value: district['code'].toString(),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: selectedProvince == null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedDistrict = value;
                          selectedWard = null;
                        });
                        fetchWardsForDistrict(value);
                        widget.onLocationSelected(
                            selectedProvince ?? '', value, '');
                      }
                    },
              dropdownColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),

          // Ward Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Phường/Xã',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
              value: selectedWard,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              items: wards.map((ward) {
                String name = ward['name'] ?? '';
                return DropdownMenuItem<String>(
                  value: ward['code'].toString(),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: selectedDistrict == null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedWard = value;
                        });
                        widget.onLocationSelected(selectedProvince ?? '',
                            selectedDistrict ?? '', value);
                      }
                    },
              dropdownColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
