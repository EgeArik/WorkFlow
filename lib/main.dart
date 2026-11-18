import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// flutterfire configure komutunun ürettiği dosya: Firebase proje bilgilerini içerir.
import 'firebase_options.dart';

// main(): uygulama açıldığında çalışan ilk fonksiyon.
// "async" yazdık çünkü içinde Firebase'in hazır olmasını "await" ile bekliyoruz.
Future<void> main() async {
  // Flutter motorunu runApp'ten önce hazırlar; Firebase başlatmadan önce gerekli.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i bu telefonun platformuna (Android/iOS) uygun ayarlarla başlatır.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WorkFlowApp());
}

class WorkFlowApp extends StatelessWidget {
  const WorkFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkFlow',
      debugShowCheckedModeBanner: false, // sağ üstteki "DEBUG" şeridini gizler
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const FirebaseTestEkrani(),
    );
  }
}

// Geçici test ekranı: Firebase bağlantısının çalıştığını gösterir.
// Bir sonraki adımda yerini Giriş ekranı alacak.
class FirebaseTestEkrani extends StatelessWidget {
  const FirebaseTestEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase.app() başlatılmış uygulamayı verir; projectId ile hangi projeye bağlı olduğumuzu görürüz.
    final projeKimligi = Firebase.app().options.projectId;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 72),
            const SizedBox(height: 16),
            const Text(
              'Firebase bağlantısı hazır',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Proje: $projeKimligi'),
          ],
        ),
      ),
    );
  }
}
