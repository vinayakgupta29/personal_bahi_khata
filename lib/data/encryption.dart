import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

class EncryptionAES {
  final int TAG_LENGTH = 16;
  final int SALT_LENGTH = 16;
  final int KEY_ITERATIONS_COUNT = 10000;

  static Future<List<int>> encryptAESGCM(
    List<int> plaintext,
    List<int> keyBytes,
    List<int> ivBytes,
  ) async {
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(Uint8List.fromList(ivBytes));

    try {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
      return encrypted.bytes;
    } catch (e) {
      throw Exception("Encryption failed: $e");
    }
  }

  static Future<List<int>> decryptAESGCM(
    List<int> ciphertextBytes,
    List<int> keyBytes,
    List<int> ivBytes,
  ) async {
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(Uint8List.fromList(ivBytes));

    try {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(ciphertextBytes)),
        iv: iv,
      );
      return decryptedBytes;
    } catch (e) {
      throw Exception("Decryption failed: $e");
    }
  }
}
