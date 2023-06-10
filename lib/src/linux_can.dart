import 'dart:ffi';
import 'package:posix/posix.dart' as posix;
import 'dart:io';

// ignore: unused_import
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:linux_can/src/bindings/native.dart';

const _DYLIB = "libc.so.6";

class CanDevice {
  // late final _libC = LibC(DynamicLibrary.open(_DYLIB));
  late final _libC = native(DynamicLibrary.open(_DYLIB));
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

    final ifNamePtr = this.interfaceName.toNativeUtf8();

    int ifindex = _libC.if_nametoindex(ifNamePtr as Pointer<Char>);
    if (ifindex == 0) {
      throw SocketException(
          "Failed to get interface index for $interfaceName.");
    }

    // CAN Addr
    final addrCanPtr = calloc.allocate<sockaddr_can>(sizeOf<sockaddr_can>());
    final addrCan = addrCanPtr.ref;
    addrCan.can_family = AF_CAN;
    addrCan.can_ifindex = ifindex;

    print('can interface index: ${addrCan.can_ifindex}');

    // Bind socket
    final len = sizeOf<sockaddr_can>();
    final sockaddrPtr = addrCanPtr.cast<sockaddr>();
    final output = _libC.bind(_socket, sockaddrPtr, len);
    if (output < 0) {
      throw SocketException("Failed to bind CAN socket: $_socket");
    }

    calloc.free(ifNamePtr);
    calloc.free(addrCanPtr);
  }

  /// Reads from the CAN bus. Throws an `SocketException` when failed.
  CanFrame read() {
    if (_socket < 0) throw StateError("Call setup() before reading.");

    final canFrame = calloc.allocate<can_frame>(sizeOf<can_frame>());
    final pointer = canFrame.cast<Void>();
    final len = sizeOf<can_frame>();

    if (_libC.read(_socket, pointer, len) < 0)
      throw SocketException("Failed to read from CAN Socket: $_socket");

    final resultFrame = canFrame.ref;
    final read = CanFrame._fromNative(resultFrame);

    calloc.free(canFrame);
    return read;
  }

  /// Writes to the CAN bus. No error checking currently
  void write(CanFrame canFrame) {
    if (_socket < 0) throw StateError("Call setup() before writing.");

    final len = sizeOf<can_frame>();

    Pointer<can_frame> nativeFrame = canFrame.toNative();
    Pointer<Void> pointer = nativeFrame.cast<Void>();
    int written = _libC.send(_socket, pointer, len, 0);

    if (written != len) {
      int err = posix.errno();
      throw SocketException(
          "Failed to write to CAN Socket: Socket: $_socket - Wrote: $written - Errno: $err");
    }

    calloc.free(nativeFrame);
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

  CanFrame({
    this.id,
    this.data = const [],
  });

  CanFrame._fromNative(can_frame frame) {
    id = frame.can_id;
    final results = frame.data;
    for (int i = 0; i < frame.can_dlc; i++) {
      data.add(results[i]);
    }
  }

  Pointer<can_frame> toNative() {
    final framePtr = calloc.allocate<can_frame>(sizeOf<can_frame>());
    final frameRef = framePtr.ref;
    frameRef.can_id = id!;
    frameRef.can_dlc = data.length;
    for (int i = 0; i < data.length; i++) {
      frameRef.data[i] = data[i];
    }
    return framePtr;
  }
}
