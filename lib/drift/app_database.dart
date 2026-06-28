import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  TextColumn get barcode => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => const [
        'UNIQUE (uuid)',
      ];
}

@DataClassName('PosTransaction')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  RealColumn get totalAmount => real()();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => const [
        'UNIQUE (uuid)',
      ];
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get priceAtSale => real()();
  IntColumn get quantity => integer()();
  RealColumn get subtotal => real()();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  RealColumn get totalSpent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => const [
        'UNIQUE (uuid)',
      ];
}

class Staff extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get hashedPin => text()();
  TextColumn get role => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DriftDatabase(tables: [Products, Transactions, TransactionItems, Customers, Staff])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();

          // Performance indexes for common POS queries.
          await customStatement('CREATE INDEX idx_products_uuid ON products(uuid);');
          await customStatement('CREATE INDEX idx_products_category ON products(category);');
          await customStatement('CREATE INDEX idx_products_barcode ON products(barcode);');
          await customStatement('CREATE INDEX idx_transactions_uuid ON transactions(uuid);');
          await customStatement('CREATE INDEX idx_transactions_synced ON transactions(synced);');
          await customStatement(
              'CREATE INDEX idx_transaction_items_transaction_id ON transaction_items(transaction_id);');
          await customStatement('CREATE INDEX idx_customers_uuid ON customers(uuid);');
          await customStatement('CREATE INDEX idx_staff_name ON staff(name);');
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File('${dbFolder.path}/k_pos.sqlite');
      return NativeDatabase.createInBackground(file, logStatements: true);
    });
  }
}
