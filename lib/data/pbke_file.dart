import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:personal_bahi_khata/data/encryption.dart';
import 'package:zstandard/zstandard.dart';

final Zstandard _zstd = Zstandard();

enum PbkeFormatMode { legacy, v_01_01 }

class PbkeReadResult {
  const PbkeReadResult({
    required this.data,
    required this.lastDate,
    required this.version,
  });

  final Map<String, dynamic> data;
  final DateTime? lastDate;
  final String version;
}

class _PbkeFooter {
  const _PbkeFooter({
    required this.keyBytes,
    required this.ivBytes,
    required this.encryptedPayload,
  });

  final List<int> keyBytes;
  final List<int> ivBytes;
  final List<int> encryptedPayload;
}

class PbkeFile {
  static const String unsupportedFileMessage = "File is not-supported";
  static const String version = "01_10";
  static const String signature = "%PBKE%";
  static const String mimeType = "application/vnd.vins.bahi-khata";

  static const int _unixTimeLength = 4;
  static const int _previousHeaderSize = 23;
  static const int _currentHeaderSize = 16;
  static const int _previousPaddingLength =
      _previousHeaderSize - signature.length - _unixTimeLength;
  static const int _currentPaddingLength =
      _currentHeaderSize - signature.length - version.length - _unixTimeLength;

  static final List<int> _signatureBytes = utf8.encode(signature);
  static final List<int> _versionBytes = utf8.encode(version);

  static const int headerSize = _currentHeaderSize;

  static void validateHeaderConfig() {
    if (_previousHeaderSize >= 100 ||
        _currentHeaderSize >= 100 ||
        _previousPaddingLength < 0 ||
        _currentPaddingLength < 0) {
      throw const FormatException(unsupportedFileMessage);
    }
  }

  static List<int> _getUnixTime(DateTime? date) {
    if (date == null) {
      return [0, 0, 0, 0];
    }

    final unixTime = date.millisecondsSinceEpoch ~/ 1000;
    return [
      (unixTime >> 24) & 0xFF,
      (unixTime >> 16) & 0xFF,
      (unixTime >> 8) & 0xFF,
      unixTime & 0xFF,
    ];
  }

  static void validateFileHeader(List<int> fileBytes) {
    validateHeaderConfig();
    final storedSignature = _readSignature(fileBytes);
    if (storedSignature != signature) {
      throw const FormatException(unsupportedFileMessage);
    }
  }

  static PbkeFormatMode _readFormatMode(List<int> fileBytes) {
    final storedSignature = _readSignature(fileBytes);
    if (storedSignature != signature) {
      throw const FormatException(unsupportedFileMessage);
    }

    if (fileBytes.length < _signatureBytes.length + version.length) {
      return PbkeFormatMode.legacy;
    }

    final versionStart = _signatureBytes.length;
    final versionEnd = versionStart + _versionBytes.length;
    final versionToken = utf8.decode(
      fileBytes.sublist(versionStart, versionEnd),
      allowMalformed: true,
    );
    if (versionToken == version) {
      return PbkeFormatMode.v_01_01;
    }
    if (_looksLikeVersionToken(versionToken)) {
      return PbkeFormatMode.legacy;
    }
    return PbkeFormatMode.legacy;
  }

  static int keyLengthForMode(PbkeFormatMode mode) {
    switch (mode) {
      case PbkeFormatMode.legacy:
        return 32;
      case PbkeFormatMode.v_01_01:
        return 32;
    }
  }

  static int ivLengthForMode(PbkeFormatMode mode) {
    switch (mode) {
      case PbkeFormatMode.legacy:
        return 12;
      case PbkeFormatMode.v_01_01:
        return 12;
    }
  }

  static int footerLengthForMode(PbkeFormatMode mode) {
    return keyLengthForMode(mode) + ivLengthForMode(mode);
  }

  static int headerSizeForMode(PbkeFormatMode mode) {
    switch (mode) {
      case PbkeFormatMode.legacy:
        return _previousHeaderSize;
      case PbkeFormatMode.v_01_01:
        return _currentHeaderSize;
    }
  }

  static int paddingLengthForMode(PbkeFormatMode mode) {
    switch (mode) {
      case PbkeFormatMode.legacy:
        return _previousPaddingLength;
      case PbkeFormatMode.v_01_01:
        return _currentPaddingLength;
    }
  }

  static String _readSignature(List<int> fileBytes) {
    if (fileBytes.length < _signatureBytes.length) {
      throw const FormatException(unsupportedFileMessage);
    }
    return utf8.decode(fileBytes.sublist(0, _signatureBytes.length));
  }

  static bool _looksLikeVersionToken(String value) {
    return RegExp(r'^\d{2}[_\.]\d{2}$').hasMatch(value);
  }

  static String readFileVersion(List<int> fileBytes) {
    return _readFormatMode(fileBytes) == PbkeFormatMode.v_01_01 ? version : "";
  }

  static DateTime? extractLastDate(List<int> fileBytes) {
    validateFileHeader(fileBytes);
    final mode = _readFormatMode(fileBytes);
    final currentHeaderSize = headerSizeForMode(mode);
    final footerLength = footerLengthForMode(mode);
    if (fileBytes.length <= currentHeaderSize + footerLength) {
      throw const FormatException(unsupportedFileMessage);
    }

    final dateStart =
        mode == PbkeFormatMode.legacy
            ? _signatureBytes.length
            : _signatureBytes.length + _versionBytes.length;
    final unixTimeBytes = fileBytes.sublist(
      dateStart,
      dateStart + _unixTimeLength,
    );
    if (unixTimeBytes.every((byte) => byte == 0)) {
      return null;
    }

    final unixTime =
        unixTimeBytes[0] << 24 |
        unixTimeBytes[1] << 16 |
        unixTimeBytes[2] << 8 |
        unixTimeBytes[3];
    return DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
  }

