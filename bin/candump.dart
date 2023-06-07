import 'dart:io';
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

  // canDevice.addListener((CanFrame frame) {
  //   print('Received frame: $frame');
  // });

  CanFrame canFrame = canDevice.read();
  // canFrame.data.forEach((element) {
  //   print(element);
  // });

  // canDevice.send(CanFrame(0x123, [1, 2, 3, 4, 5, 6, 7, 8]));
  for (var i = 0; i < 10; i++) {
    print('$i');
    canDevice.write();
    // await Future.delayed(Duration(milliseconds: 10));
  }
}
