import '../../../bitcoin_base.dart';

/// MultiSignatureSigner is an interface that defines methods required for representing
/// signers in a multi-signature scheme. A multi-signature signer typically includes
/// information about their public key and weight within the scheme.
class MultiSignatureSigner {
  MultiSignatureSigner._(this.publicKey, this.weight);

  /// PublicKey returns the public key associated with the signer.
  final String publicKey;

  /// Weight returns the weight or significance of the signer within the multi-signature scheme.
  /// The weight is used to determine the number of signatures required for a valid transaction.
  final int weight;

  /// creates a new instance of a multi-signature signer with the
  /// specified public key and weight.
  factory MultiSignatureSigner(
      {required String publicKey, required int weight}) {
    ECPublic.fromHex(publicKey);
    return MultiSignatureSigner._(publicKey, weight);
  }
}

/// MultiSignatureAddress represents a multi-signature Bitcoin address configuration, including
/// information about the required signers, threshold, the address itself,
/// and the script details used for multi-signature transactions.
class MultiSignatureAddress {
  /// Signers is a collection of signers participating in the multi-signature scheme.
  final List<MultiSignatureSigner> signers;

  /// Threshold is the minimum number of signatures required to spend the bitcoins associated
  /// with this address.
  final int threshold;

  // /// Address represents the Bitcoin address associated with this multi-signature configuration.
  // final BitcoinAddress address;

  /// ScriptDetails provides details about the multi-signature script used in transactions,
  /// including "OP_M", compressed public keys, "OP_N", and "OP_CHECKMULTISIG."
  final Script multiSigScript;

  BitcoinAddress toP2wshAddress({required BasedUtxoNetwork network}) {
    if (network is! LitecoinNetwork && network is! BitcoinNetwork) {
      throw ArgumentError(
          "${network.conf.coinName.name} Bitcoin forks that do not support Segwit. use toP2shAddress");
    }
    return P2wshAddress.fromScript(script: multiSigScript);
  }

  BitcoinAddress toP2wshInP2shAddress({required BasedUtxoNetwork network}) {
    final p2wsh = toP2wshAddress(network: network);
    return P2shAddress.fromScript(
        script: p2wsh.toScriptPubKey(), type: BitcoinAddressType.p2wshInP2sh);
  }

  BitcoinAddress toP2shAddress() {
    return P2shAddress.fromScript(
        script: multiSigScript, type: BitcoinAddressType.p2pkhInP2sh);
  }

  BitcoinAddress fromType(
      {required BasedUtxoNetwork network,
      required BitcoinAddressType addressType}) {
    switch (addressType) {
      case BitcoinAddressType.p2wsh:
        return toP2wshAddress(network: network);
      case BitcoinAddressType.p2wshInP2sh:
        return toP2wshInP2shAddress(network: network);
      case BitcoinAddressType.p2pkhInP2sh:
        return toP2shAddress();
      default:
        throw ArgumentError(
            "invalid multisig address type. use of of them [BitcoinAddressType.p2wsh, BitcoinAddressType.p2wshInP2sh, BitcoinAddressType.p2pkhInP2sh]");
    }
  }

  MultiSignatureAddress._(
      {required this.signers,
      required this.threshold,
      // required this.address,
      required this.multiSigScript});

  /// CreateMultiSignatureAddress creates a new instance of a MultiSignatureAddress, representing
  /// a multi-signature Bitcoin address configuration. It allows you to specify the minimum number
  /// of required signatures (threshold), provide the collection of signers participating in the
  /// multi-signature scheme, and specify the address type.
  factory MultiSignatureAddress({
    required int threshold,
    required List<MultiSignatureSigner> signers,
  }) {
    final sumWeight =
        signers.fold<int>(0, (sum, signer) => sum + signer.weight);
    if (threshold > 16 || threshold < 1) {
      throw ArgumentError('The threshold should be between 1 and 16');
    }
    if (sumWeight > 16) {
      throw ArgumentError(
          'The total weight of the owners should not exceed 16');
    }
    if (sumWeight < threshold) {
      throw ArgumentError(
          'The total weight of the signatories should reach the threshold');
    }
    final multiSigScript = <Object>['OP_$threshold'];
    for (final signer in signers) {
      for (var w = 0; w < signer.weight; w++) {
        multiSigScript.add(signer.publicKey);
      }
    }
    multiSigScript.addAll(['OP_$sumWeight', 'OP_CHECKMULTISIG']);
    final script = Script(script: multiSigScript);
    return MultiSignatureAddress._(
        signers: signers, threshold: threshold, multiSigScript: script);
  }
}
