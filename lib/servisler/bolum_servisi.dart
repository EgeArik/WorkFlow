import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeller/bolum.dart';

// Bölümleri listeleme ve ekleme. Yazma işlemlerine güvenlik kuralı gereği sadece yönetici izinli.
class BolumServisi {
  final _bolumler = FirebaseFirestore.instance.collection('bolumler');

  // Tüm bölümler, ada göre alfabetik sırayla, canlı.
  Stream<List<Bolum>> bolumlerAkisi() {
    return _bolumler
        .orderBy('ad')
        .snapshots()
        .map((sorgu) => sorgu.docs.map(Bolum.firestoredan).toList());
  }

  // Yeni bölüm ekler ve oluşan bölümü döndürür.
  // add(): Firestore rastgele bir doküman kimliği üretir; bu kimlik QR'a girecek.
  Future<Bolum> bolumEkle(String ad) async {
    final temizAd = ad.trim();
    final ref = await _bolumler.add({'ad': temizAd, 'aktif': true});
    return Bolum(id: ref.id, ad: temizAd, aktif: true);
  }

  // Bölümü pasif yapar veya tekrar aktif yapar (Gün 7). Bölümler silinmez;
  // pasif bölüme giriş yapılamaz ama eski kayıtlar ve QR kodu bozulmaz.
  // update(): sadece verilen alanı değiştirir, diğer alanlara dokunmaz.
  Future<void> aktiflikDegistir(Bolum bolum, bool aktif) {
    return _bolumler.doc(bolum.id).update({'aktif': aktif});
  }
}
