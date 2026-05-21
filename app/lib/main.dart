import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/parking_provider.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const ParkSmartApp());
}

class ParkSmartApp extends StatelessWidget {
  const ParkSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParkingProvider(),
      child: MaterialApp(
        title: 'ParkSmart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF060B14),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF64FFDA),
            surface: Color(0xFF0D1421),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
