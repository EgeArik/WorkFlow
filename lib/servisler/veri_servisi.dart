import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeller/hareket.dart';
import '../modeller/kullanici.dart';

// Firestore'dan veri OKUYAN fonksiyonlar burada toplanır.
// Hepsi Stream döndürür: veritabanında bir şey değişince ekran kendiliğinden güncellenir.
class VeriServisi {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Bir kullanıcının dokümanını canlı dinler.
  // map(): akıştan gelen her ham dokümanı Kullanici nesnesine çevirir.
  // Doküman yoksa (ör. kayıt yeni yapıldı, henüz yazılmadı) null gönderir.
  Stream<Kullanici?> kullaniciAkisi(String uid) {
    return _db
        .collection('kullanicilar')
        .doc(uid)
        .snapshots()
        .map(
          (dokuman) => dokuman.exists ? Kullanici.firestoredan(dokuman) : null,
        );
  }

  // Kullanıcının BUGÜNKÜ hareketleri (Ana Sayfa için).
  Stream<List<Hareket>> bugunkuHareketlerAkisi(String uid) {
    final simdi = DateTime.now();
    return hareketlerAkisi(
      uid,
      DateTime(simdi.year, simdi.month, simdi.day),
    ); // bugün 00:00
  }

  // Kullanıcının "baslangic" anından sonraki hareketleri, en yenisi en üstte.
  // Geçmiş ekranındaki Bugün / Bu hafta / Bu ay filtreleri bunu farklı başlangıçlarla çağırır.
  // Not: bu sorgu "kullaniciId + zaman" bileşik indeksi ister (firestore.indexes.json).
  Stream<List<Hareket>> hareketlerAkisi(String uid, DateTime baslangic) {
    return _db
        .collection('hareketler')
        .where('kullaniciId', isEqualTo: uid)
        .where('zaman', isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
        .orderBy('zaman', descending: true)
        .snapshots()
        .map((sorgu) => sorgu.docs.map(Hareket.firestoredan).toList());
  }
}
