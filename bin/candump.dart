import 'dart:io';
import 'dart:typed_data';
import 'package:linux_can/linux_can.dart';

void main() async {
  final canDevice = CanDevice(bitrate: 250000, interfaceName: 'vcan1');
  try {
    await canDevice.setup();
  } on SocketException catch (e) {
    print('SocketException: ${e.message}');
    exit(1);
  }

  print('CanDevice setup successful.');

  while (true) {
    CanFrame canFrame = canDevice.read();
    print('frame id: 0x${canFrame.id?.toRadixString(16)}'); // this works
    for (int i = 0; i < canFrame.data.length; i++) {
      print('${i}: ${canFrame.data[i]}\t${canFrame.data[i].toRadixString(16)}');
    }
  }
}
