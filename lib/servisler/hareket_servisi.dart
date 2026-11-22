import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeller/bolum.dart';
import '../modeller/kullanici.dart';

// Okutmanın sonucu ne oldu? enum: sabit seçeneklerden oluşan tür.
enum OkutmaTuru { giris, cikis, gecis }

// Sonuç ekranında gösterilecek bilgiler.
class OkutmaSonucu {
  final OkutmaTuru tur;
  final String bolumAdi; // okutulan bölüm
  final String? eskiBolumAdi; // sadece "geçiş"te: otomatik çıkış yapılan bölüm
  final DateTime zaman;

  const OkutmaSonucu({
    required this.tur,
    required this.bolumAdi,
    this.eskiBolumAdi,
    required this.zaman,
  });
}

// Okutma reddedildiğinde fırlatılan hata; mesajı sonuç ekranında kırmızı gösterilir.
class OkutmaHatasi implements Exception {
  final String mesaj;
  final bool
  bilgi; // true ise hata değil bilgi (ör. çift okutma): turuncu gösterilir
  OkutmaHatasi(this.mesaj, {this.bilgi = false});
}

// PROJENİN KALBİ: QR okutunca giriş / çıkış / otomatik çıkış kararı ve kaydı.
class HareketServisi {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Çift okutma koruması için son okutmayı hafızada tutarız.
  // "static": tüm HareketServisi nesneleri aynı değişkeni paylaşır; ekran kapanıp açılsa da kaybolmaz.
  static String? _sonBolumId;
  static DateTime? _sonOkutmaZamani;
  static const _ciftOkutmaSuresi = Duration(seconds: 10);

  Future<OkutmaSonucu> qrOkut({
    required String qrMetni,
    required String uid,
  }) async {
    // 1) QR bizim mi? Önek yoksa reddet.
    if (!qrMetni.startsWith(qrOneki)) {
      throw OkutmaHatasi('Geçersiz QR. Bu bir WorkFlow bölüm kodu değil.');
    }
    final bolumId = qrMetni.substring(qrOneki.length).trim();
    if (bolumId.isEmpty || bolumId.contains('/')) {
      throw OkutmaHatasi('Geçersiz QR.');
    }

    // 2) Çift okutma: aynı bölüm 10 saniye içinde tekrar okutulduysa kayıt yapma.
    final simdi = DateTime.now();
    if (_sonBolumId == bolumId &&
        _sonOkutmaZamani != null &&
        simdi.difference(_sonOkutmaZamani!) < _ciftOkutmaSuresi) {
      throw OkutmaHatasi(
        'Bu QR az önce okutuldu. Tekrar kayıt yapılmadı.',
        bilgi: true,
      );
    }

    final kullaniciRef = _db.collection('kullanicilar').doc(uid);
    final bolumRef = _db.collection('bolumler').doc(bolumId);
    final hareketler = _db.collection('hareketler');

    try {
      // 3) TRANSACTION: içindeki tüm okuma/yazmalar "ya hepsi ya hiçbiri" çalışır.
      // Başka biri aynı anda veriyi değiştirirse Firestore işlemi baştan tekrar dener.
      final sonuc = await _db.runTransaction<OkutmaSonucu>((tx) async {
        final kullaniciDok = await tx.get(kullaniciRef);
        final bolumDok = await tx.get(bolumRef);

        if (!bolumDok.exists) {
          throw OkutmaHatasi('Geçersiz QR. Böyle bir bölüm yok.');
        }
        final bolum = Bolum.firestoredan(bolumDok);
        if (!bolum.aktif) {
          throw OkutmaHatasi('${bolum.ad} pasif durumda. Okutma yapılamaz.');
        }

        final kullanici = Kullanici.firestoredan(kullaniciDok);
        final suAnkiId = kullanici.suAnkiBolumId;

        // Her hareket kaydında ortak olan alanlar. Zaman SUNUCUDAN alınır.
        Map<String, dynamic> hareketVerisi(
          String bId,
          String bAd,
          String tur,
        ) => {
          'kullaniciId': uid,
          'kullaniciAdi': kullanici.adSoyad,
          'bolumId': bId,
          'bolumAdi': bAd,
          'tur': tur,
          'zaman': FieldValue.serverTimestamp(),
        };

        // DURUM A: hiçbir bölümde değil -> GİRİŞ
        if (suAnkiId == null) {
          tx.set(hareketler.doc(), hareketVerisi(bolum.id, bolum.ad, 'giris'));
          tx.update(kullaniciRef, {
            'suAnkiBolumId': bolum.id,
            'suAnkiBolumAdi': bolum.ad,
            'girisZamani': FieldValue.serverTimestamp(),
          });
          return OkutmaSonucu(
            tur: OkutmaTuru.giris,
            bolumAdi: bolum.ad,
            zaman: simdi,
          );
        }

        // DURUM B: zaten bu bölümde -> ÇIKIŞ
        if (suAnkiId == bolum.id) {
          tx.set(hareketler.doc(), hareketVerisi(bolum.id, bolum.ad, 'cikis'));
          tx.update(kullaniciRef, {
            'suAnkiBolumId': null,
            'suAnkiBolumAdi': null,
            'girisZamani': null,
          });
          return OkutmaSonucu(
            tur: OkutmaTuru.cikis,
            bolumAdi: bolum.ad,
            zaman: simdi,
          );
        }

        // DURUM C: başka bölümde -> eskisinden OTOMATİK ÇIKIŞ + yenisine GİRİŞ
        final eskiAd = kullanici.suAnkiBolumAdi ?? '';
        tx.set(
          hareketler.doc(),
          hareketVerisi(suAnkiId, eskiAd, 'otomatik_cikis'),
        );
        tx.set(hareketler.doc(), hareketVerisi(bolum.id, bolum.ad, 'giris'));
        tx.update(kullaniciRef, {
          'suAnkiBolumId': bolum.id,
          'suAnkiBolumAdi': bolum.ad,
          'girisZamani': FieldValue.serverTimestamp(),
        });
        return OkutmaSonucu(
          tur: OkutmaTuru.gecis,
          bolumAdi: bolum.ad,
          eskiBolumAdi: eskiAd,
          zaman: simdi,
        );
      });

      // Başarılı okutmayı hatırla (çift okutma koruması için).
      _sonBolumId = bolumId;
      _sonOkutmaZamani = simdi;
      return sonuc;
    } on FirebaseException catch (e) {
      // Firebase'in hata kodlarını Türkçe mesaja çevir.
      if (e.code == 'unavailable') {
        throw OkutmaHatasi(
          'İnternet bağlantısı yok. Kayıt yapılmadı, tekrar deneyin.',
        );
      }
      if (e.code == 'permission-denied') {
        throw OkutmaHatasi('Bu işlem için yetkiniz yok veya QR geçersiz.');
      }
      throw OkutmaHatasi('Kayıt yapılamadı (${e.code}).');
    }
  }

