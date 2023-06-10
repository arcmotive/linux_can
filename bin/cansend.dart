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

  // canDevice.addListener((CanFrame frame) {
  //   print('Received frame: $frame');
  // });

  // for (var i = 0; i < 10; i++) {
  //   CanFrame canFrame = canDevice.read();
  //   print('frame id: 0x${canFrame.id?.toRadixString(16)}'); // this works
  //   for (int i = 0; i < canFrame.data.length; i++) {
  //     print(
  //         'real ${i}: ${canFrame.data[i]}\t${canFrame.data[i].toRadixString(16)}');
  //   }
  // }

  // canFrame.data.forEach((element) {
  //   print(element);
  // });

  for (var i = 0; i < 10; i++) {
    print('$i');
    canDevice.write(CanFrame(
      id: 0x7E0,
      data: Uint8List.fromList([0x02, 0x10, i]),
    ));
    await Future.delayed(Duration(milliseconds: 10));
  }
}
