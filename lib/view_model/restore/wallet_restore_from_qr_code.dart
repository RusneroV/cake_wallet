import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';

class WalletRestoreFromQRCode {
  WalletRestoreFromQRCode();

  static Future<RestoredWallet> scanQRCodeForRestoring(BuildContext context) async {
    final code = await presentQRScanner();
    Map<String, dynamic> credentials = {};

    if (code.isEmpty) {
      throw Exception('Unexpected scan QR code value: value is empty');
    }
    final formattedUrl = code.replaceFirst('_', '');
    final uri = Uri.parse(formattedUrl);
    credentials['type'] = getWalletTypeFromUrl(uri.scheme);
    credentials['address'] = getAddressFromUrl(
      type: credentials['type'] as WalletType,
      address: uri.path,
    );
    uri.queryParameters.forEach((k, v) {
      credentials[k] = v;
    });
    credentials['mode'] = getWalletRestoreMode(credentials);

    return RestoredWallet.fromJson(credentials);
  }

  static WalletType getWalletTypeFromUrl(String scheme) {
    switch (scheme) {
      case 'monerowallet':
        return WalletType.monero;
      case 'bitcoinwallet':
        return WalletType.bitcoin;
      case 'litecoinwallet':
        return WalletType.litecoin;
      default:
        throw Exception('Unexpected wallet type: ${scheme.toString()}');
    }
  }

  static String getAddressFromUrl({required WalletType type, required String address}) {
    final addressPattern = AddressValidator.getPattern(walletTypeToCryptoCurrency(type));
    final match = RegExp(addressPattern).hasMatch(address);
    return match
        ? address
        : throw Exception('Unexpected wallet address: address is invalid'
            'or does not match the type ${type.toString()}');
  }

  static WalletRestoreMode getWalletRestoreMode(Map<String, dynamic> credentials) {
    if (credentials.containsKey('mnemonic_seed')) {
      //TODO implement seed validation
      final seedValue = credentials['mnemonic_seed'];
      if (seedValue is String) {
        return seedValue.isNotEmpty
            ? WalletRestoreMode.seed
            : throw Exception('Unexpected restore mode: mnemonic_seed is invalid');
      }
    }
    if (credentials.containsKey('spend_key') && credentials.containsKey('view_key')) {
      final spendKey = credentials['spend_key'];
      final viewKey = credentials['view_key'];
      if (spendKey is String && viewKey is String) {
        return spendKey.isNotEmpty && viewKey.isNotEmpty
            ? WalletRestoreMode.keys
            : throw Exception('Unexpected restore mode: spend_key or view_key is invalid');
      }
    }
    throw Exception('Unexpected restore mode: restore params are invalid');
  }
}
