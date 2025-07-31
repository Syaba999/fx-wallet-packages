import 'package:blockchain_utils/blockchain_utils.dart';

import '../../models/network.dart';
import 'core.dart';

List<int>? decodeLegacyAddress(String address, BitcoinAddressType type,
    {required BasedUtxoNetwork network}) {
  if (network is BitcoinCashNetwork) {
    return decodeBchAddress(address, type, network);
  }

  if (address.length < 26 || address.length > 35) {
    return null;
  }
  final decode = List<int>.unmodifiable(Base58Decoder.decode(address));
  final List<int> networkPrefix = [decode[0]];
  List<int> data = decode.sublist(0, decode.length - 4);
  List<int> checksum = decode.sublist(decode.length - 4);
  List<int> hash = QuickCrypto.sha256DoubleHash(data).sublist(0, 4);

  if (!bytesEqual(checksum, hash)) {
    return null;
  }
  final addrBytes =
      decode.sublist(1, decode.length - Base58Const.checksumByteLen);
  switch (type) {
    case BitcoinAddressType.p2pkh:
      if (bytesEqual(networkPrefix, network.p2pkhNetVer)) {
        return addrBytes;
      }
      return null;

    case BitcoinAddressType.p2pkhInP2sh:
    case BitcoinAddressType.p2pkInP2sh:
    case BitcoinAddressType.p2wshInP2sh:
    case BitcoinAddressType.p2wpkhInP2sh:
      if (bytesEqual(networkPrefix, network.p2shNetVer)) {
        return addrBytes;
      }
      return null;
    default:
  }
  return addrBytes;
}

bool bytesEqual(List<int> checksum, List<int> hash) {
  if (checksum.length != hash.length) {
    return false;
  }
  for (int i = 0; i < checksum.length; i++) {
    if (checksum[i] != hash[i]) return false;
  }
  return true;
}

bool isValidHash160(String hash160) {
  if (hash160.length != 40) {
    return false;
  }
  try {
    BigInt.parse(hash160, radix: 16);
  } catch (e) {
    return false;
  }
  return true;
}

List<int>? decodeBchAddress(
    String address, BitcoinAddressType type, BitcoinCashNetwork network) {
  try {
    String hrp;
    List<int> netVersion;
    if (type.isP2sh) {
      hrp = network.conf.params.p2shStdHrp!;
      netVersion = network.conf.params.p2shStdNetVer!;
    } else {
      hrp = network.conf.params.p2pkhStdHrp!;
      netVersion = network.conf.params.p2pkhStdNetVer!;
    }

    final decode = BchBech32Decoder.decode(hrp, address);
    if (bytesEqual(decode.item1, netVersion)) {
      return decode.item2;
    }
    return null;
  } catch (e) {
    return null;
  }
}
