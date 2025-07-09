import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/rpc.dart';

/// The server_info command asks the server for a
/// human-readable version of various information
/// about the rippled server being queried.
class RPCServerInfo extends XRPLedgerRequest<ServerInfo> {
  RPCServerInfo();
  @override
  String get method => XRPRequestMethod.serverInfo;

  @override
  Map<String, dynamic> toJson() {
    return {};
  }

  @override
  ServerInfo onResonse(Map<String, dynamic> result) {
    return ServerInfo.fromJson(result);
  }
}
