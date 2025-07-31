import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../../bitcoin_base.dart';

typedef BitcoinSignerCallBack = String Function(
    List<int> trDigest, UtxoWithAddress utxo, String publicKey, int sighash);

class BitcoinTransactionBuilder {
  final List<BitcoinOutput> outPuts;
  final BigInt fee;
  final BasedUtxoNetwork network;
  final List<UtxoWithAddress> utxos;
  final String? memo;
  final bool enableRBF;
  final bool isFakeTransaction;
  BitcoinTransactionBuilder({
    required this.outPuts,
    required this.fee,
    required this.network,
    required this.utxos,
    this.memo,
    this.enableRBF = false,
    this.isFakeTransaction = false,
  }) {
    _validateBuilder();
  }

  /// validate network and address support before create transaction
  void _validateBuilder() {
    if (network is BitcoinCashNetwork) {
      throw ArgumentError(
          "invalid network for BitcoinTransactionBuilder use BCHTransactionBuilder");
    }
    for (final i in utxos) {
      /// Verify each input for its association with this network's address. Raise an exception if the address is incorrect.
      i.ownerDetails.address.toAddress(network);
    }
    for (final i in outPuts) {
      /// Verify each output for its association with this network's address. Raise an exception if the address is incorrect.
      i.address.toAddress(network);
    }
  }

  /// This method is used to create a dummy transaction,
  /// allowing us to obtain the size of the original transaction
  /// before conducting the actual transaction. This helps us estimate the transaction cost
  static int estimateTransactionSize(
      {required List<UtxoWithAddress> utxos,
      required List<BitcoinAddress> outputs,
      required BasedUtxoNetwork network,
      String? memo,
      bool enableRBF = false}) {
    final sum = utxos.sumOfUtxosValue();

    /// We consider the total amount for the output because,
    /// in all cases, the size of the amount is 8 bytes.
    final outs =
        outputs.map((e) => BitcoinOutput(address: e, value: sum)).toList();
    final transactionBuilder = BitcoinTransactionBuilder(
      /// Now, we provide the UTXOs we want to spend.
      utxos: utxos,

      /// We select transaction outputs
      outPuts: outs,
      /*
			Transaction fee
			Ensure that you have accurately calculated the amounts.
			If the sum of the outputs, including the transaction fee,
			does not match the total amount of UTXOs,
			it will result in an error. Please double-check your calculations.
		*/
      fee: BigInt.from(0),

      /// network, testnet, mainnet
      network: network,

      /// If you like the note write something else and leave it blank
      memo: memo,
      /*
			RBF, or Replace-By-Fee, is a feature in Bitcoin that allows you to increase the fee of an unconfirmed
			transaction that you've broadcasted to the network.
			This feature is useful when you want to speed up a
			transaction that is taking longer than expected to get confirmed due to low transaction fees.
		*/
      enableRBF: true,

      /// We consider the transaction to be fake so that it doesn't check the amounts
      /// and doesn't generate errors when determining the transaction size.
      isFakeTransaction: true,
    );

    /// 64 byte schnorr signature length
    const String fakeSchnorSignatureBytes =
        "01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101";

    /// 71 bytes (64 byte signature, 6-7 byte Der encoding length)
    const String fakeECDSASignatureBytes =
        "0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101";

    final transaction = transactionBuilder
        .buildTransaction((trDigest, utxo, multiSigPublicKey, int sighash) {
      if (utxo.utxo.isP2tr()) {
        return fakeSchnorSignatureBytes;
      } else {
        return fakeECDSASignatureBytes;
      }
    });

    /// Now we need the size of the transaction. If the transaction is a SegWit transaction,
    /// we use the getVSize method; otherwise, we use the getSize method to obtain the transaction size
    final size =
        transaction.hasSegwit ? transaction.getVSize() : transaction.getSize();

    return size;
  }

  /// HasSegwit checks whether any of the unspent transaction outputs (UTXOs) in the BitcoinTransactionBuilder's
  /// Utxos list are Segregated Witness (SegWit) UTXOs. It iterates through the Utxos list and returns true if it
  /// finds any UTXO with a SegWit script type; otherwise, it returns false.
//
  /// Returns:
  /// - bool: True if at least one UTXO in the list is a SegWit UTXO, false otherwise.
  bool _hasSegwit() {
    for (final element in utxos) {
      if (element.utxo.isSegwit()) {
        return true;
      }
    }
    return false;
  }

