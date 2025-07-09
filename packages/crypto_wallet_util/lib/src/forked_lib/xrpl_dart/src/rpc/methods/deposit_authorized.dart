import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/methods/methods.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/on_chain_models/on_chain_models.dart';
import '../core/methods_impl.dart';

/// The deposit_authorized command indicates whether one account
/// is authorized to send payments directly to another. See
/// Deposit Authorization for information on how to require
/// authorization to deliver money to your account.
class RPCDepositAuthorized extends XRPLedgerRequest<Map<String, dynamic>> {
  RPCDepositAuthorized({
    required this.sourceAccount,
    required this.destinationAccount,
    XRPLLedgerIndex? ledgerIndex = XRPLLedgerIndex.validated,
  }) : super(ledgerIndex: ledgerIndex);
  @override
  String get method => XRPRequestMethod.depositAuthorized;

  final String sourceAccount;
  final String destinationAccount;

  @override
  Map<String, dynamic> toJson() {
    return {
      "source_account": sourceAccount,
      "destination_account": destinationAccount,
    };
  }
}
