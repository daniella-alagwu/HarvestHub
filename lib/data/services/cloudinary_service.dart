import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const Duration _timeout = Duration(seconds: 30);

  String _env(String key) {
    try {
      if (dotenv.isInitialized) {
        return (dotenv.maybeGet(key) ?? '').trim();
      }
    } catch (_) {}
    return '';
  }

  Future<String> uploadImage(
    Uint8List bytes, {
    String filename = 'product.jpg',
  }) async {
    final cloudName = _env('CLOUDINARY_CLOUD_NAME');
    final uploadPreset = _env('CLOUDINARY_UPLOAD_PRESET');

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Image upload is not configured. Set CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET in .env and restart the app.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    )
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final http.Response response;
    try {
      final streamed = await request.send().timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Image upload timed out. Check your connection.');
    }

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode != 200) {
      final error = body['error'];
      final message = error is Map ? error['message'] : null;
      throw Exception(
        'Image upload failed (${response.statusCode}): '
        '${message ?? 'unknown error'}',
      );
    }

    final url = body['secure_url'];
    if (url is! String || url.isEmpty) {
      throw Exception('Image upload did not return an image link.');
    }
    return url;
  }
}
