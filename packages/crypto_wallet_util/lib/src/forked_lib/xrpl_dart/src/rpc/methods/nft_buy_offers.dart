import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/methods/methods.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/on_chain_models/on_chain_models.dart';
import '../core/methods_impl.dart';

/// The [nft_buy_offers] method retrieves all of buy offers
/// for the specified NFToken.
class RPCNFTBuyOffers extends XRPLedgerRequest<Map<String, dynamic>> {
  RPCNFTBuyOffers(
      {required this.nftId,
      XRPLLedgerIndex? ledgerIndex = XRPLLedgerIndex.validated});
  @override
  String get method => XRPRequestMethod.nftBuyOffers;

  final String nftId;

  @override
  Map<String, dynamic> toJson() {
    return {"nft_id": nftId};
  }
}
