import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'drift/app_database.dart';
import 'services/sync_service.dart';
import 'screens/catalog_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional at runtime; the POS must work fully offline.
  String? firebaseUid;
  try {
    await Firebase.initializeApp();
    final credential = await FirebaseAuth.instance.signInAnonymously();
    firebaseUid = credential.user?.uid;
  } catch (e, st) {
    debugPrint('Firebase setup failed; running offline.\n$e\n$st');
  }

  await Hive.initFlutter();
  final deviceBox = await Hive.openBox<String>('device');
  var deviceId = deviceBox.get('deviceId');
  if (deviceId == null || deviceId.isEmpty) {
    deviceId = firebaseUid ?? const Uuid().v4();
    await deviceBox.put('deviceId', deviceId);
  }

  const businessId = 'default_business';
  final database = AppDatabase();

  final syncService = SyncService(
    database: database,
    firestore: FirebaseFirestore.instance,
    connectivity: Connectivity(),
    auth: FirebaseAuth.instance,
    businessId: businessId,
    deviceId: deviceId,
  );
  syncService.startPeriodicSync();

  runApp(KPosApp(
    database: database,
    syncService: syncService,
  ));
}

class KPosApp extends StatefulWidget {
  final AppDatabase database;
  final SyncService syncService;

  const KPosApp({
    super.key,
    required this.database,
    required this.syncService,
  });

  @override
  State<KPosApp> createState() => _KPosAppState();
}

class _KPosAppState extends State<KPosApp> {
  @override
  void dispose() {
    widget.syncService.stopPeriodicSync();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CatalogScreen(),
    );
  }
}
