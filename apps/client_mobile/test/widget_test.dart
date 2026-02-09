import 'package:flutter_test/flutter_test.dart';
import 'package:remote_protocol/remote_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:client_mobile/main.dart';

Future<void> _ensureSupabaseInitialized() async {
  try {
    Supabase.instance.client;
    return;
  } catch (_) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _ensureSupabaseInitialized();
  });

  testWidgets('shows login UI when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('RemoteForPC'), findsOneWidget);
    expect(find.text('Control your computer remotely'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
}
