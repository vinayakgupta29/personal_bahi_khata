import 'package:flutter/services.dart';

class TelephonyService {
  static const platform = MethodChannel(
    'com.vins.personal_bahi_khata/open_file',
  );
  Future<bool> isTelephonyAvailable() async {
    try {
      final bool result = await platform.invokeMethod('isTelephonyAvailable');
      return result;
    } on PlatformException catch (e) {
      print("Error checking telephony: ${e.message}");
      return false;
    }
  }
}
