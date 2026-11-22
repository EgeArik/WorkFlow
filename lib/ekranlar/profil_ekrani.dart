import 'package:flutter/material.dart';

import '../modeller/kullanici.dart';
import '../servisler/auth_servisi.dart';
import '../tema.dart';
import '../widgetlar/bas_harf_avatar.dart';
import 'sifre_degistir_ekrani.dart';

// Profil sekmesi: bilgiler, Şifre Değiştir ve Çıkış Yap.
class ProfilEkrani extends StatelessWidget {
  final Kullanici kullanici;

  const ProfilEkrani({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: kartDekorasyonu(),
            child: Column(
              children: [
                BasHarfAvatar(harfler: kullanici.basHarfler, boyut: 72),
                const SizedBox(height: 12),
                Text(
                  kullanici.adSoyad,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _bilgiSatiri(Icons.work_outline, 'Görev', kullanici.gorev),
                _bilgiSatiri(
                  Icons.badge_outlined,
                  'Rol',
                  kullanici.yoneticiMi ? 'Yönetici' : 'Personel',
                ),
                _bilgiSatiri(Icons.email_outlined, 'E-posta', kullanici.eposta),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // OutlinedButton: çerçeveli, içi boş buton (ikincil işlem olduğunu belli eder).
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SifreDegistirEkrani()),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.key),
            label: const Text('Şifre Değiştir'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => AuthServisi().cikisYap(),
            style: ElevatedButton.styleFrom(backgroundColor: Renkler.hata),
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  // Tekrar eden satır görünümünü bir fonksiyona aldık: ikon + başlık + değer.
  Widget _bilgiSatiri(IconData ikon, String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(ikon, color: Renkler.griYazi, size: 20),
          const SizedBox(width: 12),
          Text(baslik, style: const TextStyle(color: Renkler.griYazi)),
          const SizedBox(width: 16),
          // Expanded: satırda kalan TÜM genişliği değere verir; metin sağa yaslanır.
          Expanded(
            child: Text(
              deger,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
