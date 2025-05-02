import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationSelection extends StatefulWidget {
  final Function(String, String, String) onLocationSelected;

  const LocationSelection({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _LocationSelectionState createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> wards = [];

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedWard;

  @override
  void initState() {
    super.initState();
    fetchProvinces();
  }

  Future<void> fetchProvinces() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/vietnam_locations.json');
      setState(() {
        provinces = json.decode(jsonString);
      });
    } catch (e) {
      print('Error loading provinces: $e');
    }
  }

  void updateDistricts(String provinceName) {
    final province = provinces.firstWhere(
      (p) => p['Name'] == provinceName,
      orElse: () => null,
    );

    if (province != null) {
      setState(() {
        districts = province['Districts'];
        wards = [];
        selectedDistrict = null;
        selectedWard = null;
      });
    }
  }

  void updateWards(String districtName) {
    final district = districts.firstWhere(
      (d) => d['Name'] == districtName,
      orElse: () => null,
    );

    if (district != null) {
      setState(() {
        wards = district['Wards'];
        selectedWard = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 600 ? 12.0 : 14.0;
    final verticalPadding = screenWidth < 600 ? 2.0 : 5.0;

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            style: TextStyle(fontSize: fontSize),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: verticalPadding),
              hintText: 'Tỉnh/Thành',
              border: OutlineInputBorder(),
              isDense: screenWidth < 600,
            ),
            value: selectedProvince,
            items: provinces.map<DropdownMenuItem<String>>((province) {
              return DropdownMenuItem<String>(
                value: province['Name'],
                child: Text(
                  province['Name'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedProvince = newValue;
              });
              if (newValue != null) {
                updateDistricts(newValue);
                widget.onLocationSelected(newValue, '', '');
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            style: TextStyle(fontSize: fontSize),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: verticalPadding),
              hintText: 'Quận/Huyện',
              border: OutlineInputBorder(),
              isDense: screenWidth < 600,
            ),
            value: selectedDistrict,
            items: districts.map<DropdownMenuItem<String>>((district) {
              return DropdownMenuItem<String>(
                value: district['Name'],
                child: Text(
                  district['Name'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize),
                ),
              );
            }).toList(),
            onChanged: selectedProvince == null
                ? null
                : (String? newValue) {
                    setState(() {
                      selectedDistrict = newValue;
                    });
                    if (newValue != null) {
                      updateWards(newValue);
                      widget.onLocationSelected(
                          selectedProvince!, newValue, '');
                    }
                  },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            style: TextStyle(fontSize: fontSize),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: verticalPadding),
              hintText: 'Phường/Xã',
              border: OutlineInputBorder(),
              isDense: screenWidth < 600,
            ),
            value: selectedWard,
            items: wards.map<DropdownMenuItem<String>>((ward) {
              return DropdownMenuItem<String>(
                value: ward['Name'],
                child: Text(
                  ward['Name'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize),
                ),
              );
            }).toList(),
            onChanged: selectedDistrict == null
                ? null
                : (String? newValue) {
                    setState(() {
                      selectedWard = newValue;
                    });
                    if (newValue != null) {
                      widget.onLocationSelected(
                          selectedProvince!, selectedDistrict!, newValue);
                    }
                  },
          ),
        ),
      ],
    );
  }
}
