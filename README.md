# Linux CAN

Dart implementation of SocketCAN.

This version supports both reading and writing can frames. Selecting your can interface is now possible.

CAN-FD is not supported yet.

Compared to the upstream repository, I've re-implement the FFI interfaces and re-written the code signficantly.

Example `cansend` and `candump` programs are included in the `bin` directory.

## Using the package

There are no system dependenices needed, except the `libc.so.6` which probably should be installed on your device.

### Setup

At first create a `CanDevice`. You can set a custom bitrate, default is 500 000. Afterwards call `setup()`. A `SocketException` will be thrown if something goes wrong.

```dart
final canDevice = CanDevice(bitrate: 250000, interfaceName: 'vcan0');
await canDevice.setup();
```

### Reading Data

To receive data use `read()`, which returns a `CanFrame`. It contains the id and data of the frame.

```dart
final frame = canDevice.read();
print("Frame id: ${frame.id}");
print("Frame data: ${frame.data}");
```

To close the socket use `close()`.

### Writing Data

```dart
canDevice.write(CanFrame(
      id: 0x7E0,
      data: Uint8List.fromList([0x02, 0x10, i]),
    ));
```

# Testing

To test the package you can use the `vcan` kernel module. It is a virtual CAN bus which can be used to test the package without any hardware.

```bash
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

Then you can run candump to see the data which is sent to the virtual CAN bus.

In one terminal window:

```bash
dart run ./bin/candump.dart
```

In another terminal window:

```bash
dart run ./bin/cansend.dart
```

You should see the dart `candump` script receive the data from `cansend` and print it to the console.

## Limitations

- Bitrate currently needs to be set externally from the dart script.