# WorkFlow – Proje Tanımı

> Bu dosya projenin asıl gereksinim belgesidir. Kararlar değiştikçe güncellenir.

## 1. Proje nedir?
WorkFlow, bir kurumdaki personelin gün içinde hangi bölümde olduğunu QR kod ile takip eden bir Flutter mobil uygulamasıdır (Android ve iOS). Bölümler yönetici tarafından adlandırılıp eklenir (örnek: A Bölümü, B Bölümü, C Bölümü, Yemekhane), yani uygulama fabrika, ofis, okul gibi yapılarda kullanılabilir. Her bölümün kapısına o bölüme ait TEK bir QR kod (kâğıt çıktı) asılır. Çalışan bu kodu uygulamadan okutur; sistem kişinin durumuna göre giriş veya çıkış kaydı oluşturur. Yönetici, kimin nerede olduğunu, bölüm bazlı kişi sayılarını ve bir personelin gün içindeki hareketlerini görür.

## 2. Teknoloji
- Flutter / Dart
- Firebase Authentication (e-posta + şifre) ve Cloud Firestore (gerçek zamanlı veri, `snapshots()` + `StreamBuilder`)
- Git ve GitHub (her adımda anlamlı Türkçe commit mesajı)
- QR okuma: mobile_scanner, QR üretme: qr_flutter, PDF: pdf + printing. Paket sürümleri pub.dev'den kontrol edilir.
- Ayrı sunucu veya Cloud Functions YOK (ücretsiz plan). Tüm doğrulama Firestore güvenlik kuralları ve transaction ile yapılır.
- Durum yönetimi basit kalsın (Provider veya sade StatefulWidget + Stream). Gereksiz katman yok.

## 3. Roller
İki rol var: `personel` ve `yonetici`. Tek uygulama, giriş yapanın rolüne göre alt menü değişir.
- Kayıt olan herkes `personel` olur. Yönetici rolü uygulamadan verilemez, Firebase konsolunda elle atanır. Kullanıcı kendi rolünü değiştiremez.
- Personel alt menüsü: Ana Sayfa, QR Tara, Geçmiş, Profil.
- Yönetici alt menüsü: Ana Sayfa, QR Tara, Yönetim, Geçmiş, Profil. "Yönetim" sekmesine yalnızca yönetici erişebilir. Yönetici personelin yaptığı her şeyi de yapabilir.

## 4. Ekranlar
Tüm arayüz metinleri Türkçe. Tasarım sade, kurumsal, yuvarlatılmış beyaz kartlar, hafif gölge. Renkler: lacivert #101B35 (ana), mavi #2563EB (vurgu/buton), arka plan #F4F6FA, kart beyaz, başarı yeşili #15803D, hata kırmızısı #DC2626, uyarı turuncusu #F59E0B. Butonlar en az 44-52 px yüksekliğinde. Profil fotoğrafı yok, baş harfli avatar.

**Giriş / Kayıt:** WorkFlow logosu, "Fabrika personel takip sistemi" alt yazısı, e-posta, şifre, şifreyi göster/gizle, Giriş Yap butonu, Hesap oluştur bağlantısı (ad soyad, görev, e-posta, şifre). Slogan: "Doğru İnsan, Doğru Bölüm, Daha Verimli Üretim." Oturum açık kalsın.

**Personel – Ana Sayfa:** Lacivert başlıkta avatar, ad soyad, görev. "Şu Anki Bölümünüz" kartı: bölüm adı, kaç saatten beri içeride, "İçeride" rozeti; bölümde değilse "Şu an hiçbir bölümde değilsiniz". Üç küçük kart: bugünkü hareket sayısı, son okutma saati, çalışma durumu. Büyük "QR Okut (giriş / çıkış)" butonu. "Son Hareketleriniz" listesi (saat, bölüm, Giriş/Çıkış rozeti).

**QR Tara:** Sekmeye basınca kamera doğrudan açılır. Tarama çerçevesi, flaş ve geri butonu, "Bölüm QR kodunu okutun", "Giriş mi çıkış mı olduğu mevcut durumunuza göre otomatik belirlenir". SADECE canlı kamera, galeriden seçme YOK. Okutunca onay beklemeden kaydedilir, tam ekran sonuç (2-3 sn, titreşim):
- Giriş: yeşil, "A Bölümüne hoş geldiniz", "Giriş kaydedildi · 09:12", "Çıkış için aynı QR kodu tekrar okutun."
- Çıkış: mavi, "A Bölümünden çıkış yapıldı"
- Otomatik çıkış: "A'dan çıkış, B'ye giriş yapıldı"
- Hata: kırmızı, nedeni yazılı (geçersiz QR, bölüm pasif, internet yok vb.)

