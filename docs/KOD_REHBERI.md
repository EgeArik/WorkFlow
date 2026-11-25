# Kod Rehberi

Bu belge, projedeki her dosyanın ne işe yaradığını sade bir dille anlatır. Her gün yeni dosyalar eklendikçe güncellenir.

## Klasör yapısı

```
lib/
├── main.dart                 Uygulamanın giriş noktası ve "kapılar"
├── firebase_options.dart     Firebase bağlantı ayarları (otomatik üretildi, elle değiştirilmez)
├── tema.dart                 Renkler, kart görünümü, buton/yazı alanı stilleri
├── modeller/                 Firestore verisini Dart nesnelerine çeviren sınıflar
│   ├── kullanici.dart
│   └── hareket.dart
├── servisler/                Firebase ile konuşan kodlar
│   ├── auth_servisi.dart     Giriş, kayıt, çıkış
│   ├── veri_servisi.dart     Firestore'dan canlı veri okuma
│   ├── hareket_servisi.dart  QR okutma: giriş/çıkış/geçiş (transaction)
│   ├── bolum_servisi.dart    Bölüm listeleme ve ekleme
│   └── pdf_servisi.dart      Bölüm QR'ı için A4 PDF
├── ekranlar/                 Tam sayfa ekranlar
│   ├── giris_ekrani.dart
│   ├── kayit_ekrani.dart
│   ├── ana_iskelet.dart      Alt menü + sekmeler
│   ├── ana_sayfa.dart
│   ├── profil_ekrani.dart
│   └── yonetim/              Yönetim sekmesi (alt sekmeler, personeller, bölümler, QR)
├── widgetlar/                Birden çok ekranda kullanılan küçük parçalar
│   ├── workflow_logo.dart
│   ├── bas_harf_avatar.dart
│   ├── rozet.dart
│   └── yakinda_ekrani.dart
└── yardimcilar/
    └── zaman_bicimi.dart     Saat ve süre yazdırma fonksiyonları

firestore.rules               Veritabanı güvenlik kuralları
firestore.indexes.json        Veritabanı sorgu indeksleri
```

**Neden bu şekilde ayırdık?** Ekran kodu (görünüm) ile veritabanı kodu (servis) ayrı olunca, bir ekranı değiştirirken Firebase kodunu bozma riskimiz olmaz; bir Firebase işlemini de tek yerden düzeltiriz.

---

## Temel kavramlar

| Kavram | Bir cümlede |
|---|---|
| **Widget** | Ekranda görünen her parça (yazı, buton, kutu, sayfa) bir widget'tır; widget'lar iç içe geçerek ekranı oluşturur. |
| **StatelessWidget** | İçinde değişen bilgi tutmayan widget; verilen bilgiyi sadece gösterir. |
| **StatefulWidget** | İçinde değişen bilgi (ör. "yükleniyor mu?") tutan widget; `setState()` ile ekranı yeniden çizer. |
| **build()** | Widget'ın ekranda nasıl görüneceğini tarif eden fonksiyon. |
| **async / await** | İnternetten cevap gibi zaman alan işlerde "bekle, sonra devam et" demenin yolu. |
| **Future** | İleride gelecek tek bir sonuç (ör. giriş işleminin bitmesi). |
| **Stream** | Zamanla tekrar tekrar gelen sonuçlar (ör. veritabanındaki bir dokümanın her değişikliği). |
| **StreamBuilder** | Bir Stream'i dinleyen ve her yeni veride ekranı yeniden çizen widget. |
| **Model** | Ham veriyi (Map) `kullanici.adSoyad` gibi düzenli kullanılabilen bir nesneye çeviren sınıf. |
| **null / `?`** | "Değer yok" demek. `String?` = metin olabilir de, boş (null) da olabilir. |

---

## Gün 1 dosyaları

### `main.dart`
- **`main()`**: Uygulama açılınca ilk çalışan fonksiyon. Önce Firebase'i başlatır (`Firebase.initializeApp`), sonra uygulamayı ekrana çizer (`runApp`).
- **`WorkFlowApp`**: Uygulamanın kökü. Temayı ve ilk ekranı (`OturumKapisi`) belirler.
- **`OturumKapisi`** (1. kapı): Firebase Authentication'ı dinler. Giriş yapılmamışsa `GirisEkrani`, yapılmışsa `KullaniciYukleyici` gösterilir. Firebase oturumu telefonda sakladığı için uygulama kapanıp açılınca tekrar giriş istemez.
- **`KullaniciYukleyici`** (2. kapı, Gün 2): Giriş yapan kişinin Firestore'daki bilgilerini (ad, görev, rol, bölüm) canlı dinler ve hazır olunca `AnaIskelet`'i açar. Bilgiler henüz gelmediyse yükleniyor dairesi ve "Çıkış Yap" düğmesi gösterir.

### `tema.dart`
- **`Renkler`**: Tasarımdaki tüm renkler (lacivert, mavi, yeşil, kırmızı...). Bir rengi değiştirmek için sadece burayı değiştirmek yeterli.
- **`kartDekorasyonu()`**: Beyaz, köşeleri yuvarlatılmış, hafif gölgeli kart görünümü. Tüm kartlar bunu kullanır.
- **`uygulamaTemasi()`**: Butonların (52 px yükseklik, mavi) ve yazı alanlarının (beyaz, yuvarlak kenar) varsayılan görünümü. Böylece her ekranda tek tek stil yazmayız.

### `servisler/auth_servisi.dart`
- **`girisYap()`**: E-posta ve şifreyle Firebase Authentication'a giriş yapar.
- **`kayitOl()`**: İki adımda çalışır: (1) Authentication'da hesap açar, (2) Firestore'da `kullanicilar/{uid}` dokümanını `rol: "personel"` ile oluşturur. İkinci adım başarısız olursa yarım hesap kalmasın diye birinci adımda açılan hesabı siler.
- **`cikisYap()`**: Oturumu kapatır. `OturumKapisi` bunu fark edip giriş ekranını açar.
- **`_turkceMesaj()`**: Firebase'in İngilizce hata kodlarını ("wrong-password" vb.) Türkçe mesajlara çevirir.
- **`AuthHatasi`**: Kendi hata sınıfımız; ekranlar bunu yakalayıp içindeki mesajı kırmızı uyarı olarak gösterir.