  // ÇIKIŞI UNUTMA: önceki günden açık kayıt kaldıysa sessizce otomatik çıkış yapar.
  // Kapatılan bölümün adını döndürür; kapatılacak bir şey yoksa null.
  // Kayıt zamanı TAHMİNİDİR: girişten 8 saat sonra (bir mesai günü), ama giriş gününün
  // 23:59'unu geçmez. Gerçek çıkış saatini Gün 6'da yönetici düzeltebilecek.
  static const tahminiMesai = Duration(hours: 8);

  Future<String?> eskiAcikKaydiKapat(Kullanici kullanici) async {
    final giris = kullanici.girisZamani;
    final suAnkiId = kullanici.suAnkiBolumId;
    if (suAnkiId == null || giris == null) return null;

    final simdi = DateTime.now();
    final bugunBaslangic = DateTime(simdi.year, simdi.month, simdi.day);
    if (!giris.isBefore(bugunBaslangic)) {
      return null; // giriş bugün yapılmış, sorun yok
    }

    // Tahmini çıkış: giriş + 8 saat; giriş günü 23:59'u geçerse 23:59.
    final gunSonu = DateTime(giris.year, giris.month, giris.day, 23, 59);
    var tahminiCikis = giris.add(tahminiMesai);
    if (tahminiCikis.isAfter(gunSonu)) tahminiCikis = gunSonu;

    final bolumAdi = kullanici.suAnkiBolumAdi ?? '';
    // Batch: transaction gibi "ya hepsi ya hiçbiri", ama önce okuma yapmaz; sadece yazar.
    final batch = _db.batch();
    batch.set(_db.collection('hareketler').doc(), {
      'kullaniciId': kullanici.uid,
      'kullaniciAdi': kullanici.adSoyad,
      'bolumId': suAnkiId,
      'bolumAdi': bolumAdi,
      'tur': 'otomatik_cikis',
      // Sunucu saati değil, hesapladığımız geçmiş zaman. Güvenlik kuralı buna yalnızca
      // otomatik çıkışta ve "giriş ile giriş+8 saat arası" olduğunda izin verir.
      'zaman': Timestamp.fromDate(tahminiCikis),
    });
    batch.update(_db.collection('kullanicilar').doc(kullanici.uid), {
      'suAnkiBolumId': null,
      'suAnkiBolumAdi': null,
      'girisZamani': null,
    });
    await batch.commit();
    return bolumAdi;
  }
}
