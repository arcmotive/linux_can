# Linux CAN

Dart implementation of SocketCAN.

Big shout out to [@ardera](https://github.com/ardera) who helped me a lot developing this package.

## Using the package

There are no system dependenices needed, except the `libc.so.6` which probably should be installed on your device.

### Setup

At first create a `CanDevice`. You can set a custom bitrate, default is 500 000. Afterwards call `setup()`. A `SocketException` will be thrown if something goes wrong.

```dart
final canDevice = CanDevice(bitrate: 250000, interfaceName: 'vcan0');
await canDevice.setup();
```

### Communication

To receive data use `read()`, which returns a `CanFrame`. It contains the id and data of the frame.

```dart
final frame = canDevice.read();
print("Frame id: ${frame.id}");
print("Frame data: ${frame.data}");
```

To close the socket use `close()`.

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
candump vcan0
```

In another terminal window:

```bash
dart run ./bin/candump.dart
```

And in a third:

```bash
cansend vcan0 123#1122334455667788
```

You should see the dart candump script receive the data from `cansend` and print it to the console. Then the script will try and send an frame, but unfortunately it will fail for unknown reasons.

## Limitations

- Bitrate currently needs to be set externally from the dart script.