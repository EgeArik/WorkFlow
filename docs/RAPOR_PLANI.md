# Proje Sonu Raporu – Plan

Rapor, proje tamamlandıktan sonra (Gün 7 sonrası) yazılacak. Aşağıda raporun bölümleri ve çizilecek diyagramlar yer alıyor.

## Rapor bölümleri

| Bölüm | Raporda ne olacak |
|---|---|
| **Proje Adı** | WorkFlow – QR Kodlu Personel Bölüm Takip Uygulaması |
| **1. Giriş** | Uygulamanın amacı (personelin hangi bölümde olduğunu QR ile takip), kimler kullanır, roller (Yönetici / Personel) ve yetkileri, internet gerektirmesi (Firebase) |
| **2. Araçlar ve Yöntemler** | Ekran sayısı ve adları; Flutter/Dart, Android Studio, Firebase Authentication, Cloud Firestore, Git/GitHub; kullanılan paketler; şifrelerin Firebase Authentication'da güvenli saklanması (şifreler uygulamada veya veritabanında açık metin olarak tutulmaz); her ekranın **ekran görüntüsü + "Görsel X:" alt yazısı + açıklama** |
| **3. Sonuç** | Uygulamanın yerine getirdiği işlemler maddeler hâlinde (giriş/kayıt, QR ile giriş-çıkış, otomatik çıkış, bölüm ekleme/pasif yapma, QR/PDF üretme, raporlar...) |
| **Ürünün Eksiklikleri** | Yapılmayanlar (proje tanımının 9. maddesi: GPS, bildirim, şifremi unuttum...) ve geliştirilebilecekler: yöneticinin otomatik çıkış saatini düzeltmesi; mesai saati (ör. 17:00) sonrasında bölüme giriş yapılamaması (sunucu olmadığı için okutma anında saat kontrolüyle yapılabilir) |
| **Sözlük** | Flutter, Dart, Widget, Firebase, Firestore, NoSQL, QR, Stream, Transaction, IDE, Git... |
| **Kaynakça** | Flutter, Firebase ve kullanılan paketlerin belgeleri |
| **Ek** | Önemli kodların **ekran görüntüsü + ne işe yaradığı** (KOD_REHBERI.md'den) |

## Diyagramlar

| Diyagram | WorkFlow için |
|---|---|
| **Varlık İlişki Şeması** | Varlıklar: Kullanıcı, Bölüm, Hareket. İlişkiler: Kullanıcı 1–n Hareket ("okutur"), Bölüm 1–n Hareket ("kaydedilir"), Kullanıcı n–1 Bölüm ("şu an içindedir") |
| **Veri Akış Diyagramı** | YÖNETİCİ / PERSONEL → QR OKUT → hareketler koleksiyonu → HAREKETLERİ LİSTELE; YÖNETİCİ → BÖLÜM İŞLEMLERİ (Ekle, Pasif yap) → bolumler → BÖLÜMLERİ LİSTELE; vb. |
| **Kullanıcı Arayüzü Tasarımı** | Ana Sayfa, QR Tara, Yönetim ekranlarının kutu taslakları (wireframe) |
| **Veri Tabanı Tasarımı** | `kullanicilar`, `bolumler`, `hareketler` koleksiyonlarının alanları, veri türleri ve aralarındaki bağlantılar. Not: Firestore ilişkisel (SQL) değil, NoSQL; tablo yerine koleksiyon, satır yerine doküman var. Raporda bu fark kısaca açıklanacak. |

## Şimdiden toplananlar
- Ekran görüntüleri: `docs/ekran-goruntuleri/` (her gün eklenir)
- Kod açıklamaları: `docs/KOD_REHBERI.md`
- Veritabanı anlatımı: `docs/VERITABANI.md`
- Gereksinimler: `docs/PROJE_TANIMI.md`
- Test senaryoları ve sonuçları: `docs/TEST_SENARYOLARI.md`
