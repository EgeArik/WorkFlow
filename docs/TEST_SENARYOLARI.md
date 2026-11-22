# Test Senaryoları

Testler 22 Kasım 2026'da gerçek bir Android telefonda (Xiaomi) uygulamanın debug sürümüyle yapıldı.

| # | Senaryo | Nasıl denendi | Beklenen sonuç | Sonuç |
|---|---|---|---|---|
| 1 | Geçersiz QR | WorkFlow'a ait olmayan bir QR okutuldu | Kırmızı ekranda "Geçersiz QR" | ✅ Başarılı |
| 2a | Pasif bölüme giriş | Bölüm Yönetim > Bölümler'den pasif yapıldı, dışarıdayken QR'ı okutuldu | Kırmızı ekranda "Bu bölüm (...) şu an pasif. Giriş yapamazsınız." | ✅ Başarılı |
| 2b | Pasif bölümden çıkış | Kişi bölümün içindeyken bölüm pasif yapıldı, QR okutuldu | Normal çıkış ekranı; çıkış kaydedildi | ✅ Başarılı |
| 3 | İnternet kesintisi | Wi-Fi ve mobil veri kapatıldı, QR okutulmaya çalışıldı | Alt menünün üstünde kırmızı "İnternet bağlantısı yok" şeridi; okutmada internet hatası | ✅ Başarılı |
| 4 | Kamera izni reddi | İzin penceresinde "İzin verme" seçildi | "Kamera izni verilmedi" + "Ayarlara git" butonu; izin verilip dönülünce kamera açılır | ✅ Başarılı (ilk denemede hata bulundu ve düzeltildi, aşağıya bakın) |
| 5 | Çıkışı unutma (9 saat kuralı) | Kullanıcı bir bölümdeyken konsoldan giriş zamanı 9 saatten daha eskiye (09:00) alındı | 1 dakika içinde turuncu bilgi mesajı; Geçmiş'te tam giriş + 9 saate (18:00) otomatik çıkış; kişi Dışarıda | ✅ Başarılı |
| 6 | Aynı QR'ı art arda okutma | Aynı QR 10 saniye içinde iki kez okutuldu | Turuncu "Bu QR az önce okutuldu" mesajı, yeni kayıt yok | ✅ Başarılı |
| 7 | Personelin yönetici verisine erişmesi | Personel hesabıyla giriş yapıldı | Alt menüde Yönetim sekmesi yok; Geçmiş'te sadece kendi kayıtları. Güvenlik kuralları da başkasının verisini okumayı reddeder | ✅ Başarılı |

## Testlerde bulunan ve düzeltilen hatalar

| Hata | Sebep | Çözüm |
|---|---|---|
| Kamera izni reddedilince izin penceresi sürekli yeniden açılıyordu (sonsuz döngü) | Android'in izin penceresi kapanınca uygulama "geri döndü" sinyali alıyor; kod her seferinde kamerayı yeniden başlatıyor, kamera da tekrar izin istiyordu | Kamera sadece "Ayarlara git"ten dönülünce ve izin gerçekten verildiyse yeniden başlatılıyor |
| İzin hata ekranında tarama çerçevesi yazının üstüne biniyordu | Çerçeve her durumda çiziliyordu | Kamera hata verdiyse çerçeve çizilmiyor |
| Yönetici Hareketler ekranında çalışma süresi çok uzun çıkıyordu (17 sa 31 dk) | Girişi listede olmayan çıkış gece 00:00'dan sayılıyordu | Girişi görünmeyen çıkış süreye eklenmiyor (Gün 6) |
| Yönetim sekme çubuğunda "Personeller" yazısı kesiliyordu | 4 sekme dar ekrana eşit bölününce yazı sığmadı | Sekmeler yazı kadar geniş ve yana kaydırılabilir (Gün 5) |
