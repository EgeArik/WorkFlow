import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ekranlar/ana_iskelet.dart';
import 'ekranlar/giris_ekrani.dart';
// flutterfire configure komutunun ürettiği dosya: Firebase proje bilgilerini içerir.
import 'firebase_options.dart';
import 'modeller/kullanici.dart';
import 'servisler/auth_servisi.dart';
import 'servisler/veri_servisi.dart';
import 'tema.dart';

// main(): uygulama açıldığında çalışan ilk fonksiyon.
// "async" yazdık çünkü içinde Firebase'in hazır olmasını "await" ile bekliyoruz.
Future<void> main() async {
  // Flutter motorunu runApp'ten önce hazırlar; Firebase başlatmadan önce gerekli.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i bu telefonun platformuna (Android/iOS) uygun ayarlarla başlatır.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      // Uygulama dili Türkçe: tarih seçici, "İptal/Tamam" gibi hazır yazılar Türkçe görünür.
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const OturumKapisi(),
    );
  }
}

// 1. kapı: kullanıcı giriş yapmış mı? Yapmadıysa Giriş ekranı.
// Firebase oturumu telefonda saklar; uygulama kapanıp açılsa da oturum açık kalır.
class OturumKapisi extends StatelessWidget {
  const OturumKapisi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthServisi().oturumDegisiklikleri,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final kullanici = snapshot.data;
        if (kullanici == null) return const GirisEkrani();
        // ValueKey: farklı bir hesapla girilirse eski kullanıcının ekranı yeniden kullanılmasın.
        return KullaniciYukleyici(
          key: ValueKey(kullanici.uid),
          uid: kullanici.uid,
        );
      },
    );
  }
}

// 2. kapı: giriş yapan kişinin Firestore'daki bilgilerini (ad, rol, bölüm) canlı yükler
// ve rolüne uygun alt menülü iskeleti açar. Konsoldan rol değişirse menü anında değişir.
class KullaniciYukleyici extends StatefulWidget {
  final String uid;
  const KullaniciYukleyici({super.key, required this.uid});

  @override
  State<KullaniciYukleyici> createState() => _KullaniciYukleyiciState();
}

class _KullaniciYukleyiciState extends State<KullaniciYukleyici> {
  late final Stream<Kullanici?> _akis;

  @override
  void initState() {
    super.initState();
    _akis = VeriServisi().kullaniciAkisi(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Kullanici?>(
      stream: _akis,
      builder: (context, snapshot) {
        final kullanici = snapshot.data;
        if (kullanici != null) return AnaIskelet(kullanici: kullanici);

        // Bilgiler henüz gelmedi (ör. kayıt yeni yapıldı) ya da bir hata oluştu.
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Kullanıcı bilgileri yüklenemedi.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
                const SizedBox(height: 24),
                // Takılı kalınırsa kullanıcı çıkış yapıp tekrar deneyebilsin.
                TextButton(
                  onPressed: () => AuthServisi().cikisYap(),
                  child: const Text('Çıkış Yap'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
