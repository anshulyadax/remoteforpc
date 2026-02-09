import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:remote_protocol/remote_protocol.dart';
import 'screens/login_screen.dart';
import 'screens/connection_screen.dart';
import 'state/auth_state.dart';
import 'state/client_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Neon auth client
  await NeonRuntime.initialize(
    url: NeonAuthConfig.authUrl,
    anonKey: NeonAuthConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthState()),
        ChangeNotifierProvider(create: (_) => ClientState()),
      ],
      child: MaterialApp(
        title: 'RemoteForPC',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Wrapper to handle authentication state routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthState>(
      builder: (context, authState, _) {
        // Check if user is authenticated on app start
        final isAuthenticated = authState.isAuthenticated;

        // Show login screen if not authenticated, otherwise connection screen
        return isAuthenticated ? const ConnectionScreen() : const LoginScreen();
      },
    );
  }
}
