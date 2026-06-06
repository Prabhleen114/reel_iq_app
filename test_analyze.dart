import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  var request = http.MultipartRequest('POST', Uri.parse('http://192.168.29.25:8000/analyze-reel'));
  request.fields['title'] = 'Test';
  request.files.add(await http.MultipartFile.fromPath('file', 'backend/test_video.mp4'));
  try {
    var res = await request.send();
    print('Status: ${res.statusCode}');
    var body = await res.stream.bytesToString();
    print('Response Body: $body');
  } catch (e) {
    print('Error: $e');
  }
}
