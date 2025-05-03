import 'package:flutter/material.dart';
import '../signup/base_state_provider.dart';

class LocationStateProvider extends BaseStateProvider {
  // Keys for state values
  static const String provinceKey = 'selectedProvince';
  static const String districtKey = 'selectedDistrict';
  static const String wardKey = 'selectedWard';
  static const String provincesKey = 'provinces';
  static const String districtsKey = 'districts';
  static const String wardsKey = 'wards';

  // Initialize state
  LocationStateProvider() {
    setMultipleStates({
      provinceKey: '',
      districtKey: '',
      wardKey: '',
      provincesKey: <Map<String, dynamic>>[],
      districtsKey: <Map<String, dynamic>>[],
      wardsKey: <Map<String, dynamic>>[],
    });
  }

  // Getters
  String get selectedProvince => getState<String>(provinceKey) ?? '';
  String get selectedDistrict => getState<String>(districtKey) ?? '';
  String get selectedWard => getState<String>(wardKey) ?? '';
  List<Map<String, dynamic>> get provinces =>
      getState<List<Map<String, dynamic>>>(provincesKey) ?? [];
  List<Map<String, dynamic>> get districts =>
      getState<List<Map<String, dynamic>>>(districtsKey) ?? [];
  List<Map<String, dynamic>> get wards =>
      getState<List<Map<String, dynamic>>>(wardsKey) ?? [];

  // Setters
  void setProvinces(List<Map<String, dynamic>> data) {
    setState(provincesKey, data);
  }

  void setDistricts(List<Map<String, dynamic>> data) {
    setState(districtsKey, data);
  }

  void setWards(List<Map<String, dynamic>> data) {
    setState(wardsKey, data);
  }

  void selectProvince(String province) {
    setMultipleStates({
      provinceKey: province,
      districtKey: '',
      wardKey: '',
    });
  }

  void selectDistrict(String district) {
    setMultipleStates({
      districtKey: district,
      wardKey: '',
    });
  }

  void selectWard(String ward) {
    setState(wardKey, ward);
  }

  // Clear selections
  void clearSelections() {
    setMultipleStates({
      provinceKey: '',
      districtKey: '',
      wardKey: '',
    });
  }

  // Export location data
  Map<String, String> exportLocationData() {
    return {
      'province': selectedProvince,
      'district': selectedDistrict,
      'ward': selectedWard,
    };
  }

  // Import location data
  void importLocationData(Map<String, String> data) {
    setMultipleStates({
      provinceKey: data['province'] ?? '',
      districtKey: data['district'] ?? '',
      wardKey: data['ward'] ?? '',
    });
  }

  // Check if location is complete
  bool isLocationComplete() {
    return selectedProvince.isNotEmpty &&
        selectedDistrict.isNotEmpty &&
        selectedWard.isNotEmpty;
  }
}
