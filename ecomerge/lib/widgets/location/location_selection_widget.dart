import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_commerce_app/State/location/location_state_provider.dart';
import 'package:e_commerce_app/State/core/state_widget.dart';

class LocationSelectionWidget extends StatefulWidget {
  final void Function(String, String, String)? onLocationSelected;

  const LocationSelectionWidget({
    Key? key,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSelectionWidget> createState() =>
      _LocationSelectionWidgetState();
}

class _LocationSelectionWidgetState extends State<LocationSelectionWidget> {
  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      // Use ByteData and explicit UTF-8 decoding for proper character handling
      final ByteData data =
          await rootBundle.load('assets/vietnam_locations.json');
      final List<int> bytes = data.buffer.asUint8List();
      final String jsonContent = utf8.decode(bytes);

      // Parse JSON
      final List<dynamic> locations = json.decode(jsonContent);

      // Convert to required format
      final List<Map<String, dynamic>> provinces =
          List<Map<String, dynamic>>.from(locations);

      if (!mounted) return;
      context.readState<LocationStateProvider>().setProvinces(provinces);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  Widget _buildDropdown({
    required String value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            hint: Text(
              hint,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              border: OutlineInputBorder(),
            ),
            items: items.map((item) {
              final name = item['Name']?.toString() ?? '';
              return DropdownMenuItem(
                value: name,
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled ? Colors.black87 : Colors.grey[600],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StateWidget<LocationStateProvider>(
      state: LocationStateProvider(),
      child: Builder(
        builder: (context) {
          final state = context.watchState<LocationStateProvider>();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(
                value: state.selectedProvince,
                hint: 'Tỉnh/Thành phố',
                items: state.provinces,
                onChanged: (value) {
                  if (value == null) return;
                  final provinceData = state.provinces.firstWhere(
                    (province) => province['Name'] == value,
                  );
                  state.selectProvince(value);
                  state.setDistricts(
                    List<Map<String, dynamic>>.from(
                      provinceData['Districts'] as List,
                    ),
                  );
                  if (widget.onLocationSelected != null) {
                    widget.onLocationSelected!(value, '', '');
                  }
                },
              ),
              _buildDropdown(
                value: state.selectedDistrict,
                hint: 'Quận/Huyện',
                items: state.districts,
                onChanged: (value) {
                  if (value == null) return;
                  final districtData = state.districts.firstWhere(
                    (district) => district['Name'] == value,
                  );
                  state.selectDistrict(value);
                  state.setWards(
                    List<Map<String, dynamic>>.from(
                      districtData['Wards'] as List,
                    ),
                  );
                  if (widget.onLocationSelected != null) {
                    widget.onLocationSelected!(
                      state.selectedProvince,
                      value,
                      '',
                    );
                  }
                },
                enabled: state.selectedProvince.isNotEmpty,
              ),
              _buildDropdown(
                value: state.selectedWard,
                hint: 'Phường/Xã',
                items: state.wards,
                onChanged: (value) {
                  if (value == null) return;
                  state.selectWard(value);
                  if (widget.onLocationSelected != null) {
                    widget.onLocationSelected!(
                      state.selectedProvince,
                      state.selectedDistrict,
                      value,
                    );
                  }
                },
                enabled: state.selectedDistrict.isNotEmpty,
              ),
            ],
          );
        },
      ),
    );
  }
}
