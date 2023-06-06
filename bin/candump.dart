import 'dart:io';
import 'package:linux_can/linux_can.dart';

void main() async {
  final canDevice = CanDevice(bitrate: 250000, interfaceName: 'can1');
  try {
    await canDevice.setup();
  } on SocketException catch (e) {
    print('SocketException: ${e.message}');
    exit(1);
  }

  print('CanDevice setup successful.');
}
