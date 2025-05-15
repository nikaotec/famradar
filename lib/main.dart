// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'di/di.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = DI.createAppProvider();
    return ChangeNotifierProvider.value(
      value: appProvider,
      child: MaterialApp.router(
        routerConfig: router,
        title: 'FamRadar',
        theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      ),
    );
  }
}
