import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/neurobot_controller.dart';
import 'controllers/vocal_controller.dart';
import 'services/ai_service.dart';
import 'services/navigation_service.dart';
import 'services/tts_service.dart';
import 'services/voice_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NeuroLinkApp());
}

class NeuroLinkApp extends StatelessWidget {
  const NeuroLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<VoiceService>(create: (_) => VoiceService()),
        Provider<TtsService>(create: (_) => TtsService()),
        Provider<AiService>(create: (_) => AiService()),
        Provider<NavigationService>(create: (_) => NavigationService()),
        ChangeNotifierProvider<NeurobotController>(
          create: (context) => NeurobotController(
            aiService: context.read<AiService>(),
            ttsService: context.read<TtsService>(),
          ),
        ),
        ChangeNotifierProvider<VocalController>(
          create: (context) => VocalController(
            voiceService: context.read<VoiceService>(),
            ttsService: context.read<TtsService>(),
            navigationService: context.read<NavigationService>(),
            neurobotController: context.read<NeurobotController>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'NeuroLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
