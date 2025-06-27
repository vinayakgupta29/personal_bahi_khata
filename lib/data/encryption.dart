import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

class EncryptionAES {
  static const String KEY = "viksviksviksvikspbkepbkepbkepbke";
  static const int KEY_LENGTH = EncryptionAES.KEY.length;
  static const int IV_LENGTH = 12;
  final int TAG_LENGTH = 16;
  final int SALT_LENGTH = 16;
  final int KEY_ITERATIONS_COUNT = 10000;

  static Future<List<int>> encryptAESGCM(
    List<int> plaintext,
    String keyBase64,
  ) async {
    // Decode the Base64-encoded key
    final keyBytes = base64Decode(keyBase64);

    // Create the AES key (32 bytes for AES-256)
    final key = enc.Key(keyBytes);

    // Generate a random nonce (12 bytes for AES-GCM)
    final iv = enc.IV.fromLength(EncryptionAES.IV_LENGTH);

    try {
      // Create AES-GCM encryption
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      // Encrypt the plaintext
      final encrypted = encrypter.encryptBytes(plaintext, iv: iv);

      // Combine the nonce and ciphertext into a single list of bytes
      final combined = <int>[];

      combined.addAll(encrypted.bytes); // Add the encrypted bytes
      combined.addAll(iv.bytes); // Add the nonce
      combined.addAll(key.bytes);
      return combined; // Return the combined list of bytes
    } catch (e) {
      throw Exception("Encryption failed: $e");
    }
  }

  static Future<List<int>> decryptAESGCM(
    List<int> ciphertextBase64,
    String keyBase64,
  ) async {
    // Decode the Base64-encoded ciphertext and key
    final ciphertextBytes = Uint8List.fromList(ciphertextBase64);
    final keyBytes = base64Decode(keyBase64);

    // Create the AES key (32 bytes for AES-256)
    final key = enc.Key(keyBytes);

    // The nonce is the first part of the ciphertext (12 bytes for AES-GCM)
    if (ciphertextBytes.length < EncryptionAES.IV_LENGTH) {
      throw Exception("Data to decrypt is too small");
    }
    final footer = ciphertextBytes.length - EncryptionAES.IV_LENGTH;
    // Extract nonce (initialization vector)
    final nonce = enc.IV(ciphertextBytes.sublist(footer));

    // The remaining ciphertext after the nonce
    final encryptedBytes = ciphertextBytes.sublist(0, footer);

    try {
      // Create AES-GCM decryption
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      // Decrypt the data
      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted(encryptedBytes),
        iv: nonce,
      );

      // Convert the decrypted bytes to a UTF-8 string and return it
      return decryptedBytes;
    } catch (e) {
      throw Exception("Decryption failed: $e");
    }
  }
}
