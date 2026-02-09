import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:window_manager/window_manager.dart';
import 'package:remote_protocol/remote_protocol.dart';
import 'screens/home_screen.dart';
import 'state/server_state.dart';
import 'state/auth_state.dart' as app_state;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager for desktop
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(400, 300),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'RemoteForPC Server',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
        ChangeNotifierProvider(create: (_) => app_state.AuthState()),
        ChangeNotifierProvider(create: (_) => ServerState()),
      ],
      child: MaterialApp(
        title: 'RemoteForPC Server',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