### `ekranlar/giris_ekrani.dart`
- **`Form` + `GlobalKey<FormState>`**: Tüm alanları tek seferde kontrol etmeyi sağlar (`validate()`).
- **`TextEditingController`**: Yazı alanına yazılanı okumamızı sağlar. Ekran kapanınca `dispose()` ile serbest bırakılır.
- **`validator`**: Alan boşsa veya e-postada `@` yoksa hata yazısı döndürür; `null` dönerse alan geçerlidir.
- **`_sifreGizli`**: Göz ikonuna basınca değişir, şifre görünür/gizli olur.
- **`_yukleniyor`**: Giriş sürerken butonu kapatır ve içinde dönen daire gösterir (iki kez basılmasın diye).
- **`mounted`**: Ekranın hâlâ açık olup olmadığını kontrol eder; kapanmış ekranda `setState` çağırmak hata verir.

### `ekranlar/kayit_ekrani.dart`
Giriş ekranıyla aynı mantık; dört alan (ad soyad, görev, e-posta, şifre) var. Şifre en az 6 karakter olmalı (Firebase'in kuralı). Kayıt başarılı olunca ekran kapanır (`Navigator.pop`) ve oturum kapısı ana sayfayı açar.

### `widgetlar/workflow_logo.dart`
Giriş ve kayıt ekranlarında ortak kullanılan logo, "WorkFlow" yazısı ve "Personel takip sistemi" alt yazısı.

### `firestore.rules`
Veritabanının güvenlik kuralları. Burada izin verilmeyen her şey yasaktır. Ayrıntılar için [VERITABANI.md](VERITABANI.md).

---

## Gün 2 dosyaları

### `modeller/kullanici.dart`
- **`Kullanici`**: `kullanicilar` koleksiyonundaki bir dokümanın Dart hâli (adSoyad, eposta, gorev, rol, suAnkiBolumId, suAnkiBolumAdi, girisZamani).
- **`Kullanici.firestoredan()`**: Firestore dokümanından `Kullanici` nesnesi üretir. Alan eksikse `??` ile varsayılan değer koyar; Firestore'un `Timestamp` zamanını `toDate()` ile Dart'ın `DateTime`'ına çevirir.
- **`yoneticiMi`**, **`icerideMi`**: Getter'lar; saklanmaz, her okunduğunda hesaplanır (`rol == 'yonetici'`, `suAnkiBolumId != null`).
- **`basHarfler`**: "Ege Arık" → "EA". Avatar için.
- **`turkceBuyukHarf()`**: Dart'ın `toUpperCase()` fonksiyonu `i` harfini `I` yapar; Türkçede `İ` olmalı. Bu fonksiyon bunu düzeltir.

### `modeller/hareket.dart`
- **`Hareket`**: Bir giriş/çıkış kaydı (kim, hangi bölüm, tür, zaman).
- **`zaman` neden null olabilir?** Zamanı telefon değil sunucu yazar (`serverTimestamp`). Kayıt eklendiği o kısa anda telefona henüz sunucu saati ulaşmamış olabilir.
- **`turEtiketi`**: `giris` → "Giriş", `cikis` → "Çıkış", `otomatik_cikis` → "Otomatik çıkış".

### `servisler/veri_servisi.dart`
- **`kullaniciAkisi(uid)`**: Kullanıcının dokümanını canlı dinler. `.map()` ile her gelen dokümanı `Kullanici` nesnesine çevirir.
- **`bugunkuHareketlerAkisi(uid)`**: Kullanıcının bugün 00:00'dan sonraki hareketlerini, en yenisi üstte olacak şekilde canlı dinler. Bu sorgu iki alana birden (kullaniciId ve zaman) baktığı için Firestore'da **bileşik indeks** ister; indeks `firestore.indexes.json` dosyasında tanımlı.

### `ekranlar/ana_iskelet.dart`
- Alt menü (`NavigationBar`) ve seçili sekmenin ekranı.
- **`_sekmeleriOlustur()`**: Sekme listesini kurar. `if (k.yoneticiMi)` satırı sayesinde **Yönetim** sekmesi sadece yöneticide listeye eklenir. Personel: 4 sekme, yönetici: 5 sekme.
- **`_seciliSira`**: Hangi sekmenin açık olduğu (0 = ilk). Menüye basınca `setState` ile değişir.
- **`clamp()`**: Rol canlı değişir ve sekme sayısı azalırsa, seçili sıra listenin dışına taşmasın diye sınırlar.
- **`_qrSekmesineGec()`**: Ana sayfadaki "QR Okut" butonu bu fonksiyonu çağırır ve QR Tara sekmesine geçilir.

### `ekranlar/ana_sayfa.dart`
- **`_Baslik`**: Lacivert üst alan; baş harfli avatar, ad soyad, görev. `SafeArea` ile telefonun saat/çentik alanının altında kalmaz.
- **`_BolumKarti`**: "Şu Anki Bölümünüz". Kişi bir bölümdeyse bölüm adı, "09:12'den beri · 2 sa 30 dk" ve yeşil "İçeride" rozeti; değilse "Şu an hiçbir bölümde değilsiniz". İçinde her dakika çalışan bir **`Timer`** var; süre yazısı kendiliğinden güncellenir. Ekran kapanınca `dispose()` içinde durdurulur.
- **`_kucukKartlar()`**: Üç küçük kart: bugünkü hareket sayısı, son okutma saati, durum (Çalışıyor/Dışarıda). `Expanded` sayesinde üçü eşit genişlikte; `IntrinsicHeight` + `CrossAxisAlignment.stretch` sayesinde de eşit yükseklikte (biri iki satırlı olsa bile).
- **QR Okut butonu**: 60 px yüksekliğinde büyük buton; QR Tara sekmesini açar.
- **`_hareketListesi()`**: Bugünkü hareketler. Hata, yükleniyor ve "Bugün henüz hareketiniz yok" durumlarını ayrı ayrı gösterir.
- **`_HareketSatiri`**: Tek bir hareket satırı. Giriş yeşil, çıkış mavi, otomatik çıkış turuncu.
- **Akış neden `initState`'te oluşturuluyor?** `build()` ekran her yenilendiğinde tekrar çalışır. Akışı orada oluştursaydık her seferinde Firestore'a yeni bir dinleme açılırdı. `initState` ise ekran açılırken yalnızca bir kez çalışır.

### `ekranlar/profil_ekrani.dart`
Avatar, ad soyad, görev, rol, e-posta ve kırmızı **Çıkış Yap** butonu. `_bilgiSatiri()` tekrar eden satır görünümünü tek fonksiyonda toplar; değer kısmı `Expanded` içinde olduğu için satırda kalan tüm genişliği alır ve sağa yaslanır. "Şifre Değiştir" Gün 4'te eklenecek.

### `widgetlar/bas_harf_avatar.dart`, `rozet.dart`, `yakinda_ekrani.dart`
- **`BasHarfAvatar`**: Mavi daire içinde beyaz baş harfler (profil fotoğrafı yerine).
- **`Rozet`**: "İçeride", "Giriş" gibi küçük renkli etiket; arka planı aynı rengin %12 opak hâlidir.
- **`YakindaEkrani`**: Henüz yapılmamış sekmeler için geçici sayfa ("Gün 3'te eklenecek").

### `yardimcilar/zaman_bicimi.dart`
- **`saatYaz()`**: `DateTime` → "09:05". `padLeft(2, '0')` tek haneli sayının başına 0 koyar.
- **`sureYaz()`**: `Duration` → "2 sa 30 dk". `%` (mod) bölümden kalanı verir: 150 dakika → 2 saat, kalan 30 dakika.

### `firestore.rules` (Gün 2 eklemesi)
`hareketler` koleksiyonu için okuma kuralı: kişi yalnızca `kullaniciId` alanı kendi uid'si olan kayıtları okuyabilir. Yazma kuralları Gün 3'te eklenecek.

### `firestore.indexes.json` (Gün 2)
Firestore, birden fazla alana bakan sorgular için önceden hazırlanmış bir **indeks** (kitabın sonundaki dizin gibi) ister. Buradaki indeks "kullaniciId'ye göre filtrele, zamana göre sırala" sorgusunu hızlı ve mümkün kılar. `firebase deploy` komutuyla Firebase'e yüklendi.

---

## Gün 3 dosyaları – QR okutma ve giriş/çıkış mantığı

### Akış (projenin kalbi)

```
QR okutuldu: "workflow:bolum:abc123"
   │
   ├─ Önek yok mu? ─────────────────────────► "Geçersiz QR"
   ├─ Aynı QR 10 sn içinde mi okutuldu? ─────► "Az önce okutuldu" (kayıt yok)
   │
   └─ TRANSACTION başlar (ya hepsi ya hiçbiri)
        ├─ Bölüm yok / pasif mi? ────────────► "Geçersiz QR" / "Bölüm pasif"
        ├─ suAnkiBolumId boş     → GİRİŞ      (giris kaydı + kullanıcıya bölüm yaz)
        ├─ suAnkiBolumId = bu    → ÇIKIŞ      (cikis kaydı + kullanıcının bölümünü temizle)
        └─ suAnkiBolumId = başka → GEÇİŞ      (eskiye otomatik_cikis + yeniye giris)
```

### `modeller/bolum.dart`
- **`Bolum`**: id, ad, aktif. `id` Firestore'un ürettiği rastgele kimliktir.
- **`qrOneki`** = `"workflow:bolum:"`; **`qrIcerigi`** = önek + id. Bölüm adı değişse de QR geçerli kalır, çünkü QR'da ad değil id vardır.

### `servisler/hareket_servisi.dart`
- **`qrOkut()`**: Yukarıdaki akışı uygular.
  - **Transaction (`runTransaction`)**: İçindeki okuma ve yazmalar tek bir bütün gibi çalışır. İnternet yarıda kesilirse hiçbir şey yazılmaz; iki işlem aynı anda gelirse Firestore biri bitince diğerini baştan tekrar dener. Böylece "hareket yazıldı ama kullanıcının bölümü güncellenmedi" gibi yarım durumlar oluşmaz.
  - **`FieldValue.serverTimestamp()`**: Zaman telefondan değil Google sunucusundan alınır; telefonun saati yanlış olsa bile kayıt doğrudur.
  - **Çift okutma koruması**: Son başarılı okutmanın bölümü ve zamanı `static` değişkenlerde tutulur. `static` = tüm nesnelerin paylaştığı değişken; ekran kapanıp açılsa da silinmez.
  - **`OkutmaHatasi`**: Reddedilen okutmalar için kendi hata sınıfımız. `bilgi: true` ise hata değil bilgi (turuncu).
  - `FirebaseException` kodları (`unavailable` = internet yok, `permission-denied` = kural reddetti) Türkçe mesaja çevrilir.
- **`eskiAcikKaydiKapat()`**: Önceki günden açık kalmış giriş varsa **batch** ile otomatik çıkış yazar. Batch, transaction gibi "ya hepsi ya hiçbiri"dir ama önce okuma yapmaz, sadece yazar.

### `servisler/bolum_servisi.dart`
- **`bolumlerAkisi()`**: Bölümleri ada göre sıralı, canlı listeler.
- **`bolumEkle()`**: `add()` ile yeni bölüm ekler; Firestore rastgele kimlik üretir.

### `servisler/pdf_servisi.dart`
- **`qrPdfIndir()`**: A4 PDF oluşturup Android'in yazdırma ekranını açar (`Printing.layoutPdf`). "PDF olarak kaydet" seçilince dosya İndirilenler'e iner; depolama izni gerekmez.
- **`pw.BarcodeWidget`**: QR'ı vektör olarak çizer; büyütülse de bulanıklaşmaz.
- **`PdfGoogleFonts.notoSans...`**: Türkçe karakterli font. PDF'in varsayılan fontunda ç, ğ, ı, ş yoktur.
- **`Uint8List`**: Bayt listesi; dosyanın ham içeriği.

### `ekranlar/qr_tara_ekrani.dart`
- **`MobileScannerController`**: Kamerayı yönetir; sadece QR formatını arar.
- **`Stack`**: Widget'ları üst üste koyar: en altta kamera, üstünde çerçeve, flaş ve geri butonu, yazılar.
- **`_qrBulundu()`**: Kamera QR görünce çalışır. `_isleniyor` ile aynı anda ikinci okutma engellenir; kamera durdurulur, servis çağrılır, titreşim verilir (`HapticFeedback`), sonuç ekranı açılır. **Başarılıysa Ana Sayfa'ya dönülür**; hata/bilgide kamera tekrar açılır.
- **`ValueListenableBuilder`**: Flaşın açık/kapalı durumunu dinleyip ikonu günceller.
- **`_KameraHatasi`**: Kamera izni reddedilirse açıklama gösterir.

### `ekranlar/okutma_sonuc_ekrani.dart`
- Tam ekran sonuç: giriş yeşil, çıkış mavi, geçiş yeşil, hata kırmızı, bilgi turuncu.
- Tek seferlik **`Timer`** 2,5 sn sonra ekranı kapatır; ekrana dokununca hemen kapanır.
- Bölüm adı ayrı satırda, eksiz yazılır: "A Bölümü" + "-e" gibi ekler her ada doğru uymaz.

### `ekranlar/yonetim/bolumler_ekrani.dart` ve `bolum_qr_ekrani.dart`
- Bölüm listesi, **Bölüm Ekle** (ad sorulur → kaydedilir → QR ekranı otomatik açılır), her bölümde **QR Kodu** butonu.
- QR ekranı: bölüm adı, `QrImageView` ile büyük QR, **PDF olarak indir / yazdır** butonu.
- Gün 5'te kişi sayısı, son okutma ve pasif yapma eklenecek.

### `ekranlar/ana_iskelet.dart` (Gün 3 eklemeleri)
- QR Tara sekmesi artık gerçek tarayıcı; Yönetim sekmesi Bölümler ekranı.
- **`_eskiKaydiKontrolEt()`**: Uygulama açılınca (initState) unutulmuş çıkışı kontrol eder, kapattıysa turuncu bilgi gösterir.

### `firestore.rules` (Gün 3)
- **`yoneticiMi()`**: Kişinin kullanıcı dokümanındaki `rol` alanına bakar (`get()` ile başka doküman okunabilir).
- **`aktifBolum()`**: Bölüm var ve aktif mi?
- **Kullanıcı güncelleme**: `diff(...).affectedKeys().hasOnly([...])` → sadece bölüm alanları değişebilir; **rol asla değiştirilemez**. Bölüme giriliyorsa bölüm aktif olmalı ve giriş zamanı sunucu saati olmalı.
- **Bölümler**: Herkes okur, sadece yönetici ekler/günceller. Silme kuralı yok = silmek yasak.
- **Hareketler**: Sadece kendi adına, geçerli türde (`giris`, `cikis`, `otomatik_cikis`) ve `zaman == request.time` (sunucu saati) ile eklenebilir. Güncelleme/silme kuralı yok = kayıtlar değiştirilemez.

### `pubspec.yaml` notu
`image` paketi `<4.8.0` sürümüne sabitlendi: `pdf` paketi `archive` kütüphanesinin eski sürümünü, yeni `image` ise yenisini istiyordu; ikisi birlikte kurulamıyordu.

---

## Gün 4 dosyaları – Geçmiş ve Şifre Değiştir

### `servisler/veri_servisi.dart` (Gün 4)
- **`hareketlerAkisi(uid, baslangic)`**: Verilen andan sonraki hareketleri getirir. Ana Sayfa (bugün 00:00) ve Geçmiş (bugün / Pazartesi / ayın 1'i) aynı fonksiyonu farklı başlangıçla çağırır; kod tekrar etmez. Gün 2'deki indeks bu sorgu için de yeterlidir.

### `yardimcilar/zaman_bicimi.dart` (Gün 4)
- **`gunBasligi()`**: `DateTime` → "22 Kasım Pazar". Ay ve gün adları Türkçe listelerden alınır (`month` 1-12, `weekday` 1=Pazartesi … 7=Pazar).
- **`gunBaslangici()`**: Tarihin saatini 00:00 yapar; iki kaydın aynı günde olup olmadığını karşılaştırmak için.

### `widgetlar/hareket_zaman_cizelgesi.dart`
- Dikey zaman çizelgesi: **saat | renkli nokta + gri çizgi | bölüm kartı + rozet**.
- Gün değişince araya **gün başlığı** ekler; günün son kaydında çizgiyi keser (`cizgiDevam`).
- `IntrinsicHeight` sayesinde soldaki çizgi, sağdaki kartın boyu kadar uzar.
- `turRengi()`: giriş yeşil, çıkış mavi, otomatik çıkış turuncu. Gün 6'da yönetici Hareketler ekranında da kullanılacak.

### `ekranlar/gecmis_ekrani.dart`
- **`SegmentedButton`**: Bugün / Bu hafta / Bu ay; aynı anda bir seçenek seçilir.
- **`_akisOlustur()`**: Seçime göre başlangıç anını hesaplar. Bu hafta = bugünden `weekday - 1` gün geri (Pazartesi). Filtre değişince akış yeniden oluşturulur.
- Boş dönemde "Bu dönemde hareket yok." yazar; üstte kayıt sayısı görünür.

### `servisler/auth_servisi.dart` (Gün 4)
- **`sifreDegistir()`**: Önce mevcut şifreyle **yeniden kimlik doğrulama** (`reauthenticateWithCredential`), sonra `updatePassword`. Firebase bunu zorunlu tutar: telefonu açık bırakılan birinin şifresini başkası değiştiremesin.
- `EmailAuthProvider.credential`: "bu e-posta + bu şifre" bilgisini taşıyan kimlik belgesi.

### `ekranlar/sifre_degistir_ekrani.dart`
- Üç alan: mevcut şifre, yeni şifre (en az 6 karakter, eskisiyle aynı olamaz), yeni şifre tekrar (eşleşmeli).
- `_sifreAlani()`: Üç alan aynı görünümde olduğu için ortak fonksiyon. Tek düğme üçünün de göster/gizle durumunu değiştirir.
- Başarılıysa yeşil mesajla Profil'e döner.

### `ekranlar/profil_ekrani.dart` (Gün 4)
- Çerçeveli (`OutlinedButton`) **Şifre Değiştir** butonu eklendi; ikincil işlem olduğu için Çıkış Yap'tan farklı görünür.

### Düzeltme: Unutulan çıkışın zamanı
**Sorun:** Unutulan çıkış, uygulamanın **açıldığı anın** tarihiyle kaydediliyordu (Perşembe giriş → Pazar otomatik çıkış). Sebep: güvenlik kuralı her hareketin zamanının sunucu saati olmasını istiyordu.

**Çözüm:**
- `hareket_servisi.dart` → `eskiAcikKaydiKapat()`: Otomatik çıkış zamanı artık **giriş + 8 saat** (`tahminiMesai`); giriş gününün 23:59'unu geçerse 23:59. Bu zaman `Timestamp.fromDate()` ile yazılır. Gerçek çıkış saati bilinemediği için bu bir **tahmindir**; Gün 6'da yönetici düzeltebilecek.
- `firestore.rules` → **`gecmisOtomatikCikis()`**: Geçmiş bir zamana yazmaya izin veren **tek istisna**. Şartları: tür `otomatik_cikis`, bölüm kişinin şu anki bölümü, zaman **giriş ile giriş + 8 saat arasında** (`duration.value(8, 'h')`) ve şu andan önce. `get()` aynı batch'te kullanıcı dokümanı temizlenmeden **önceki** hâli okur. Diğer tüm kayıtlar hâlâ yalnızca sunucu saatiyle yazılabilir; böylece kimse rastgele bir tarihe kayıt ekleyemez.

**Test:** Konsoldan kullanıcıya geçmiş bir giriş verildi (19 Kasım 09:00, Yemekhane) → uygulama yeniden açıldı → Geçmiş'te **19 Kasım 17:00 · Yemekhane · Otomatik çıkış** göründü (ekran görüntüsü: `gun4-gecmis-bu-hafta.png`).

---

## Gün 5 dosyaları – Yönetim: Personeller ve Bölümler

### `ekranlar/yonetim/yonetim_ekrani.dart` (yeni)
- Yönetim sekmesinin çatısı: **Genel, Personeller, Bölümler, Hareketler**. Genel ve Hareketler Gün 6'da dolacak; şimdilik "Gün 6'da eklenecek" yazıyor.
- **`DefaultTabController`**: Üstteki sekme çubuğunu (`TabBar`) alttaki sayfalarla (`TabBarView`) bağlar; sekmeye basınca sayfa, sayfayı kaydırınca sekme değişir.
- `initialIndex: 1` → açılışta Personeller gelir (Genel henüz boş).
- `isScrollable: true`: Dar ekranda "Personeller" yazısı kesiliyordu; artık her sekme yazısı kadar geniş, sığmazsa yana kayar.

### `ekranlar/yonetim/personeller_ekrani.dart` (yeni)
- **Arama kutusu**: Her harfte liste süzülür (`onChanged` + `setState`). Büyük/küçük harf farkı yok sayılır.
- **Bölüm filtresi**: "Tümü" + bölüm adları, **`ChoiceChip`** (aynı anda biri seçili) ile; `SingleChildScrollView(scrollDirection: Axis.horizontal)` sayesinde sığmazsa yana kayar.
- Önce bölüm filtresi, sonra arama uygulanır (`where` iki kez): ikisine de uyan kişiler kalır.
- **`_PersonelSatiri`**: avatar, ad soyad, şu anki bölüm (yoksa "Bölümde değil"), **son giriş**, **İçeride** (yeşil) / **Dışarıda** (gri) rozeti.
- **Son giriş nereden?** Kişi içerideyse kendi dokümanındaki `girisZamani`; değilse son 300 hareket içindeki en yeni "giris" kaydı. Bulunamazsa "—".

### `ekranlar/yonetim/bolumler_ekrani.dart` (Gün 5)
- Kendi başlığı (AppBar) kaldırıldı; başlık artık Yönetim ekranında.
- Her kartta **"2 kişi içeride · Son okutma: 09:12"**.
  - **Kişi sayısı**: Tüm kullanıcılar okunur, `suAnkiBolumId` değerine göre bir **Map**'te (bölümId → sayı) sayılır.
  - **Son okutma**: Son hareketler en yeniden eskiye sıralı geldiği için bir bölümle ilk karşılaşılan kayıt en sonuncusudur (`putIfAbsent` = yoksa ekle, varsa dokunma). Otomatik çıkışlar sayılmaz, çünkü QR okutularak oluşmazlar.
- Üç akış iç içe (`StreamBuilder` içinde `StreamBuilder`): bölümler + kullanıcılar + hareketler. Kullanıcılar/hareketler henüz gelmese bile bölümler gösterilir.
- **Pasif yapma** ileriye bırakıldı (karar: Gün 5'te yapılmadı).

### `servisler/veri_servisi.dart` (Gün 5)
- **`tumKullanicilarAkisi()`**: Tüm kullanıcılar, ada göre sıralı.
- **`sonHareketlerAkisi()`**: Herkesin en yeni 300 hareketi. **`limit()`** = en fazla bu kadar doküman getir; hepsini okumak yavaş ve pahalı olurdu. Tek alana (`zaman`) göre sıralandığı için yeni indeks gerekmedi.

### `yardimcilar/zaman_bicimi.dart` (Gün 5)
- **`kisaZamanYaz()`**: Bugünse "09:12", değilse "19 Kas 09:12".

### `modeller/kullanici.dart` (Gün 5)
- **`turkceKucukHarf()`**: Aramada "İsmail" ile "ismail" eşleşsin diye; Dart'ın `toLowerCase()` fonksiyonu "I" harfini "ı" değil "i" yapar.

### `firestore.rules` (Gün 5)
- `kullanicilar` ve `hareketler` okuma kuralına **`|| yoneticiMi()`** eklendi: yönetici herkesinkini okur, personel hâlâ sadece kendisininkini. `firebase deploy --only firestore` ile yayınlandı.

### Küçük temizlik
- `flutter analyze` eski dosyalarda 7 bilgi notu veriyordu ("if içindeki satır süslü parantezde olmalı"). `dart fix --apply` ile düzeltildi; davranış değişmedi.

**Ekran görüntüsü:** `ekran-goruntuleri/gun5-personeller.png`

---

## Gün 6 dosyaları – Yönetim: Genel ve Hareketler

### `ekranlar/yonetim/genel_ekrani.dart` (yeni)
- **`_SayiKarti`**: "Toplam personel" ve "Şu an içeride" (bir bölümde görünen kişi sayısı) kartları.
- **Bölüm Durumu**: Her aktif bölüm için ad, "1 kişi" ve yatay çubuk (**`LinearProgressIndicator`**: 0 ile 1 arasındaki değeri çubuk olarak çizer).
  - **Çubuğun doluluğu = o bölümdeki kişi ÷ şu an içerideki toplam kişi.** Örnek: 4 kişi içeride, 3'ü Emerald'da → Emerald çubuğu %75. Yani içeridekilerin bölümlere dağılımını gösterir.
  - Pasif bölüm, sadece içinde hâlâ biri varsa gösterilir.
  - `(Bolum, int)` bir **record**'dur: iki değeri yeni sınıf yazmadan tek pakette taşır.
- **Son Hareketler**: Herkesin son 10 kaydı (saat, kişi, bölüm, tür rozeti). `sonHareketlerAkisi(adet: 10)` ile.
- **`_SistemDurumu`**: Yeşil nokta + "Sistem aktif · 22 Kasım Pazar 16:27". `Timer.periodic` her 30 saniyede ekranı yeniler; `dispose()` içinde durdurulur.

### `ekranlar/yonetim/hareketler_ekrani.dart` (yeni)
- **Personel seçici**: **`DropdownButtonFormField`** (açılır liste). İlk açılışta listedeki ilk kişi seçilir.
- **Filtre**: Bugün / Dün / Bu hafta / Tarih seç (`SegmentedButton`). Tarih seç → **`showDatePicker`** takvimi açar; seçilen gün düğmede yazar ("19.11"), vazgeçilirse filtre değişmez.
- **`_donem()`**: Seçime göre dönemin başını ve sonunu bir record olarak döndürür: Dün = (dün 00:00, bugün 00:00).
- **`_akisAl()`**: Kişi veya dönem değişince yeni akış açar, değişmediyse eskisini kullanır (her `build`'de Firestore'a yeni dinleme açılmasın diye).
- Üstte **toplam çalışma süresi** kartı ve kayıt sayısı, altında Gün 4'teki zaman çizelgesi.

### `yardimcilar/calisma_suresi.dart` (yeni)
- **`toplamCalismaSuresi()`**: Kayıtları eskiden yeniye sıralar; her **giriş** ile ondan sonraki **çıkış** arasındaki süreleri toplar.
- Bölüm değiştirmek süreyi bölmez: eski bölümden otomatik çıkış ve yeni bölüme giriş **aynı anda** yazılır. Aynı andaki kayıtlarda önce çıkış, sonra giriş işlensin diye sıralamaya ek kural konuldu.
- Kişi hâlâ içerideyse süre şu ana (geçmiş bir gün seçildiyse o günün sonuna) kadar sayılır.
- **Girişi listede olmayan çıkış sayılmaz.** İlk sürümde dönemin başından (00:00) sayılıyordu; konsoldan elle yazılmış test girişi yüzünden 17 saatlik hatalı süre çıktı. Bedeli: gece yarısını geçen mesaide (23:00 giriş, 01:00 çıkış) "Bugün" filtresinde 00:00–01:00 arası sayılmaz.

### `servisler/veri_servisi.dart` (Gün 6)
- `hareketlerAkisi()` fonksiyonuna isteğe bağlı **`bitis`** eklendi: verilirse o andan önceki kayıtlar gelir. Aynı alana (`zaman`) iki sınır koyduğumuz için Gün 2'deki indeks yeterli.

### `main.dart` ve `pubspec.yaml` (Gün 6)
- **`flutter_localizations`** (Flutter'la birlikte gelir) eklendi, uygulama dili `Locale('tr')` yapıldı. Böylece takvim ve "İptal/Tamam" gibi hazır yazılar Türkçe.

### Güvenlik kuralları
- Yeni kural gerekmedi: Gün 5'te yöneticiye tüm kullanıcıları ve hareketleri okuma izni verilmişti.

### Gün 7'ye kalanlar
- Yöneticinin otomatik çıkış saatini düzeltmesi, bölümü pasif yapma.

**Ekran görüntüleri:** `ekran-goruntuleri/gun6-genel.png`, `ekran-goruntuleri/gun6-hareketler.png`

---

## Gün 7 dosyaları – Pasif bölüm, internet şeridi, kamera izni ve testler

### `servisler/bolum_servisi.dart` (Gün 7)
- **`aktiflikDegistir(bolum, aktif)`**: Bölümün `aktif` alanını değiştirir. **`update()`** sadece verilen alanı değiştirir, diğerlerine dokunmaz. Bölümler silinmez; pasif bölümün QR'ı ve eski kayıtları bozulmaz.

### `ekranlar/yonetim/bolumler_ekrani.dart` (Gün 7)
- Her kartta **`PopupMenuButton`** ("⋮" simgesi): basınca küçük menü açılır → **Pasif yap** / **Aktif yap**.
- Pasif yapmadan önce **onay penceresi** (`AlertDialog`): "Bu bölüme artık giriş yapılamaz. İçerideki kişiler çıkış yapabilir." Vazgeçilir veya pencere dışına basılırsa hiçbir şey değişmez.

### `servisler/hareket_servisi.dart` (Gün 7)
- Pasif bölüm kontrolü değişti: Önceden pasif bölümde **her** okutma reddediliyordu, içerideki kişi çıkamıyordu. Artık kural: **pasif bölüme girilemez ama içindeki kişi çıkabilir.** Mesaj: "Bu bölüm (Emerald) şu an pasif. Giriş yapamazsınız." Güvenlik kuralları zaten sadece **girişte** bölümün aktif olmasını istiyordu; kural değişmedi.

### `widgetlar/internet_seridi.dart` (yeni)
- **`connectivity_plus`** paketiyle bağlantıyı **sürekli dinler** (`onConnectivityChanged` akışı). Hiçbir ağa bağlı değilse kırmızı "İnternet bağlantısı yok" şeridi; bağlantı varken `SizedBox.shrink()` ile hiç yer kaplamaz.
- Açılıştaki durum için ayrıca **`checkConnectivity()`** sorulur (akış ilk değişikliğe kadar değer göndermeyebilir). `FutureBuilder` içinde `StreamBuilder` bunu birleştirir.
- **Neden sekme geçişinde kontrol değil de sürekli dinleme?** Aynı sekmede dururken kesilen bağlantıyı da hemen gösterir.
- Not: Bu paket telefonun bir ağa bağlı olup olmadığını bilir; Wi-Fi'ye bağlı ama modemin interneti yoksa şerit çıkmaz. O durumda QR okutma yine "internet yok" hatası verir.

### `ekranlar/ana_iskelet.dart` (Gün 7)
- `bottomNavigationBar` artık bir `Column`: üstte `InternetSeridi`, altta alt menü. Şerit **alt menünün hemen üstünde** durur; üste koysaydık her ekranın lacivert başlığıyla çakışırdı.

### `ekranlar/qr_tara_ekrani.dart` (Gün 7)
- İzin reddedilince **"Ayarlara git"** butonu: **`permission_handler`** paketinin `openAppSettings()` fonksiyonu telefonun bu uygulamaya ait ayar sayfasını açar.
- **`WidgetsBindingObserver`** + **`didChangeAppLifecycleState`**: Uygulama arka plana gidip geri gelince haber alırız. Ayarlardan dönülünce (`resumed`) izin verildiyse (`Permission.camera.isGranted`) kamera yeniden başlatılır.
- **Testte bulunan hata – sonsuz döngü:** İlk sürüm her "geri dönüşte" kamerayı başlatıyordu. Ama Android'in izin penceresi kapanınca da "geri dönüş" sinyali gelir → kamera tekrar izin ister → pencere → geri dönüş → ... Çözüm: **`_ayarlaraGidildi`** bayrağı; sadece "Ayarlara git"e basıldıysa yeniden başlatılır.
- Kamera hata verdiyse tarama çerçevesi çizilmez (`ValueListenableBuilder` ile kameranın `error` durumu dinlenir); önceden çerçeve hata yazısının üstüne biniyordu.

### `pubspec.yaml` (Gün 7)
- `connectivity_plus` ve `permission_handler` eklendi. `permission_handler`'ın en yeni sürümü (13) projenin Android ayarlarıyla derlenmedi (Kotlin derleme hatası); **12.0.1** sürümüne sabitlendi.

### `docs/TEST_SENARYOLARI.md` (yeni)
- 7 test senaryosu: nasıl denendi, beklenen sonuç, sonuç. Testlerde bulunan ve düzeltilen hatalar tablosu. Rapora girecek.

**Ekran görüntüsü:** `ekran-goruntuleri/gun7-kamera-izni.png`

---

## Ek düzeltme – 9 saat otomatik çıkış kuralı

**Önceki durum:** Unutulan çıkış sadece **ertesi gün** uygulama açılınca kapatılıyor, saati "giriş + 8 saat (en geç 23:59)" yazılıyordu. Biri sabah girip çıkışı unutursa akşam hâlâ "İçeride" görünüyordu.

**Yeni kural:** Girişin üzerinden **9 saat** geçince kişi otomatik çıkmış sayılır; çıkış kaydı her zaman tam **giriş + 9 saat** zamanıyla yazılır (23:59 sınırı kalktı, gece vardiyası da doğru hesaplanır).

### `modeller/kullanici.dart`
- **`otomatikCikisSuresi = Duration(hours: 9)`**: Süre tek yerde. Değiştirilirse `firestore.rules` içindeki `9` da değişmeli.
- **`suresiDolduMu`**: Girişin üzerinden 9 saat geçti mi?
- **`suAnIcerideMi`**: Ekranda gösterilecek durum = içeride **ve** süre dolmamış. `icerideMi` (dokümana göre) giriş/çıkış kararında, `suAnIcerideMi` ekranlarda kullanılır.

### Kaydı kim, ne zaman yazıyor? (Sunucu olmadığı için kişinin kendi telefonu)
- **Uygulama açılınca** ve **açıkken her dakika** (`ana_iskelet.dart` → `Timer.periodic`). Kontrol internete çıkmaz, sadece süreye bakar; süre dolduysa tek kayıt yazar. `_kontrolSuruyor` bayrağı iki kontrolün aynı anda iki kayıt yazmasını engeller; **`finally`** bloğu hata olsa da olmasa da bayrağı indirir.
- **QR okutulunca** (`hareket_servisi.dart` → transaction içinde): Süre dolmuşsa önce eski giriş "giriş + 9 saat" ile kapatılır, sonra bu okutma **yeni giriş** sayılır. Yoksa ertesi sabah aynı QR okutulunca yanlışlıkla "çıkış" olurdu.
  - **`...` (spread)**: Bir haritanın tüm alanlarını başka haritaya kopyalar; burada ortak alanları kopyalayıp sadece `zaman`ı geçmiş saatle değiştirdik.

### Yönetici ekranları (Genel, Personeller, Bölümler) ve Ana Sayfa
- `suAnIcerideMi` kullanılır: Süresi dolan kişi, **telefonu kapalı olsa bile** hemen "Dışarıda" görünür ve bölüm sayılarına katılmaz. Personeller'de "Otomatik çıkış (9 saat doldu)" yazar. Kayıt, kişi uygulamayı açınca yazılır.

### `firestore.rules`
- `gecmisOtomatikCikis()` içindeki sınır `duration.value(9, 'h')` oldu ve yayınlandı.

### Test
- Kullanıcı Emerald'dayken konsoldan `girisZamani` 09:00 yapıldı → 1 dakika içinde turuncu uyarı, Geçmiş'te **18:00 · Emerald · Otomatik çıkış**, Ana Sayfa'da "hiçbir bölümde değilsiniz". Ardından QR ile giriş/çıkış yapıldı; `girisZamani` girişte o anın saatini aldı, çıkışta null oldu.
- Not: Testte 18:00 çıkışı listede 20:02 girişinin altında göründü; çünkü konsoldan yazılan 09:00 sahte bir giriş saatiydi. Gerçek kullanımda bu sıra oluşmaz.

---

## Arayüz tasarımı – yeni görünüm

**Amaç:** Uygulama hazır şablon gibi (her yerde aynı mavi, beyaz kart, gölge) görünmesin; fabrikadaki işçi ve ofisteki çalışan için sade, okunaklı ve kendine ait bir görünüm olsun. Çalışma mantığına dokunulmadı; sadece görünüm değişti.

**Seçimler:** Renkler petrol yeşili (ana), hardal sarısı (vurgu) ve krem (arka plan). Yazı tipi birçok seçenek arasından elenerek seçilen **Rubik** (köşeleri hafif yuvarlak, yumuşak ama sağlam). Personel ekranları büyük, yönetim ekranları sıkı.

### `assets/fonts/` ve `pubspec.yaml`
- Rubik'in 3 kalınlığı (Regular 400, Medium 500, SemiBold 600) ve lisans dosyası `OFL.txt` (açık lisans, ücretsiz).
- `pubspec.yaml` → `fonts:` bölümü: Yazı tipi dosyaları uygulamanın **içine** konur; internet olmadan da çalışır. `weight:` hangi dosyanın hangi kalınlık olduğunu söyler.

### `tema.dart`
- **`Renkler`**: Yeni palet. Eski `lacivert` ve `mavi` kaldırıldı, yerine `petrol`, `hardal`, `kenar`, `yazi` geldi. Çıkış rengi artık kiremit (`hata`).
- **`kartDekorasyonu()`**: Gölge kaldırıldı, yerine ince kenar çizgisi (`Border.all`).
- **`KucukBaslik`**: "BUGÜN" gibi küçük başlıklar; büyük harf ve **`letterSpacing`** (harfler arası boşluk) ile tabela hissi verir. Türkçe "i → İ" için `turkceBuyukHarf` kullanılır.
- **`ThemeData`** içine eklenenler: `fontFamily: 'Rubik'` (tüm uygulamada), `appBarTheme` (petrol üst çubuk), `navigationBarTheme` (alt menü; seçili sekmenin arkasında hardal hap), `tabBarTheme` (seçili sekme altında hardal çizgi), `chipTheme` (seçili filtre petrol dolgulu), `dividerTheme` (liste çizgileri).
  - **`WidgetStateProperty.resolveWith`**: Bir değerin duruma göre (seçili mi, değil mi) değişmesini sağlar; alt menüde seçili sekmenin yazısı petrol ve kalın olur.

### `widgetlar/workflow_logo.dart`
- **`LogoIsareti`**: İçinde "W" olan kare; sol üst ve sağ alt köşede QR çerçevesini hatırlatan hardal çizgiler. Resim dosyası yok, kodla çizilir.
  - **`Stack` + `Positioned`**: Parçaları üst üste koyar ve her birinin yerini (üstten/soldan uzaklık) ayarlar.
- **`LogoYazisi`**: "Work" yarı kalın, "Flow" ince ve renkli. **`Text.rich` / `TextSpan`**: Tek yazı içinde farklı biçimli parçalar.
- **`LogoSatiri`**: İşaret + yazı yan yana. `koyuZemin: true` ise petrol zemine uygun renkler (beyaz kare, sarı "Flow").

### `ekranlar/ana_sayfa.dart`
- **Üst şerit (`_UstSerit`)**: Petrol zeminde logo ve saate göre selam ("Günaydın / İyi günler / İyi akşamlar, Ad").
- **Durum kartı**: Solda renkli şerit (yeşil = içeride, gri = dışarıda), büyük bölüm adı ve süre. **`clipBehavior: Clip.antiAlias`**: Şeridin kartın yuvarlak köşesinden taşmasını engeller.
- **QR butonu**: Hardal sarısı, 72 px yüksek; personelin en çok bastığı yer olduğu için en büyük öğe.
- **Bugün listesi**: Tek kart içinde, satırlar `Divider` ile ayrılır. Saatler **`FontFeature.tabularFigures()`** ile yazılır: tüm rakamlar aynı genişlikte olur, saatler alt alta düzgün hizalanır.
- "Durum" küçük kartı kaldırıldı; aynı bilgi artık büyük kartta.

### Diğer ekranlar
- **`okutma_sonuc_ekrani.dart`**: Tam ekran renkli; büyük bölüm adı sola yaslı, ikon çerçeveli karede, altında "Kapatmak için ekrana dokunun".
- **`giris_ekrani.dart`**: Yeni logo; alttaki slogan düz yazı.
- **Yönetim > Personeller ve Bölümler**: Her satır ayrı kart yerine **tek kart içinde çizgiyle ayrılmış** sıkı liste.
- **`bas_harf_avatar.dart`**: Yuvarlak yerine köşeleri yuvarlak kare, açık petrol zemin.
- **`rozet.dart`**: Küçük köşeli, büyük harfli etiket ("İÇERİDE", "DIŞARIDA").
- **`yonetim_ekrani.dart`**, Geçmiş, Profil vb.: Renkler artık temadan geliyor.

**Ekran görüntüleri:** `ekran-goruntuleri/tasarim-ana-sayfa.png`, `ekran-goruntuleri/tasarim-personeller.png`
