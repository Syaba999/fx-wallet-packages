import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/number/number_parser.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/utility/helper.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

/// Represents a [PaymentChannelCreate](https://xrpl.org/paymentchannelcreate.html)
/// transaction, which creates a [payment channel](https://xrpl.org/payment-channels.html) and funds it with
/// XRP. The sender of this transaction is the "source address" of the payment
/// channel.
class PaymentChannelCreate extends XRPTransaction {
  /// [amount] The amount of XRP, in drops, to set aside in this channel.
  final BigInt amount;

  /// [destination] can receive XRP from this channel, also known as the
  /// "destination address" of the channel. Cannot be the same as the sender.
  final String destination;

  /// [settleDelay] The amount of time, in seconds, the source address must wait between
  /// requesting to close the channel and fully closing it.
  final int settleDelay;

  /// [publicKey] The public key of the key pair that the source will use to authorize
  /// claims against this  channel, as hexadecimal. This can be any valid
  /// secp256k1 or Ed25519 public key.
  final String publicKey;

  /// [cancelAfter] An immutable expiration time for the channel.
  /// The channel can be closed sooner than this but cannot remain open
  /// later than this time.
  late final int? cancelAfter;
  final int? destinationTag;

  PaymentChannelCreate(
      {required String account,
      required this.amount,
      required this.destination,
      required this.settleDelay,
      required this.publicKey,
      DateTime? cancelAfterTime,
      this.destinationTag,
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
            transactionType: XRPLTransactionType.paymentChannelCreate) {
    if (cancelAfterTime != null) {
      cancelAfter = XRPHelper.datetimeToRippleTime(cancelAfterTime);
    } else {
      cancelAfter = null;
    }
  }

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      "amount": amount.toString(),
      "destination": destination,
      "settle_delay": settleDelay,
      "public_key": publicKey,
      "cancel_after": cancelAfter,
      "destination_tag": destinationTag,
      ...super.toJson()
    };
  }

  PaymentChannelCreate.fromJson(Map<String, dynamic> json)
      : amount = parseBigInt(json["amount"])!,
        cancelAfter = json["cancel_after"],
        destination = json["destination"],
        destinationTag = json["destination_tag"],
        publicKey = json["public_key"],
        settleDelay = json["settle_delay"],
        super.json(json);
}
