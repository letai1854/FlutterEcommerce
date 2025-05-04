import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/io_client.dart';
import 'dart:io';

final String baseurl =
    kIsWeb ? 'https://localhost:8443' : 'https://10.0.2.2:8443';

IOClient createHttpClientWithIgnoreBadCert() {
  HttpClient client = HttpClient();
  if (kDebugMode) {
    // Chỉ bỏ qua trong chế độ debug
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            true; // Accept any certificate
  }
  return IOClient(client);
}

late final IOClient _httpClient = createHttpClientWithIgnoreBadCert();
IOClient get httpClient => _httpClient;
