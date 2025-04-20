import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryUtils {
  static final String cloudName =
      'dlne9uhda'; // Replace with your actual cloud name
  static final String apiKey =
      '871241446667216'; // Replace with your actual API Key
  static final String apiSecret =
      'c5h3QPC4immYhar1iozPzymATu8'; // Replace with your actual API Secret

  static String extractPublicId(String imageUrl) {
    // Example URL: https://res.cloudinary.com/myapp/image/upload/images/problem123.jpg
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    // The publicId is the last segment without the file extension
    final fileName = pathSegments.last;
    final publicIdWithExtension = fileName.split('.');
    final publicId = publicIdWithExtension[0];
    // Include the folder path if it exists (e.g., 'images/problem123')
    final folderIndex =
        pathSegments.indexOf('image') + 2; // Skip 'image/upload'
    final folderPath = pathSegments
        .sublist(folderIndex, pathSegments.length - 1)
        .join('/');
    return '$folderPath/$publicId';
  }

  static Future<void> deleteImageFromCloudinary(String publicId) async {
    final url =
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload/destroy';
    final body = {'public_id': publicId};
    final auth = base64Encode(utf8.encode('$apiKey:$apiSecret'));
    final headers = {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['result'] != 'ok') {
        throw Exception('Failed to delete image: ${response.body}');
      }
    } else {
      throw Exception(
        'Failed to delete image: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
