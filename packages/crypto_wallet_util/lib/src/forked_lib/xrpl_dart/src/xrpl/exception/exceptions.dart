import 'package:blockchain_utils/blockchain_utils.dart';

/// Exception thrown when an error occurs during XRPL binary encoding or decoding.
class XRPLBinaryCodecException implements BlockchainUtilsException {
  @override
  final String message;

  /// Constructor for XRPLBinaryCodecException
  const XRPLBinaryCodecException(this.message);

  @override
  String toString() => message;

  @override
  Map<String, dynamic>? get details => throw UnimplementedError();
}

/// Exception thrown when an error occurs during XRPL address encoding or decoding.
class XRPLAddressCodecException implements BlockchainUtilsException {
  @override
  final String message;

  /// Constructor for XRPLAddressCodecException
  const XRPLAddressCodecException(this.message);
  @override
  String toString() => message;

  @override
  Map<String, dynamic>? get details => throw UnimplementedError();
}
