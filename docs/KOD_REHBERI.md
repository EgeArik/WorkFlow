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
│   └── veri_servisi.dart     Firestore'dan canlı veri okuma
├── ekranlar/                 Tam sayfa ekranlar
│   ├── giris_ekrani.dart
│   ├── kayit_ekrani.dart
│   ├── ana_iskelet.dart      Alt menü + sekmeler
│   ├── ana_sayfa.dart
│   └── profil_ekrani.dart
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

### `firestore.indexes.json`
Firestore, birden fazla alana bakan sorgular için önceden hazırlanmış bir **indeks** (kitabın sonundaki dizin gibi) ister. Buradaki indeks "kullaniciId'ye göre filtrele, zamana göre sırala" sorgusunu hızlı ve mümkün kılar. `firebase deploy` komutuyla Firebase'e yüklendi.
