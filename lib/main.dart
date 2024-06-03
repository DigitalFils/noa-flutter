import 'package:audio_session/audio_session.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:noa/bluetooth.dart';
import 'package:noa/pages/splash.dart';
import 'package:noa/util/app_log.dart';

final globalPageStorageBucket = PageStorageBucket();

void main() async {
  // Load environment variables
  await dotenv.load();

  // Start logging
  final container = ProviderContainer();
  container.read(appLog);

  // Request bluetooth permission
  BrilliantBluetooth.requestPermission();

  setupAudioSession();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MainApp(),
  ));
}

void setupAudioSession() {
  AudioSession.instance.then((audioSession) async {
    await audioSession.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    audioSession.setActive(true);
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashPage(),
    );
  }
}
