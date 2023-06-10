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

  for (var i = 0; i < 10; i++) {
    print('$i');
    canDevice.write(CanFrame(
      id: 0x7E0,
      data: Uint8List.fromList([0x02, 0x10, i]),
    ));
    await Future.delayed(Duration(milliseconds: 10));
  }
}
