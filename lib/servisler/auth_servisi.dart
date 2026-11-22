import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Servis: ekranlardan ayrı tutulan, Firebase ile konuşan kodların toplandığı sınıf.
// Ekranlar sadece "girisYap" der; Firebase'in nasıl çağrıldığını bilmek zorunda kalmaz.
class AuthServisi {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream: zamanla yeni değerler gönderen veri akışı.
  // Kullanıcı giriş/çıkış yaptıkça bu akış yeni değer (User veya null) gönderir.
  Stream<User?> get oturumDegisiklikleri => _auth.authStateChanges();

  Future<void> girisYap({required String eposta, required String sifre}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: eposta.trim(),
        password: sifre,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(_turkceMesaj(e.code));
    }
  }

  // Kayıt iki adımdır: 1) Firebase Authentication hesabı, 2) Firestore'da kullanıcı dokümanı.
  Future<void> kayitOl({
    required String adSoyad,
    required String gorev,
    required String eposta,
    required String sifre,
  }) async {
    final UserCredential sonuc;
    try {
      sonuc = await _auth.createUserWithEmailAndPassword(
        email: eposta.trim(),
        password: sifre,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthHatasi(_turkceMesaj(e.code));
    }

    final kullanici = sonuc.user!;
    try {
      // Doküman kimliği = kullanıcının uid'si. Böylece "kullanicilar/{uid}" ile kolayca buluruz.
      // Rol her zaman "personel"; yönetici rolü Firebase konsolundan elle verilir.
      await _db.collection('kullanicilar').doc(kullanici.uid).set({
        'adSoyad': adSoyad.trim(),
        // Firebase e-postayı küçük harfle saklar; güvenlik kuralı ikisinin aynı olmasını ister.
        'eposta': eposta.trim().toLowerCase(),
        'gorev': gorev.trim(),
        'rol': 'personel',
        'suAnkiBolumId': null,
        'suAnkiBolumAdi': null,
        'girisZamani': null,
      });
    } catch (_) {
      // Doküman yazılamadıysa yarım hesap kalmasın diye Authentication hesabını da sileriz.
      await kullanici.delete();
      throw AuthHatasi(
        'Hesap bilgileri kaydedilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<void> cikisYap() => _auth.signOut();

  // Şifre değiştirme. Firebase güvenlik gereği önce MEVCUT şifreyle kimliği tekrar doğrular
  // (reauthenticate). Böylece telefonu açık bırakılan biri başkası tarafından şifresini değiştiremez.
  Future<void> sifreDegistir({
    required String mevcutSifre,
    required String yeniSifre,
  }) async {
    final kullanici = _auth.currentUser;
    final eposta = kullanici?.email;
    if (kullanici == null || eposta == null)
      throw AuthHatasi('Oturum bulunamadı.');
    try {
      // credential: "bu e-posta ve şifre" bilgisini taşıyan kimlik belgesi.
      final kimlik = EmailAuthProvider.credential(
        email: eposta,
        password: mevcutSifre,
      );
      await kullanici.reauthenticateWithCredential(kimlik);
      await kullanici.updatePassword(yeniSifre);
    } on FirebaseAuthException catch (e) {
      // Bu ekranda "şifre hatalı" mesajı mevcut şifre için olmalı.
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthHatasi('Mevcut şifre hatalı.');
      }
      throw AuthHatasi(_turkceMesaj(e.code));
    }
  }

  // Firebase'in İngilizce hata kodlarını kullanıcıya gösterilecek Türkçe mesajlara çevirir.
  String _turkceMesaj(String kod) {
    switch (kod) {
      case 'invalid-email':
        return 'E-posta adresi geçersiz.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta ile zaten bir hesap var.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar deneyin.';
      default:
        return 'Bir hata oluştu ($kod).';
    }
  }
}

// Kendi hata sınıfımız: ekranlar bunu yakalayıp içindeki Türkçe mesajı gösterir.
class AuthHatasi implements Exception {
  final String mesaj;
  AuthHatasi(this.mesaj);
}
