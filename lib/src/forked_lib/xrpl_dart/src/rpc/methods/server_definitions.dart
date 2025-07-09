import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/methods/methods.dart';
import '../core/methods_impl.dart';

/// The definitions command asks the server for a
/// human-readable version of various information
/// about the rippled server being queried.
class RPCServerDefinitions extends XRPLedgerRequest<Map<String, dynamic>> {
  RPCServerDefinitions({this.hash});
  @override
  String get method => XRPRequestMethod.serverDefinitions;

  final String? hash;

  @override
  Map<String, dynamic> toJson() {
    return {"hash": hash};
  }
}
