import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shenai_sdk/pigeon.dart';
import 'package:shenai_sdk/shenai_sdk.dart';
import 'package:shenai_sdk/shenai_view.dart';

const apiKey = String.fromEnvironment('SHENAI_API_KEY');
const userId = String.fromEnvironment(
  'SHENAI_USER_ID',
  defaultValue: 'ce-flutter-minimal-example',
);
const language = String.fromEnvironment('SHENAI_LANGUAGE', defaultValue: 'en');
void main() => runApp(const CeMinimalApp());

class CeMinimalApp extends StatelessWidget {
  const CeMinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CeMinimalScreen(),
    );
  }
}

class CeMinimalScreen extends StatefulWidget {
  const CeMinimalScreen({super.key});

  @override
  State<CeMinimalScreen> createState() => _CeMinimalScreenState();
}

class _CeMinimalScreenState extends State<CeMinimalScreen> {
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    if (_initialized) {
      unawaited(ShenaiSdk.deinitialize());
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    if (apiKey.isEmpty) {
      setState(() => _error = 'Missing SHENAI_API_KEY');
      return;
    }

    final result = await ShenaiSdk.initialize(
      apiKey,
      userId,
      settings: InitializationSettings(
        initializationMode: InitializationMode.measurement,
      ),
    );

    if (result == InitializationResult.success) {
      await ShenaiSdk.setLanguage(language);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _initialized = result == InitializationResult.success;
      _error = _initialized ? null : 'Initialization failed: $result';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(body: ShenaiView());
  }
}