**Geçmiş (personel):** Dikey zaman çizelgesi. Filtre: Bugün, Bu hafta, Bu ay. Her kayıtta saat, bölüm, tür (Giriş/Çıkış/Otomatik çıkış).

**Profil:** Ad soyad, görev, rol, e-posta, Şifre Değiştir, Çıkış Yap.

**Yönetim sekmesi (yönetici)**, 4 alt sekme:
- Genel: "Toplam personel" ve "Aktif personel" kartları; "Bölüm Durumu" yatay çubuklar; "Son Hareketler"; "Sistem aktif" ve tarih-saat.
- Personeller: arama, bölüme göre filtre (Tümü + bölümler, yatay kaydırma), liste: ad soyad, bölüm, son giriş saati, durum rozeti.
- Bölümler: kartlar (ad, kişi sayısı, son okutma saati), "QR Kodu" butonu, en altta "Bölüm Ekle". QR ekranı: bölüm adı + büyük QR + "PDF olarak indir / yazdır". Yeni bölüm kaydedilince QR ekranı otomatik açılır. Bölümler SİLİNMEZ, "pasif" yapılır.
- Hareketler: personel seçici, filtre (Bugün, Dün, Bu hafta, Tarih seç), dikey zaman çizelgesi ve toplam çalışma süresi.

## 5. QR içeriği ve PDF
- QR içeriği: `workflow:bolum:<bolumId>`. Bölüm adı değişse de QR geçerli kalır. Önek yoksa veya bölüm yok/pasifse "Geçersiz QR".
- PDF: A4, büyük bölüm adı, büyük vektör QR, altında "Giriş ve çıkış için okutun". Türkçe karakterler için font gömülür. Paylaşma sistem menüsüyle (depolama izni yok).

## 6. Giriş / çıkış mantığı
Karar `suAnkiBolumId` değerine göre:
1. Boş → GİRİŞ.
2. Okutulan bölümle aynı → ÇIKIŞ.
3. Başka bölüm → OTOMATİK ÇIKIŞ + GİRİŞ.
- Tek Firestore transaction/batch.
- Zaman `FieldValue.serverTimestamp()`.
- Aynı bölüm ~10 sn içinde tekrar okutulursa yeni kayıt yok.
- Çıkış unutulursa: girişin üzerinden 9 saat geçince kişi otomatik çıkmış sayılır; çıkış kaydı "giriş + 9 saat" zamanıyla, kişinin kendi uygulaması tarafından (açılışta, açıkken her dakika veya bir sonraki QR okutmasında) yazılır. Yönetici ekranları süresi dolan kişiyi hemen "Dışarıda" gösterir.

## 7. Veri yapısı (Firestore)
- `kullanicilar/{uid}`: adSoyad, eposta, gorev, rol, suAnkiBolumId, suAnkiBolumAdi, girisZamani.
- `bolumler/{bolumId}`: ad, aktif.
- `hareketler/{id}`: kullaniciId, kullaniciAdi, bolumId, bolumAdi, tur ("giris"/"cikis"/"otomatik_cikis"), zaman.

## 8. Güvenlik kuralları
- Giriş yapmamış kimse okuyamaz/yazamaz.
- Personel yalnızca kendi kullanıcı dokümanını okur; yalnızca suAnkiBolum* ve girisZamani alanlarını günceller; rolü değiştiremez. Kayıtta rol yalnızca "personel".
- Personel hareketlere yalnızca kendi kullaniciId'siyle ekler, yalnızca kendininkileri okur; silemez/değiştiremez.
- Yönetici her şeyi okur, bölüm ekler/günceller. Yönetici rol alanından anlaşılır.
- `bolumler`: giriş yapan herkes okur, yalnızca yönetici yazar.
- Test modunda bırakılmaz.

## 9. Şimdilik YAPILMAYACAKLAR
GPS, cihaz bağlama, push bildirim, profil fotoğrafı, mola sayaçları, şüpheli kayıt, şifremi unuttum, tarih aralığı seçici, çoklu kurum, NFC/Bluetooth.

## 10. 7 günlük plan
1. Flutter + Firebase + Git kurulumu, kayıt/giriş
2. Roller, alt menü iskeleti, personel ana sayfası
3. QR okutma ve giriş/çıkış mantığı
4. Personel Geçmiş ve Profil
5. Yönetici Bölümler (ekle, QR, PDF) ve Personeller
6. Yönetici Hareketler ve Genel + güvenlik kuralları
7. Test ve hata düzeltme

Test senaryoları: geçersiz QR, pasif bölüm, internet kesintisi, kamera izni reddi, çıkışı unutma, aynı QR'ı art arda okutma, personelin yönetici verisine erişmeye çalışması.
