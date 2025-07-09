import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/rpc.dart';

/// Retrieve information about the public ledger.
/// See [ledger](https://xrpl.org/ledger.html)
class RPCLedger extends XRPLedgerRequest<LedgerData> {
  RPCLedger(
      {this.full = false,
      this.accounts = false,
      this.transactions = false,
      this.expand = false,
      this.ownerFunds = false,
      this.binary = false,
      this.queue = false,
      this.type,
      XRPLLedgerIndex? ledgerIndex = XRPLLedgerIndex.validated})
      : super(ledgerIndex: ledgerIndex);
  @override
  String get method => XRPRequestMethod.ledger;

  final bool full;
  final bool accounts;
  final bool transactions;
  final bool expand;
  final bool ownerFunds;
  final bool binary;
  final bool queue;
  final LedgerEntryType? type;

  @override
  Map<String, dynamic> toJson() {
    return {
      "full": full,
      "accounts": accounts,
      "transactions": transactions,
      "expand": expand,
      "owner_funds": ownerFunds,
      "binary": binary,
      "queue": queue,
      "type": type?.value
    };
  }

  @override
  LedgerData onResonse(Map<String, dynamic> result) {
    return LedgerData.fromJson(result);
  }
}
