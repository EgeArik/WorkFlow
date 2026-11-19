# Proje Sonu Raporu – Plan

Ders kitabı: *Yazılım Projesi 11-12 (Bilişim Teknolojileri)*, MEB. Rapor formatı kitabın **2.6 Stok Takip Programı Rapor Aşaması** (s. 103-106) örneğine göre, diyagramlar **2.2.2-2.2.5** (s. 56-59) örneklerine göre hazırlanacak. Rapor, proje tamamlandıktan sonra (Gün 7 sonrası) yazılacak.

## Kitaptaki rapor bölümleri → WorkFlow karşılıkları

| Kitaptaki bölüm | WorkFlow raporunda ne olacak |
|---|---|
| **Proje Adı** | WorkFlow – QR Kodlu Personel Bölüm Takip Uygulaması |
| **1. Giriş** | Uygulamanın amacı (personelin hangi bölümde olduğunu QR ile takip), kimler kullanır, roller (Yönetici / Personel) ve yetkileri, internet gerektirmesi (Firebase) |
| **2. Araçlar ve Yöntemler** | Ekran sayısı ve adları; Flutter/Dart, Android Studio, Firebase Authentication, Cloud Firestore, Git/GitHub; kullanılan paketler; şifrelerin Firebase Authentication'da güvenli saklanması (kitaptaki MD5 paragrafının karşılığı); her ekranın **ekran görüntüsü + "Görsel X:" alt yazısı + açıklama** |
| **3. Sonuç** | Uygulamanın yerine getirdiği işlemler maddeler hâlinde (giriş/kayıt, QR ile giriş-çıkış, otomatik çıkış, bölüm ekleme/pasif yapma, QR/PDF üretme, raporlar...) |
| **Ürünün Eksiklikleri** | Yapılmayanlar (proje tanımının 9. maddesi: GPS, bildirim, şifremi unuttum...) ve geliştirilebilecekler |
| **Sözlük** | Flutter, Dart, Widget, Firebase, Firestore, NoSQL, QR, Stream, Transaction, IDE, Git... |
| **Kaynakça** | Flutter, Firebase, paket belgeleri; ders kitabı |
| **Ek (bizim ilavemiz)** | Önemli kodların **ekran görüntüsü + ne işe yaradığı** (KOD_REHBERI.md'den) |

## Kitaptaki diyagramlar → WorkFlow karşılıkları

| Kitaptaki diyagram | WorkFlow için |
|---|---|
| **Varlık İlişki Şeması** (Görsel 2.2) | Varlıklar: Kullanıcı, Bölüm, Hareket. İlişkiler: Kullanıcı 1–n Hareket ("okutur"), Bölüm 1–n Hareket ("kaydedilir"), Kullanıcı n–1 Bölüm ("şu an içindedir") |
| **Veri Akış Diyagramı** (Görsel 2.3) | YÖNETİCİ / PERSONEL → QR OKUT → hareketler koleksiyonu → HAREKETLERİ LİSTELE; YÖNETİCİ → BÖLÜM İŞLEMLERİ (Ekle, Pasif yap) → bolumler → BÖLÜMLERİ LİSTELE; vb. |
| **Kullanıcı Arayüzü Tasarımı** (Görsel 2.4-2.6) | Ana Sayfa, QR Tara, Yönetim ekranlarının kutu taslakları (wireframe) |
| **Veri Tabanı Tasarımı** (Görsel 2.7-2.8) | `kullanicilar`, `bolumler`, `hareketler` koleksiyonlarının alanları, veri türleri ve aralarındaki bağlantılar. Not: Firestore ilişkisel (SQL) değil, NoSQL; tablo yerine koleksiyon, satır yerine doküman var. Raporda bu fark kısaca açıklanacak. |

## Şimdiden toplananlar
- Ekran görüntüleri: `docs/ekran-goruntuleri/` (her gün eklenir)
- Kod açıklamaları: `docs/KOD_REHBERI.md`
- Veritabanı anlatımı: `docs/VERITABANI.md`
- Gereksinimler: `docs/PROJE_TANIMI.md`
