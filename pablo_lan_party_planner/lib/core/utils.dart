import 'dart:convert';
import 'package:crypto/crypto.dart';

String encryptData(String data, {String key = 'lanparty-key'}) {
  final bytes = utf8.encode('$data$key');
  final digest = sha256.convert(bytes);
  return base64Encode(digest.bytes);
}