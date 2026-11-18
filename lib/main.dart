import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'ekranlar/gecici_ana_sayfa.dart';
import 'ekranlar/giris_ekrani.dart';
// flutterfire configure komutunun ürettiği dosya: Firebase proje bilgilerini içerir.
import 'firebase_options.dart';
import 'servisler/auth_servisi.dart';
import 'tema.dart';

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
      theme: uygulamaTemasi(),
      home: const OturumKapisi(),
    );
  }
}

// Oturum kapısı: kullanıcı giriş yapmış mı bakar ve doğru ekranı gösterir.
// Firebase oturumu telefonda saklar; uygulama kapanıp açılsa da oturum açık kalır.
class OturumKapisi extends StatelessWidget {
  const OturumKapisi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthServisi().oturumDegisiklikleri,
      builder: (context, snapshot) {
        // Firebase oturumu kontrol ederken kısa bir an yükleniyor göster.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // snapshot.data: giriş yapmış kullanıcı (yoksa null).
        if (snapshot.data == null) return const GirisEkrani();
        return const GeciciAnaSayfa();
      },
    );
  }
}
