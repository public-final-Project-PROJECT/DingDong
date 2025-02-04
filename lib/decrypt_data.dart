import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class DecryptResult {
  final String? data;
  final String? error;

  DecryptResult({this.data, this.error});

  bool get isSuccess => data != null && error == null;
}

DecryptResult decryptData(String encryptedData, String secretKey) {
  try {
    final encryptedBytes = base64.decode(encryptedData);

    final prefix = utf8.decode(encryptedBytes.sublist(0, 8));
    if (prefix != "Salted__") {
      return DecryptResult(error: "Invalid encrypted data format");
    }

    final salt = encryptedBytes.sublist(8, 16);

    final keyAndIV = _deriveKeyAndIV(secretKey, salt);

    final ciphertext = encryptedBytes.sublist(16);

    final key = encrypt.Key(Uint8List.fromList(keyAndIV.sublist(0, 32)));
    final iv = encrypt.IV(Uint8List.fromList(keyAndIV.sublist(32, 48)));
    final encrypted = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"));

    final decrypted = encrypted.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(ciphertext)),
        iv: iv);

    return DecryptResult(data: utf8.decode(decrypted));
  } catch (e) {
    return DecryptResult(error: "Decryption failed: $e");
  }
}

List<int> _deriveKeyAndIV(String password, List<int> salt) {
  final passwordBytes = utf8.encode(password);
  final totalLength = 48;

  var derived = <int>[];
  var block = <int>[];

  while (derived.length < totalLength) {
    final input = [...block, ...passwordBytes, ...salt];
    block = md5.convert(input).bytes;
    derived.addAll(block);
  }

  return derived.sublist(0, totalLength);
}