  static List<int> extractEncryptedPayload(List<int> fileBytes) {
    validateFileHeader(fileBytes);
    return _extractFooter(fileBytes).encryptedPayload;
  }

  static List<int> buildFileHeader(DateTime? date, {String fileVersion = version}) {
    validateHeaderConfig();
    final dateBytes = _getUnixTime(date);
    switch (fileVersion) {
      case "":
        return [
          ..._signatureBytes,
          ...dateBytes,
          ...List<int>.filled(paddingLengthForMode(PbkeFormatMode.legacy), 0),
        ];
      case version:
        return [
          ..._signatureBytes,
          ...utf8.encode(fileVersion),
          ...dateBytes,
          ...List<int>.filled(paddingLengthForMode(PbkeFormatMode.v_01_01), 0),
        ];
      default:
        throw const FormatException(unsupportedFileMessage);
    }
  }

  static Future<List<int>> compressAndEncryptJson(
    String jsonData, {
    String fileVersion = version,
  }) async {
    late final List<int> compressedData;
    switch (fileVersion) {
      case "":
        final zstdCompressed = await _zstd.compress(utf8.encode(jsonData), 13);
        compressedData = List<int>.from(zstdCompressed?.toList() ?? <int>[]);
        break;
      case version:
        compressedData = gzip.encode(utf8.encode(jsonData));
        break;
      default:
        throw const FormatException(unsupportedFileMessage);
    }

    final mode =
        fileVersion == version ? PbkeFormatMode.v_01_01 : PbkeFormatMode.legacy;
    final keyBytes = _randomBytes(keyLengthForMode(mode));
    final ivBytes = _randomBytes(ivLengthForMode(mode));
    final encryptedPayload = await EncryptionAES.encryptAESGCM(
      compressedData,
      keyBytes,
      ivBytes,
    );
    return [...encryptedPayload, ...ivBytes, ...keyBytes];
  }

  static Future<Map<String, dynamic>> decryptAndDecompressJson(
    List<int> encryptedCompressedData, {
    required List<int> keyBytes,
    required List<int> ivBytes,
    String fileVersion = version,
  }) async {
    debugPrint("pbke version $fileVersion");

    final decryptedData = await EncryptionAES.decryptAESGCM(
      encryptedCompressedData,
      keyBytes,
      ivBytes,
    );

    late final List<int> decompressedData;
    switch (fileVersion) {
      case "":
        final zstdDecompressed = await _zstd.decompress(
          Uint8List.fromList(decryptedData),
        );
        decompressedData = List<int>.from(zstdDecompressed ?? <int>[]);
        break;
      case version:
        decompressedData = gzip.decode(decryptedData);
        break;
      default:
        throw const FormatException(unsupportedFileMessage);
    }

    final jsonString = utf8.decode(decompressedData);
    final decodedJson = jsonDecode(jsonString);
    if (decodedJson is! Map<String, dynamic>) {
      throw const FormatException(unsupportedFileMessage);
    }
    return decodedJson;
  }

  static _PbkeFooter _extractFooter(List<int> fileBytes) {
    final mode = _readFormatMode(fileBytes);
    final currentHeaderSize = headerSizeForMode(mode);
    final keyLength = keyLengthForMode(mode);
    final ivLength = ivLengthForMode(mode);
    final footerLength = footerLengthForMode(mode);

    if (fileBytes.length <= currentHeaderSize + footerLength) {
      throw const FormatException(unsupportedFileMessage);
    }

    final footerStart = fileBytes.length - footerLength;
    final ivStart = footerStart;
    final keyStart = ivStart + ivLength;

    return _PbkeFooter(
      encryptedPayload: fileBytes.sublist(currentHeaderSize, footerStart),
      ivBytes: fileBytes.sublist(ivStart, keyStart),
      keyBytes: fileBytes.sublist(keyStart),
    );
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static Future<PbkeReadResult?> readPbkeFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final contents = await file.readAsBytes();
    if (contents.isEmpty) {
      return null;
    }

    final fileVersion = readFileVersion(contents);
    final lastDate = extractLastDate(contents);
    final footer = _extractFooter(contents);
    final decodedJson = await decryptAndDecompressJson(
      footer.encryptedPayload,
      keyBytes: footer.keyBytes,
      ivBytes: footer.ivBytes,
      fileVersion: fileVersion,
    );

    return PbkeReadResult(
      data: decodedJson,
      lastDate: lastDate,
      version: fileVersion,
    );
  }

  static Future<File> writePbkeFile(
    String filePath,
    String jsonData,
    DateTime? date, {
    String fileVersion = version,
  }) async {
    validateHeaderConfig();

    final encryptedCompressedBytes = await compressAndEncryptJson(
      jsonData,
      fileVersion: fileVersion,
    );
    final fileContent = [
      ...buildFileHeader(date, fileVersion: fileVersion),
      ...encryptedCompressedBytes,
    ];

    return File(filePath).writeAsBytes(fileContent);
  }
}
