import 'dart:ffi';
import 'package:posix/posix.dart' as posix;
import 'dart:io';
import 'dart:typed_data';

// ignore: unused_import
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:linux_can/src/bindings.dart';
import 'package:linux_can/src/bindings/custom_bindings.dart';

import 'bindings/libc_arm32.g.dart';

const _DYLIB = "libc.so.6";

typedef _dart_write = int Function(
  int fd,
  Pointer<Int8> buf,
  int n,
);

class CanDevice {
  late final _libC = LibC(DynamicLibrary.open(_DYLIB));
  final int bitrate;
  final String interfaceName;

  CanDevice({
    this.bitrate = 500000,
    this.interfaceName = 'can0',
  });

  int _socket = -1;

  /// Sets up the socket and binds it. Throws an `SocketException``
  /// when something wents wrong.
  Future setup() async {
    // final isolate = await Isolate.spawn<int>(_setupBitrate, bitrate);
    // isolate.kill();

    _socket = _libC.socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (_socket < 0)
      throw SocketException("Failed to open CAN socket for $interfaceName.");

    // Set socket non-blocking
    // final flags = _libC.fcntl(_socket, F_GETFL, 0);
    // _libC.fcntl(_socket, F_SETFL, flags | O_NONBLOCK);

    // IFR
    final ifrPtr = calloc.allocate<ifreq>(sizeOf<ifreq>());
    final ifr = ifrPtr.ref;

    final ifName = this.interfaceName.toNativeUtf8().cast<Int8>();

    // The cast here only works because the ifr_name field is the first field
    // in the struct. If the struct changes, this will break.
    // See https://github.com/dart-lang/sdk/issues/41237
    posix.strcpy(ifrPtr as Pointer<Int8>, ifName);

    final outputioctl = _libC.ioctlPointer(_socket, SIOCGIFINDEX, ifrPtr);
    if (outputioctl < 0)
      throw SocketException("Failed to initalize CAN socket: $_socket");

    // CAN Addr
    final addrCanPtr = calloc.allocate<sockaddr_can>(sizeOf<sockaddr_can>());
    final addrCan = addrCanPtr.ref;
    addrCan.can_family = AF_CAN;
    addrCan.can_ifindex = ifr.ifr_ifindex;

    print('ifr_ifindex: ${ifr.ifr_ifindex}');
    print('addrCan.can_ifindex: ${addrCan.can_ifindex}');

    // Bind socket
    final len = sizeOf<sockaddr_can>();
    final sockaddrPtr = addrCanPtr.cast<sockaddr>();
    final output = _libC.bind(_socket, sockaddrPtr, len);
    if (output < 0) {
      throw SocketException("Failed to bind CAN socket: $_socket");
    }

    print("Socket: $_socket");

    calloc.free(ifrPtr);
    calloc.free(addrCanPtr);
  }

  /// Reads from the CAN bus. Throws an `SocketException` when failed.
  CanFrame read() {
    if (_socket < 0) throw StateError("Call setup() before reading.");

    final canFrame = calloc.allocate<can_frame>(sizeOf<can_frame>());
    final pointer = canFrame.cast<Void>();
    final len = sizeOf<can_frame>();

    final data = posix.read(_socket, len);
    if (data.length == 0)
      throw SocketException("Failed to read from CAN Socket: $_socket");

    print('data: $data');

    // if (_libC.read(_socket, pointer, len) < 0)
    //   throw SocketException("Failed to read from CAN Socket: $_socket");

    final resultFrame = pointer.cast<can_frame>().ref;
    final read = CanFrame._fromNative(resultFrame);

    calloc.free(canFrame);
    return read;
  }

  /// Copies a dart list of integers into a c buffer.
  /// You MUST free the returned buffer by calling [pffi.malloc.free];
  Pointer<Int8> copyDartListToCBuff(List<int> buf) {
    final cBuf = malloc.allocate<Int8>(buf.length);

    for (var i = 0; i < buf.length; i++) {
      cBuf[i] = buf.indexOf(i);
    }

    return cBuf;
  }

  /// Writes to the CAN bus. No error checking currently
  void write() {
    if (_socket < 0) throw StateError("Call setup() before writing.");

    ByteData canFrameData = ByteData(sizeOf<can_frame>());
    canFrameData.setUint32(0, 0x7E0);
    canFrameData.setUint8(5, 3); // length
    // canFrameData.setUint8(6, 0); // pad
    // canFrameData.setUint8(7, 0); // res0
    // canFrameData.setUint8(8, 0); // res1
    canFrameData.setUint8(9, 0x02); // data
    canFrameData.setUint8(10, 0x10); // data
    canFrameData.setUint8(11, 0x01); // data

    print('sending on socket: $_socket');
    posix.write(_socket, canFrameData.buffer.asUint8List());

    final canFrame = copyDartListToCBuff(canFrameData.buffer.asUint8List());

    // final canFrame = calloc.allocate<can_frame>(sizeOf<can_frame>());
    // final canFramePtr = canFrame.ref;
    final pointer = canFrame.cast<Void>();
    final len = sizeOf<can_frame>();
    // canFramePtr.can_id = 0x7E0;
    // canFramePtr.can_dlc = 3;
    // canFramePtr.data[0] =
    //     0x02; //This is just a basic UDS diagnostic test. Since we dont know if the MCP2515 driver excludes its own messages, we would at least see the response.
    // canFramePtr.data[1] = 0x10;
    // canFramePtr.data[2] = 0x01;

    int written = _libC.write(_socket, pointer, len);

    if (written != sizeOf<can_frame>()) {
      int err = posix.errno();
      throw SocketException(
          "Failed to write to CAN Socket: $_socket - $written - $err");
    }

    calloc.free(canFrame);
  }

  void clearReceiveBuffer() {
    CanFrame? frame;
    do {
      try {
        frame = read();
      } catch (error) {
        break;
      }
    } while (!frame.isEmpty);
  }

  void close() {
    _libC.close(_socket);
    _socket = -1;
  }
}

class CanFrame {
  int? id;
  List<int> data = [];

  bool get isEmpty => data.isEmpty;

  CanFrame._fromNative(can_frame frame) {
    id = frame.can_id;
    final results = frame.data;
    for (int i = 0; i < results.length; i++) {
      data.add(results[i]);
    }
  }
}
