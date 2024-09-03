import 'package:Satsails/models/transfer_model.dart';
import 'package:Satsails/models/user_model.dart';
import 'package:Satsails/providers/liquid_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

final FlutterSecureStorage _storage = const FlutterSecureStorage();

final initializeUserProvider = FutureProvider<User>((ref) async {
  final box = await Hive.openBox('user');
  final affiliateCode = box.get('affiliateCode', defaultValue: '');
  final hasInsertedAffiliate = box.get('hasInsertedAffiliate', defaultValue: false);
  final hasCreatedAffiliate = box.get('hasCreatedAffiliate', defaultValue: false);
  final paymentId = box.get('paymentId', defaultValue: '');
  final recoveryCode = await _storage.read(key: 'recoveryCode') ?? '';
  final onboarded = box.get('onboarding', defaultValue: false);

  return User(affiliateCode: affiliateCode, hasInsertedAffiliate: hasInsertedAffiliate, hasCreatedAffiliate: hasCreatedAffiliate, recoveryCode: recoveryCode, paymentId: paymentId, onboarded: onboarded);
});

final userProvider = StateNotifierProvider<UserModel, User>((ref) {
  final initialUser = ref.watch(initializeUserProvider);

  return UserModel(initialUser.when(
    data: (user) => user,
    loading: () => User(
      affiliateCode: '',
      hasInsertedAffiliate: false,
      hasCreatedAffiliate: false,
      recoveryCode: '',
      paymentId: '',
      onboarded: false,
    ),
    error: (Object error, StackTrace stackTrace) {
      throw error;
    },
  ));
});


final createUserProvider = FutureProvider.autoDispose<void>((ref) async {
  final liquidAddress = await ref.read(liquidAddressProvider.future);
  final user = await UserService.createUserRequest(liquidAddress.confidential);
  await ref.watch(userProvider.notifier).setPaymentId(user.paymentId);
  await ref.watch(userProvider.notifier).setRecoveryCode(user.recoveryCode);
});

final getUserTransactionsProvider = FutureProvider.autoDispose<List<Transfer>>((ref) async {
  final paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  return await UserService.getUserTransactions(paymentId, auth);
});

final getAmountTransferredProvider = FutureProvider.autoDispose<String>((ref) async {
  final paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  return await UserService.getAmountTransferred(paymentId, auth);
});

final addAffiliateCodeProvider = FutureProvider.autoDispose.family<void, String>((ref, affiliateCode) async {
  var paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  await UserService.addAffiliateCode(paymentId, affiliateCode, auth);
  ref.read(userProvider.notifier).sethasInsertedAffiliate(true);
  ref.read(userProvider.notifier).setAffiliateCode(affiliateCode);
});

final createAffiliateCodeProvider = FutureProvider.autoDispose.family<void, Affiliate>((ref, affiliate) async {
  var paymentId = ref.read(userProvider).paymentId;
  final auth = ref.read(userProvider).recoveryCode;
  await UserService.createAffiliateCode(paymentId, affiliate.code, affiliate.liquidAddress, auth);
  ref.read(userProvider.notifier).setHasCreatedAffiliate(true);
  await ref.read(userProvider.notifier).setAffiliateCode(affiliate.code);
});

final numberOfAffiliateInstallsProvider = FutureProvider.autoDispose<int>((ref) async {
  final affiliateCode = ref.watch(userProvider).affiliateCode ?? '';
  final auth = ref.read(userProvider).recoveryCode;
  return await UserService.affiliateNumberOfUsers(affiliateCode, auth);
});

final affiliateEarningsProvider = FutureProvider.autoDispose<String>((ref) async {
  final affiliateCode = ref.watch(userProvider).affiliateCode ?? '';
  final auth = ref.read(userProvider).recoveryCode;
  return await UserService.affiliateEarnings(affiliateCode, auth);
});

final updateLiquidAddressProvider = FutureProvider.autoDispose<String>((ref) async {
  final liquidAddress = await ref.read(liquidAddressProvider.future);
  final auth = ref.read(userProvider).recoveryCode;
  return await UserService.updateLiquidAddress(liquidAddress.confidential, auth);
});

final setUserProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.read(updateLiquidAddressProvider.future);
  final auth = ref.read(userProvider).recoveryCode;
  User user = await UserService.showUser(auth);
  ref.read(userProvider.notifier).setPaymentId(user.paymentId);
  ref.read(userProvider.notifier).setRecoveryCode(user.recoveryCode);
  ref.read(userProvider.notifier).setAffiliateCode(user.affiliateCode ?? '');
});