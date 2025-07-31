import 'package:blockchain_utils/blockchain_utils.dart';

import '../../bitcoin/script/op_code/constant.dart';
import '../../crypto/keypair/ec_public.dart';
import 'script.dart';

class ControlBlock {
  ControlBlock({required this.public, this.scriptToSpend, this.scripts});
  late final ECPublic public;
  final Script? scriptToSpend;
  final List<int>? scripts;

  List<int> toBytes() {
    final List<int> version = [BitcoinOpCodeConst.LEAF_VERSION_TAPSCRIPT];

    final List<int> pubKey = BytesUtils.fromHexString(public.toXOnlyHex());
    final List<int> marklePath = scripts ?? [];
    return [...version, ...pubKey, ...marklePath];
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }
}
