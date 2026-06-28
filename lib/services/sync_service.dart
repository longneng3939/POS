import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../drift/app_database.dart';

/// Cloud sync orchestrator.
///
/// SQLite/Drift remains the source of truth on the device. Firestore is only
/// used to upload local transactions and download product catalog changes.
class SyncService {
  SyncService({
    required this.database,
    required this.firestore,
    required this.connectivity,
    required this.auth,
    required this.businessId,
    required this.deviceId,
  });

  final AppDatabase database;
  final FirebaseFirestore firestore;
  final Connectivity connectivity;
  final FirebaseAuth auth;
  final String businessId;
  final String deviceId;

  Timer? _syncTimer;

  /// Returns true if the device reports any connectivity other than none.
  Future<bool> isOnline() async {
    try {
      final results = await connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e, st) {
      log('SyncService: connectivity check failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// Upload every local transaction that has not yet been synced.
  Future<void> syncUpTransactions() async {
    try {
      final query = database.select(database.transactions)
        ..where((t) => t.synced.equals(false));
      final rows = await query.get();

      for (final tx in rows) {
        final itemsQuery = database.select(database.transactionItems)
          ..where((i) => i.transactionId.equals(tx.id));
        final items = await itemsQuery.get();

        final itemsData = items
            .map((i) => {
                  'productId': i.productId,
                  'productName': i.productName,
                  'priceAtSale': i.priceAtSale,
                  'quantity': i.quantity,
                  'subtotal': i.subtotal,
                })
            .toList();

        final docRef = firestore
            .collection('businesses')
            .doc(businessId)
            .collection('transactions')
            .doc(tx.uuid);

        await docRef.set({
          'uuid': tx.uuid,
          'totalAmount': tx.totalAmount,
          'taxAmount': tx.taxAmount,
          'discountAmount': tx.discountAmount,
          'paymentMethod': tx.paymentMethod,
          'status': tx.status,
          'createdAt': Timestamp.fromDate(tx.createdAt),
          'deviceId': deviceId,
          'items': itemsData,
          'syncedAt': FieldValue.serverTimestamp(),
        });

        await (database.update(database.transactions)
              ..where((t) => t.id.equals(tx.id)))
            .write(const TransactionsCompanion(synced: Value(true)));
      }
    } catch (e, st) {
      log('SyncService: syncUpTransactions failed', error: e, stackTrace: st);
    }
  }

  /// Download product catalog updates from Firestore and upsert into Drift,
  /// never overwriting local rows that are newer than the remote row.
  Future<void> syncDownProducts() async {
    try {
      final snapshot = await firestore
          .collection('businesses')
          .doc(businessId)
          .collection('products')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final remoteUuid = data['uuid'] as String?;
        final remoteUpdatedAt = _parseTimestamp(data['updatedAt']);
        if (remoteUuid == null || remoteUpdatedAt == null) continue;

        final localQuery = database.select(database.products)
          ..where((p) => p.uuid.equals(remoteUuid));
        final local = await localQuery.getSingleOrNull();

        if (local != null && local.updatedAt.isAfter(remoteUpdatedAt)) {
          continue;
        }

        final entity = ProductsCompanion(
          uuid: Value(remoteUuid),
          name: Value((data['name'] as String?) ?? ''),
          category: Value((data['category'] as String?) ?? ''),
          price: Value(((data['price'] as num?) ?? 0).toDouble()),
          stock: Value((data['stock'] as int?) ?? 0),
          barcode: Value(data['barcode'] as String?),
          isActive: Value((data['isActive'] as bool?) ?? true),
          updatedAt: Value(remoteUpdatedAt),
        );

        if (local != null) {
          await (database.update(database.products)
                ..where((p) => p.id.equals(local.id)))
              .write(entity.copyWith(id: Value(local.id)));
        } else {
          await database.into(database.products).insert(entity);
        }
      }
    } catch (e, st) {
      log('SyncService: syncDownProducts failed', error: e, stackTrace: st);
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Runs an up-sync followed by a down-sync. Each phase is isolated so a
  /// failure in one does not prevent the other from running.
  Future<void> syncAll() async {
    if (!await isOnline()) return;
    try {
      await syncUpTransactions();
    } catch (e, st) {
      log('SyncService: syncUpTransactions error', error: e, stackTrace: st);
    }
    try {
      await syncDownProducts();
    } catch (e, st) {
      log('SyncService: syncDownProducts error', error: e, stackTrace: st);
    }
  }

  /// Starts a 30-second background timer that syncs when online.
  void startPeriodicSync() {
    stopPeriodicSync();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (await isOnline()) {
        await syncAll();
      }
    });
  }

  /// Cancels the background sync timer.
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
