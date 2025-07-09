import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/rpc.dart';

/// This request retrieves information about an account, its activity, and its XRP
/// balance.
/// All information retrieved is relative to a particular version of the ledger.
/// See [account_info](https://xrpl.org/account_info.html)
class RPCAccountInfo extends XRPLedgerRequest<AccountInfo> {
  RPCAccountInfo({
    required this.account,
    this.queue = false,
    this.signerList = false,
    this.strict = false,
    super.ledgerIndex = XRPLLedgerIndex.validated,
  });
  @override
  String get method => XRPRequestMethod.accountInfo;

  final String account;
  final bool queue;
  final bool signerList;
  final bool strict;

  @override
  Map<String, dynamic> toJson() {
    return {
      "account": XRPAddressUtils.ensureClassicAddress(account),
      "queue": queue,
      "strict": strict,
      "signer_lists": signerList
    };
  }

  @override
  AccountInfo onResonse(Map<String, dynamic> result) {
    return AccountInfo.fromJson(result);
  }
}
