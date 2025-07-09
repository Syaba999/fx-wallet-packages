// ignore_for_file: constant_identifier_names

import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/number/number_parser.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

import 'on_chain_transaction.dart';

class LedgerDepositPreauth {
  const LedgerDepositPreauth({required this.owner, required this.authorized});
  final String owner;
  final String authorized;

  Map<String, dynamic> toJson() {
    return {"owner": owner, "authorized": authorized};
  }
}

class LedgerDirectory {
  const LedgerDirectory(
      {required this.owner, required this.dirRoot, this.subIndex});
  final String owner;
  final String dirRoot;
  final int? subIndex;
  Map<String, dynamic> toJson() {
    return {
      "owner": owner,
      "dir_root": dirRoot,
      "sub_index": subIndex,
    };
  }
}

class LedgerEscrow {
  const LedgerEscrow({required this.owner, required this.seq});
  final String owner;
  final int seq;
  Map<String, dynamic> toJson() {
    return {
      "owner": owner,
      "seq": seq,
    };
  }
}

class LedgerOffer {
  const LedgerOffer({required this.account, required this.seq});
  final String account;
  final int seq;
  Map<String, dynamic> toJson() {
    return {
      "account": account,
      "seq": seq,
    };
  }
}

class LedgerRippleState {
  const LedgerRippleState({required this.currency, required this.accounts});
  final String currency;
  final List<String> accounts;

  Map<String, dynamic> toJson() {
    return {
      "currency": currency,
      "accounts": accounts,
    };
  }
}

class LedgerTicket {
  const LedgerTicket({required this.owner, required this.ticketSequence});
  final String owner;
  final int ticketSequence;

  Map<String, dynamic> toJson() {
    return {
      "owner": owner,
      "ticket_sequence": ticketSequence,
    };
  }
}

class LedgerXChainClaimID extends XChainBridge {
  LedgerXChainClaimID(
      {required String issuingChainDoor,
      required XRPCurrencies issuingChainIssue,
      required String lockingChainDoor,
      required XRPCurrencies lockingChainIssue,
      required this.xChainClaimId})
      : super(
            issuingChainDoor: issuingChainDoor,
            issuingChainIssue: issuingChainIssue,
            lockingChainDoor: lockingChainDoor,
            lockingChainIssue: lockingChainIssue);
  final int xChainClaimId;

  @override
  Map<String, dynamic> toJson() {
    final toJs = super.toJson();
    toJs["xchain_claim_id"] = xChainClaimId;

    return toJs;
  }
}

class LedgerXChainCreateAccountClaimID extends XChainBridge {
  LedgerXChainCreateAccountClaimID(
      {required String issuingChainDoor,
      required XRPCurrencies issuingChainIssue,
      required String lockingChainDoor,
      required XRPCurrencies lockingChainIssue,
      required this.xChainCreateAccountClaimId})
      : super(
            issuingChainDoor: issuingChainDoor,
            issuingChainIssue: issuingChainIssue,
            lockingChainDoor: lockingChainDoor,
            lockingChainIssue: lockingChainIssue);
  final int xChainCreateAccountClaimId;

  @override
  Map<String, dynamic> toJson() {
    final toJs = super.toJson();
    toJs["xchain_create_account_claim_id"] = xChainCreateAccountClaimId;

    return toJs;
  }
}

class LedgerData {
  final String? accountHash;
  final int closeFlags;
  final int closeTime;
  final String closeTimeHuman;
  final int closeTimeResolution;
  final bool closed;

  final String ledgerHash;
  final int ledgerIndex;
  final int parentCloseTime;
  final String parentHash;
  final int? seqNum;
  final BigInt totalCoins;
  final List<TransactionData> transactions;

  final String transactionHash;

  const LedgerData(
      {required this.accountHash,
      required this.closeFlags,
      required this.closeTime,
      required this.closeTimeHuman,
      required this.closeTimeResolution,
      required this.closed,
      required this.ledgerHash,
      required this.ledgerIndex,
      required this.parentCloseTime,
      required this.parentHash,
      required this.seqNum,
      required this.totalCoins,
      required this.transactionHash,
      required this.transactions});

  factory LedgerData.fromJson(Map<String, dynamic> json) {
    return LedgerData(
        accountHash: json['ledger']['account_hash'],
        closeFlags: parseInt(json['ledger']['close_flags'])!,
        closeTime: parseInt(json['ledger']['close_time'])!,
        closeTimeHuman: json['ledger']['close_time_human'],
        closeTimeResolution: parseInt(json['ledger']['close_time_resolution'])!,
        closed: json['ledger']['closed'],
        ledgerHash: json['ledger']['ledger_hash'],
        ledgerIndex: parseInt(json['ledger']['ledger_index'])!,
        parentCloseTime: parseInt(json['ledger']['parent_close_time'])!,
        parentHash: json['ledger']['parent_hash'],
        seqNum: parseInt(json['ledger']['seqNum']),
        totalCoins: parseBigInt(json['ledger']['total_coins'])!,
        transactionHash: json['ledger']['transaction_hash'],
        transactions: (json['ledger']["transactions"] as List?)
                ?.map((e) => TransactionData.fromJson(e))
                .toList() ??
            <TransactionData>[]);
  }
}
