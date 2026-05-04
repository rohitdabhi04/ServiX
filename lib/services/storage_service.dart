import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StorageService {
  static const String _cloudName = 'defbsehfy';
  static const String _uploadPreset = 'ServiX';

  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Generic upload helper — returns secure_url or null
  Future<String?> _upload(File file, String folder,
      {void Function(double)? onProgress}) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      // http package doesn't support progress natively,
      // but we simulate 0→1 via send/listen pattern:
      if (onProgress != null) onProgress(0.1);
      final response = await request.send();
      if (onProgress != null) onProgress(0.8);
      final body = await response.stream.bytesToString();
      if (onProgress != null) onProgress(1.0);

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      } else {
        print('Cloudinary Error: $body');
        return null;
      }
    } catch (e) {
      print('StorageService Error: $e');
      return null;
    }
  }

  /// Upload profile photo → profile_images/
  Future<String?> uploadProfileImage(File file) =>
      _upload(file, 'profile_images');

  /// Upload portfolio photo → portfolio/
  /// [onProgress] callback: 0.0 → 1.0
  Future<String?> uploadPortfolioImage(File file,
      {void Function(double)? onProgress}) =>
      _upload(file, 'portfolio', onProgress: onProgress);

  /// Upload chat image → chat_images/
  Future<String?> uploadChatImage(File file) =>
      _upload(file, 'chat_images');
}