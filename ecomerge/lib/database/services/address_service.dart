import 'dart:convert';
import 'dart:io';

import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:e_commerce_app/database/models/address_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class AddressService {
  final String baseUrl = baseurl;
  late final http.Client httpClient;

  // Constructor - setup SSL-bypassing client for all platforms
  AddressService() {
    httpClient = _createSecureClient();
  }

  // Create a client that bypasses SSL certificate verification
  http.Client _createSecureClient() {
    if (kIsWeb) {
      // Web platform doesn't need special handling
      return http.Client();
    } else {
      // For mobile and desktop platforms
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  // Get auth headers
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final authToken = UserInfo().authToken;
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }

    return headers;
  }

  // Get all addresses for the current user
  Future<List<Address>> getUserAddresses() async {
    final url = Uri.parse('$baseUrl/api/addresses/me');

    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> addressData = json.decode(response.body);
        return addressData.map((data) => Address.fromJson(data)).toList();
      } else if (response.statusCode == 204) {
        // No content - user has no addresses
        return [];
      } else {
        print('Failed to fetch addresses: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching addresses: $e');
      return [];
    }
  }

  // Add a new address for the current user
  Future<Address?> addAddress(AddressRequest addressRequest) async {
    final url = Uri.parse('$baseUrl/api/addresses/me');

    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: json.encode(addressRequest.toJson()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Address.fromJson(responseData);
      } else {
        print('Failed to add address: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding address: $e');
      return null;
    }
  }

  // Update an existing address
  Future<Address?> updateAddress(
      int addressId, AddressRequest addressRequest) async {
    final url = Uri.parse('$baseUrl/api/addresses/me/$addressId');

    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(),
        body: json.encode(addressRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Address.fromJson(responseData);
      } else {
        print('Failed to update address: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating address: $e');
      return null;
    }
  }

  // Delete an address
  Future<bool> deleteAddress(int addressId) async {
    final url = Uri.parse('$baseUrl/api/addresses/me/$addressId');

    try {
      final response = await httpClient.delete(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to delete address: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // Set an address as default with special handling for null addresses
  Future<bool> setDefaultAddress(int addressId) async {
    try {
      // First, check for any "null" default addresses
      final addresses = await getUserAddresses();
      final nullDefaultAddress = addresses.firstWhere(
        (address) => address.specificAddress == "null" && address.isDefault,
        orElse: () => null as Address,
      );

      // If found, remove the null default address
      if (nullDefaultAddress != null && nullDefaultAddress.id != null) {
        await deleteAddress(nullDefaultAddress.id!);
        print('Removed "null" default address before setting new default');
      }

      // Now set the new default address
      final url = Uri.parse('$baseUrl/api/addresses/me/$addressId/default');
      final response = await httpClient.patch(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to set default address: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }
}
