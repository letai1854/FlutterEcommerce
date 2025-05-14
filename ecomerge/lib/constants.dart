import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
final String baseUrl = kIsWeb 
    ? 'https://localhost:8443' // For web
    : 'https://10.0.2.2:8443'; // For Android emulator

// IMPORTANT: Replace with your actual Gemini API Key.
// For production, use environment variables or a secure key management solution.
const String geminiApiKey = "AIzaSyDTjMKiwUQHn7f6DH_DqsK-ckRS3LY2eFM";

final bool isWeb = kIsWeb;
var myDeflaultBackground = const Color.fromARGB(255, 213, 213, 213);
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
var myAppBar = AppBar(
  backgroundColor: Colors.grey[900],
);
var myDrawer = Drawer(
        backgroundColor:  Colors.grey[300],
        child: Column(
          children: const [
            DrawerHeader(child: Icon(Icons.favorite)),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('D A S H B O A R D'),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('M E S S A G E'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('S E T T I N G S'),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('L O G O U T'),
            ),
          ],
        ),
       );
