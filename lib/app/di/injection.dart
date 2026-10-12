import 'package:get_it/get_it.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/account_repository.dart';
import 'package:finance_tracker/features/transactions/data/transaction_repository.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) return;

  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<TransferRepository>(
    () => TransferRepository(getIt<AppDatabase>()),
  );
}
