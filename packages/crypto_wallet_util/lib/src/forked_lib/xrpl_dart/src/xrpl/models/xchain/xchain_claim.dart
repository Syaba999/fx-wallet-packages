import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

/// Represents a XChainClaim transaction.
/// The XChainClaim transaction completes a cross-chain transfer of value.
/// It allows a user to claim the value on the destination chain - the
/// equivalent of the value locked on the source chain.
class XChainClaim extends XRPTransaction {
  XChainClaim.fromJson(Map<String, dynamic> json)
      : xchainBridge = XChainBridge.fromJson(json["xchain_bridge"]),
        xchainClaimId = json["xchain_claim_id"],
        amount = CurrencyAmount.fromJson(json["amount"]),
        destination = json["destination"],
        destinationTag = json["destination_tag"],
        super.json(json);

  /// The bridge to use for the transfer. This field is required.
  final XChainBridge xchainBridge;

  /// The unique integer ID for the cross-chain transfer that was referenced in
  /// the corresponding XChainCommit transaction. This field is required.
  final int xchainClaimId;

  /// The destination account on the destination chain. It must exist or the
  /// transaction will fail. However, if the transaction fails in this case, the
  /// sequence number and collected signatures won't be destroyed, and the
  /// transaction can be rerun with a different destination. This field is
  /// required.
  final String destination;

  /// An integer destination tag.
  final int? destinationTag;

  /// The amount to claim on the destination chain. This must match the amount
  /// attested to on the attestations associated with this XChainClaimID.
  /// This field is required.
  final CurrencyAmount amount;

  XChainClaim(
      {required String account,
      required this.xchainBridge,
      required this.xchainClaimId,
      required this.destination,
      this.destinationTag,
      required this.amount,
      List<XRPLMemo>? memos = const [],
      String signingPubKey = "",
      int? ticketSequance,
      BigInt? fee,
      int? lastLedgerSequence,
      int? sequence,
      List<XRPLSigners>? signers,
      dynamic flags,
      int? sourceTag,
      List<String> multiSigSigners = const []})
      : super(
            account: account,
            fee: fee,
            lastLedgerSequence: lastLedgerSequence,
            memos: memos,
            sequence: sequence,
            signers: signers,
            sourceTag: sourceTag,
            flags: flags,
            ticketSequance: ticketSequance,
            signingPubKey: signingPubKey,
            multiSigSigners: multiSigSigners,
            transactionType: XRPLTransactionType.xChainClaim);

  @override
  Map<String, dynamic> toJson() {
    return {
      "xchain_bridge": xchainBridge.toJson(),
      "xchain_claim_id": xchainClaimId,
      "amount": amount.toString(),
      "destination": destination,
      "destination_tag": destinationTag,
      ...super.toJson()
    };
  }

  @override
  String? get validate {
    if (amount.toCurrency() != xchainBridge.issuingChainIssue) {
      return "amount must match either locking chain issue or issuing chain issue.";
    }
    return super.validate;
  }
}
