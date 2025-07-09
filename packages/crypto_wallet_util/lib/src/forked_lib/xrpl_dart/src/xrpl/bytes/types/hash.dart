part of 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/bytes/serializer.dart';

abstract class Hash extends SerializedType {
  Hash([List<int>? buffer]) : super(buffer) {
    if (_buffer.length != getLength()) {
      throw XRPLBinaryCodecException(
          "Invalid hash length ${_buffer.length}. ${getLength()}");
    }
  }

  int getLength();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hash &&
        runtimeType == other.runtimeType &&
        bytesEqual(_buffer, other._buffer);
  }

  @override
  int get hashCode => _buffer.hashCode;
}