  /// HasTaproot checks whether any of the unspent transaction outputs (UTXOs) in the BitcoinTransactionBuilder's
  /// Utxos list are Pay-to-Taproot (P2TR) UTXOs. It iterates through the Utxos list and returns true if it finds
  /// any UTXO with a Taproot script type; otherwise, it returns false.
//
  /// Returns:
  /// - bool: True if at least one UTXO in the list is a P2TR UTXO, false otherwise.
  bool _hasTaproot() {
    for (final element in utxos) {
      if (element.utxo.isP2tr()) {
        return true;
      }
    }
    return false;
  }

  /// It is used to make the appropriate scriptSig
  Script _findLockingScript(UtxoWithAddress utxo, bool isTaproot) {
    if (utxo.isMultiSig()) {
      final multiSigAAddr = utxo.multiSigAddress;
      final script = multiSigAAddr.multiSigScript;
      switch (utxo.utxo.scriptType) {
        case BitcoinAddressType.p2wshInP2sh:
          if (isTaproot) {
            return multiSigAAddr
                .toP2wshInP2shAddress(network: network)
                .toScriptPubKey();
          }
          return script;
        case BitcoinAddressType.p2wsh:
          if (isTaproot) {
            return multiSigAAddr
                .toP2wshAddress(network: network)
                .toScriptPubKey();
          }
          return script;
        case BitcoinAddressType.p2pkhInP2sh:
          if (isTaproot) {
            return multiSigAAddr.toP2shAddress().toScriptPubKey();
          }
          return script;
        default:
          throw ArgumentError(
              "unsuported multi-sig type ${utxo.utxo.scriptType}");
      }
    }

    final senderPub = utxo.public();
    switch (utxo.utxo.scriptType) {
      case BitcoinAddressType.p2pk:
        return senderPub.toRedeemScript();
      case BitcoinAddressType.p2wsh:
        if (isTaproot) {
          return senderPub.toP2wshAddress().toScriptPubKey();
        }
        return senderPub.toP2wshScript();
      case BitcoinAddressType.p2pkh:
        return senderPub.toAddress().toScriptPubKey();
      case BitcoinAddressType.p2wpkh:
        if (isTaproot) {
          return senderPub.toSegwitAddress().toScriptPubKey();
        }
        return senderPub.toAddress().toScriptPubKey();
      case BitcoinAddressType.p2tr:
        return senderPub.toTaprootAddress().toScriptPubKey();
      case BitcoinAddressType.p2pkhInP2sh:
        if (isTaproot) {
          return senderPub.toP2pkhInP2sh().toScriptPubKey();
        }
        return senderPub.toAddress().toScriptPubKey();
      case BitcoinAddressType.p2wpkhInP2sh:
        if (isTaproot) {
          return senderPub.toP2wpkhInP2sh().toScriptPubKey();
        }
        return senderPub.toAddress().toScriptPubKey();
      case BitcoinAddressType.p2wshInP2sh:
        if (isTaproot) {
          return senderPub.toP2wshInP2sh().toScriptPubKey();
        }
        return senderPub.toP2wshScript();
      case BitcoinAddressType.p2pkInP2sh:
        if (isTaproot) {
          return senderPub.toP2pkInP2sh().toScriptPubKey();
        }
        return senderPub.toRedeemScript();
    }
    throw ArgumentError("invalid bitcoin address type");
  }

