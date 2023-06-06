import 'dart:io';
import 'package:linux_can/linux_can.dart';

void main() async {
  final canDevice = CanDevice(bitrate: 250000);
  await canDevice.setup();

  print('CanDevice setup successful.');
}
