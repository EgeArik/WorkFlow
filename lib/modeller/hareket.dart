import 'package:cloud_firestore/cloud_firestore.dart';

// Bir giriş/çıkış kaydı. Firestore'daki "hareketler" koleksiyonunun bir dokümanı.
class Hareket {
  final String id;
  final String kullaniciId;
  final String kullaniciAdi;
  final String bolumId;
  final String bolumAdi;
  final String tur; // "giris", "cikis" veya "otomatik_cikis"
  // Zaman sunucu tarafından yazılır (serverTimestamp). Kayıt yeni eklendiği o kısa anda
  // telefonda henüz sunucu saati gelmemiş olabilir; bu yüzden null olabilir.
  final DateTime? zaman;

  const Hareket({
    required this.id,
    required this.kullaniciId,
    required this.kullaniciAdi,
    required this.bolumId,
    required this.bolumAdi,
    required this.tur,
    this.zaman,
  });

  factory Hareket.firestoredan(DocumentSnapshot<Map<String, dynamic>> dokuman) {
    final veri = dokuman.data()!;
    return Hareket(
      id: dokuman.id,
      kullaniciId: veri['kullaniciId'] as String? ?? '',
      kullaniciAdi: veri['kullaniciAdi'] as String? ?? '',
      bolumId: veri['bolumId'] as String? ?? '',
      bolumAdi: veri['bolumAdi'] as String? ?? '',
      tur: veri['tur'] as String? ?? 'giris',
      zaman: (veri['zaman'] as Timestamp?)?.toDate(),
    );
  }

  bool get girisMi => tur == 'giris';

  // Ekranda gösterilecek Türkçe ad.
  String get turEtiketi {
    switch (tur) {
      case 'giris':
        return 'Giriş';
      case 'cikis':
        return 'Çıkış';
      case 'otomatik_cikis':
        return 'Otomatik çıkış';
      default:
        return tur;
    }
  }
}