  /// generateTransactionDigest generates and returns a transaction digest for a given input in the context of a Bitcoin
  /// transaction. The digest is used for signing the transaction input. The function takes into account whether the
  /// associated UTXO is Segregated Witness (SegWit) or Pay-to-Taproot (P2TR), and it computes the appropriate digest
  /// based on these conditions.
//
  /// Parameters:
  /// - scriptPubKeys: representing the scriptPubKey for the transaction output being spent.
  /// - input: An integer indicating the index of the input being processed within the transaction.
  /// - utox: A UtxoWithAddress instance representing the unspent transaction output (UTXO) associated with the input.
  /// - transaction: A BtcTransaction representing the Bitcoin transaction being constructed.
  /// - taprootAmounts: A List of BigInt containing taproot-specific amounts for P2TR inputs (ignored for non-P2TR inputs).
  /// - tapRootPubKeys: A List of of Script representing taproot public keys for P2TR inputs (ignored for non-P2TR inputs).
//
  /// Returns:
  /// - List<int>: representing the transaction digest to be used for signing the input.
  List<int> _generateTransactionDigest(
      Script scriptPubKeys,
      int input,
      UtxoWithAddress utox,
      BtcTransaction transaction,
      List<BigInt> taprootAmounts,
      List<Script> tapRootPubKeys) {
    if (utox.utxo.isSegwit()) {
      if (utox.utxo.isP2tr()) {
        return transaction.getTransactionTaprootDigset(
          txIndex: input,
          scriptPubKeys: tapRootPubKeys,
          amounts: taprootAmounts,
        );
      }
      return transaction.getTransactionSegwitDigit(
          txInIndex: input, script: scriptPubKeys, amount: utox.utxo.value);
    }
    return transaction.getTransactionDigest(
        txInIndex: input, script: scriptPubKeys);
  }

  /// buildP2wshOrP2shScriptSig constructs and returns a script signature (represented as a List of strings)
  /// for a Pay-to-Witness-Script-Hash (P2WSH) or Pay-to-Script-Hash (P2SH) input. The function combines the
  /// signed transaction digest with the script details of the multi-signature address owned by the UTXO owner.
  //
  /// Parameters:
  /// - signedDigest: A List of strings containing the signed transaction digest elements.
  /// - utx: A UtxoWithAddress instance representing the unspent transaction output (UTXO) and its owner details.
  //
  /// Returns:
  /// - List<String>: A List of strings representing the script signature for the P2WSH or P2SH input.
  List<String> _buildMiltisigUnlockingScript(
      List<String> signedDigest, UtxoWithAddress utx) {
    /// The constructed script signature consists of the signed digest elements followed by
    /// the script details of the multi-signature address.

    return ['', ...signedDigest, utx.multiSigAddress.multiSigScript.toHex()];
  }

  /// buildP2shSegwitRedeemScriptSig constructs and returns a script signature (represented as a List of strings)
  /// for a Pay-to-Script-Hash (P2SH) Segregated Witness (SegWit) input. The function determines the script type
  /// based on the UTXO and UTXO owner details and creates the appropriate script signature.
  //
  /// Parameters:
  /// - utxo: A UtxoWithAddress instance representing the unspent transaction output (UTXO) and its owner details.
  //
  /// Returns:
  /// - List<string>: A List of strings representing the script signature for the P2SH SegWit input.
  List<String> _buildNestedSegwitReedemScript(UtxoWithAddress utxo) {
    if (utxo.isMultiSig()) {
      switch (utxo.utxo.scriptType) {
        case BitcoinAddressType.p2wshInP2sh:
          final script = Script.fromRaw(
              hexData: utxo.multiSigAddress.multiSigScript.toHex(),
              hasSegwit: true);
          final p2wsh = P2wshAddress.fromScript(script: script);
          return [p2wsh.toScriptPubKey().toHex()];
        default:
          throw Exception(
              "Invalid p2sh nested segwit type ${utxo.utxo.scriptType.value}");
      }
    }
    final senderPub = utxo.public();
    switch (utxo.utxo.scriptType) {
      case BitcoinAddressType.p2wshInP2sh:
        final script = senderPub.toP2wshAddress().toScriptPubKey();
        return [script.toHex()];
      case BitcoinAddressType.p2wpkhInP2sh:
        final script = senderPub.toSegwitAddress().toScriptPubKey();
        return [script.toHex()];
      default:
        throw Exception(
            "Invalid p2sh nested segwit type ${utxo.utxo.scriptType.value}");
    }
  }

/*
Unlocking Script (scriptSig): The scriptSig is also referred to as
the unlocking script because it provides data and instructions to unlock
a specific output. It contains information and cryptographic signatures
that demonstrate the right to spend the bitcoins associated with the corresponding scriptPubKey output.
*/
  List<String> _buildUnlockingScript(String signedDigest, UtxoWithAddress utx) {
    final senderPub = utx.public();
    if (utx.utxo.isSegwit()) {
      if (utx.utxo.isP2tr()) {
        return [signedDigest];
      }
      switch (utx.utxo.scriptType) {
        case BitcoinAddressType.p2wshInP2sh:
        case BitcoinAddressType.p2wsh:
          final script = senderPub.toP2wshScript();
          return ['', signedDigest, script.toHex()];
        case BitcoinAddressType.p2wpkh:
        case BitcoinAddressType.p2wpkhInP2sh:
          return [signedDigest, senderPub.toHex()];
        default:
          throw Exception(
              "invalid segwit address type ${utx.utxo.scriptType.value}");
      }
    } else {
      switch (utx.utxo.scriptType) {
        case BitcoinAddressType.p2pk:
          return [signedDigest];
        case BitcoinAddressType.p2pkh:
          return [signedDigest, senderPub.toHex()];
        case BitcoinAddressType.p2pkhInP2sh:
          final script = senderPub.toAddress().toScriptPubKey();
          return [signedDigest, senderPub.toHex(), script.toHex()];
        case BitcoinAddressType.p2pkInP2sh:
          final script = senderPub.toRedeemScript();
          return [signedDigest, script.toHex()];
        default:
          throw Exception("invalid address type ${utx.utxo.scriptType.value}");
      }
    }
  }

  List<TxInput> _buildInputs() {
    final sequence = enableRBF
        ? (Sequence(
                seqType: BitcoinOpCodeConst.TYPE_REPLACE_BY_FEE,
                value: 0,
                isTypeBlock: true))
            .forInputSequence()
        : null;
    final inputs = <TxInput>[];
    for (int i = 0; i < utxos.length; i++) {
      final e = utxos[i];
      inputs.add(TxInput(
          txId: e.utxo.txHash,
          txIndex: e.utxo.vout,
          sequance: i == 0 && enableRBF ? sequence : null));
    }
    return inputs;
  }

  List<TxOutput> _buildOutputs() {
    final outputs = <TxOutput>[];
    for (final e in outPuts) {
      outputs.add(
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()));
    }
    return outputs;
  }

  /// The primary use case for OP_RETURN is data storage. You can embed various types of
  /// data within the OP_RETURN output, such as text messages, document hashes, or metadata
  /// related to a transaction. This data is permanently recorded on the blockchain and can
  /// be retrieved by anyone who examines the blockchain's history.
  Script _opReturn(String message) {
    try {
      BytesUtils.fromHexString(message);
      return Script(script: ["OP_RETURN", message]);

      /// ignore: empty_catches
    } catch (e) {}
    final toBytes = utf8.encode(message);
    final toHex = BytesUtils.toHexString(toBytes);
    return Script(script: ["OP_RETURN", toHex]);
  }

  /// Total amount to spend excluding fees
  BigInt _sumOutputAmounts() {
    BigInt sum = BigInt.zero;
    for (final e in outPuts) {
      sum += e.value;
    }
    return sum;
  }

  String buildTrxPre() {
    /// build inputs
    final inputs = _buildInputs();

    /// build outout
    final outputs = _buildOutputs();

    /// check transaction is segwit
    final hasSegwit = _hasSegwit();

    /// check transaction is taproot
    _hasTaproot();

    /// check if you set memos or not
    if (memo != null) {
      outputs
          .add(TxOutput(amount: BigInt.zero, scriptPubKey: _opReturn(memo!)));
    }

    /// sum of amounts you filled in outputs
    final sumOutputAmounts = _sumOutputAmounts();

    /// sum of UTXOS amount
    final sumUtxoAmount = utxos.sumOfUtxosValue();

    /// sum of outputs amount + transcation fee
    final sumAmountsWithFee = (sumOutputAmounts + fee);

    /// We will check whether you have spent the correct amounts or not
    if (!isFakeTransaction && sumAmountsWithFee != sumUtxoAmount) {
      throw ArgumentError('Sum value of utxo not spending');
    }

    /// create new transaction with inputs and outputs and isSegwit transaction or not
    final transaction =
        BtcTransaction(inputs: inputs, outputs: outputs, hasSegwit: hasSegwit);
    return transaction.toHex();
  }

  String buildTrxSuf(String hex, List<String> sig) {
    /// check transaction is segwit
    final hasSegwit = _hasSegwit();

    /// check transaction is taproot
    final transaction = BtcTransaction.fromRaw(hex);
    final witnesses = <TxWitnessInput>[];

    /// Well, now let's do what we want for each input
    for (int i = 0; i < transaction.inputs.length; i++) {
      /// We receive the owner's ScriptPubKey

      /// handle multisig address
      if (utxos[i].isMultiSig()) {
        final multiSigAddress = utxos[i].multiSigAddress;
        int sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (int ownerIndex = 0;
            ownerIndex < multiSigAddress.signers.length;
            ownerIndex++) {
          /// now we need sign the transaction digest
          if (sig.isEmpty) continue;
          for (int weight = 0;
              weight < multiSigAddress.signers[ownerIndex].weight;
              weight++) {
            if (mutlsiSigSignatures.length >= multiSigAddress.threshold) {
              break;
            }
            mutlsiSigSignatures.add(sig[i]);
          }
          sumMultiSigWeight += multiSigAddress.signers[ownerIndex].weight;
          if (sumMultiSigWeight >= multiSigAddress.threshold) {
            break;
          }
        }
        if (sumMultiSigWeight != multiSigAddress.threshold) {
          throw StateError("some multisig signature does not exist");
        }
        _addUnlockScriptScript(
            hasSegwit: transaction.hasSegwit,
            input: transaction.inputs[i],
            signatures: mutlsiSigSignatures,
            utxo: utxos[i],
            witnesses: witnesses);
        continue;
      }
      _addUnlockScriptScript(
          hasSegwit: transaction.hasSegwit,
          input: transaction.inputs[i],
          signatures: [sig[i]],
          utxo: utxos[i],
          witnesses: witnesses);
    }

    /// ok we now check if the transaction is segwit We add all witnesses to the transaction
    if (hasSegwit) {
      // add all witnesses to the transaction
      for (final wit in witnesses) {
        transaction.addWitnesses(wit);
      }
    }

    return transaction.serialize();
  }

  BtcTransaction buildTransaction(BitcoinSignerCallBack sign) {
    /// build inputs
    final inputs = _buildInputs();

    /// build outout
    final outputs = _buildOutputs();

    /// check transaction is segwit
    final hasSegwit = _hasSegwit();

    /// check transaction is taproot
    final hasTaproot = _hasTaproot();

    /// check if you set memos or not
    if (memo != null) {
      outputs
          .add(TxOutput(amount: BigInt.zero, scriptPubKey: _opReturn(memo!)));
    }

    /// sum of amounts you filled in outputs
    final sumOutputAmounts = _sumOutputAmounts();

    /// sum of UTXOS amount
    final sumUtxoAmount = utxos.sumOfUtxosValue();

    /// sum of outputs amount + transaction fee
    final sumAmountsWithFee = (sumOutputAmounts + fee);

    /// We will check whether you have spent the correct amounts or not
    if (!isFakeTransaction && sumAmountsWithFee != sumUtxoAmount) {
      throw ArgumentError('Sum value of utxo not spending');
    }

    /// create new transaction with inputs and outputs and isSegwit transaction or not
    final transaction =
        BtcTransaction(inputs: inputs, outputs: outputs, hasSegwit: hasSegwit);

    /// we define empty witnesses. maybe the transaction is segwit and We need this
    final witnesses = <TxWitnessInput>[];

    /// when the transaction is taproot and we must use getTaproot transaction digest
    /// we need all of inputs amounts and owner script pub keys
    List<BigInt> taprootAmounts = [];
    List<Script> taprootScripts = [];

    if (hasTaproot) {
      taprootAmounts = utxos.map((e) => e.utxo.value).toList();
      taprootScripts = utxos.map((e) => _findLockingScript(e, true)).toList();
    }

    /// Well, now let's do what we want for each input
    for (int i = 0; i < inputs.length; i++) {
      /// We receive the owner's ScriptPubKey
      final script = _findLockingScript(utxos[i], false);

      /// We generate transaction digest for current input
      final digest = _generateTransactionDigest(
          script, i, utxos[i], transaction, taprootAmounts, taprootScripts);
      final int sighash = utxos[i].utxo.isP2tr()
          ? BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL
          : BitcoinOpCodeConst.SIGHASH_ALL;

      /// handle multisig address
      if (utxos[i].isMultiSig()) {
        final multiSigAddress = utxos[i].multiSigAddress;
        int sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (int ownerIndex = 0;
            ownerIndex < multiSigAddress.signers.length;
            ownerIndex++) {
          /// now we need sign the transaction digest
          final sig = sign(digest, utxos[i],
              multiSigAddress.signers[ownerIndex].publicKey, sighash);
          if (sig.isEmpty) continue;
          for (int weight = 0;
              weight < multiSigAddress.signers[ownerIndex].weight;
              weight++) {
            if (mutlsiSigSignatures.length >= multiSigAddress.threshold) {
              break;
            }
            mutlsiSigSignatures.add(sig);
          }
          sumMultiSigWeight += multiSigAddress.signers[ownerIndex].weight;
          if (sumMultiSigWeight >= multiSigAddress.threshold) {
            break;
          }
        }
        if (sumMultiSigWeight != multiSigAddress.threshold) {
          throw StateError("some multisig signature does not exist");
        }
        _addUnlockScriptScript(
            hasSegwit: hasSegwit,
            input: inputs[i],
            signatures: mutlsiSigSignatures,
            utxo: utxos[i],
            witnesses: witnesses);
        continue;
      }

      /// now we need sign the transaction digest
      final sig = sign(digest, utxos[i], utxos[i].public().toHex(), sighash);
      _addUnlockScriptScript(
          hasSegwit: hasSegwit,
          input: inputs[i],
          signatures: [sig],
          utxo: utxos[i],
          witnesses: witnesses);
    }

    /// ok we now check if the transaction is segwit We add all witnesses to the transaction
    if (hasSegwit) {
      // add all witnesses to the transaction
      for (final wit in witnesses) {
        transaction.addWitnesses(wit);
      }
    }

    return transaction;
  }

  /// add unlocking script to each input
  void _addUnlockScriptScript(
      {required UtxoWithAddress utxo,
      required TxInput input,
      required List<String> signatures,
      required List<TxWitnessInput> witnesses,
      required bool hasSegwit}) {
    /// ok we signed, now we need unlocking script for this input
    final scriptSig = utxo.isMultiSig()
        ? _buildMiltisigUnlockingScript(signatures, utxo)
        : _buildUnlockingScript(signatures.first, utxo);

    /// Now we need to add it to the transaction
    /// check if current utxo is segwit or not
    if (utxo.utxo.isSegwit()) {
      witnesses.add(TxWitnessInput(stack: scriptSig));
      if (utxo.utxo.isP2shSegwit()) {
        /// check if we need redeemScriptSig or not
        /// In a Pay-to-Script-Hash (P2SH) Segregated Witness (SegWit) input,
        /// the redeemScriptSig is needed for historical and compatibility reasons,
        /// even though the actual script execution has moved to the witness field (the witnessScript).
        /// This design choice preserves backward compatibility with older Bitcoin clients that do not support SegWit.
        final p2shSegwitScript = _buildNestedSegwitReedemScript(utxo);
        input.scriptSig = Script(script: p2shSegwitScript);
      }
    } else {
      /// ok input is not segwit and we use SetScriptSig to set the correct scriptSig
      input.scriptSig = Script(script: scriptSig);

      /// the concept of an "empty witness" is related to Segregated Witness (SegWit) transactions
      ///  and the way transaction data is structured. When a transaction input is not associated
      ///  with a SegWit UTXO, it still needs to be compatible with
      ///  the SegWit transaction format. This is achieved through the use of an "empty witness."
      if (hasSegwit) {
        witnesses.add(TxWitnessInput(stack: []));
      }
    }
  }
}
