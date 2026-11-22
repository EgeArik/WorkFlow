import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../servisler/hareket_servisi.dart';
import '../tema.dart';
import 'okutma_sonuc_ekrani.dart';

// QR Tara sekmesi: açılınca kamera doğrudan çalışır. Sadece canlı kamera; galeriden seçme yok.
class QrTaraEkrani extends StatefulWidget {
  final String uid;
  // Ana Sayfa sekmesine döndürür. Geri butonunda ve başarılı okutmadan sonra çağrılır.
  final VoidCallback geriTiklandi;

  const QrTaraEkrani({
    super.key,
    required this.uid,
    required this.geriTiklandi,
  });

  @override
  State<QrTaraEkrani> createState() => _QrTaraEkraniState();
}

class _QrTaraEkraniState extends State<QrTaraEkrani> {
  // Kamerayı yöneten nesne. Sadece QR formatını arar (daha hızlı).
  final _kamera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final _hareketServisi = HareketServisi();
  bool _isleniyor = false; // bir okutma işlenirken yeni okutmaları yok say

  @override
  void dispose() {
    _kamera.dispose(); // sekmeden çıkınca kamerayı kapat
    super.dispose();
  }

  // Kamera bir QR gördüğünde çağrılır (saniyede birkaç kez çağrılabilir).
  Future<void> _qrBulundu(BarcodeCapture yakalanan) async {
    if (_isleniyor) return;
    final metin = yakalanan.barcodes.firstOrNull?.rawValue;
    if (metin == null) return;

    setState(() => _isleniyor = true);
    await _kamera.stop(); // sonuç ekranı açıkken taramayı durdur

    OkutmaSonucu? sonuc;
    OkutmaHatasi? hata;
    try {
      sonuc = await _hareketServisi.qrOkut(qrMetni: metin, uid: widget.uid);
      HapticFeedback.heavyImpact(); // başarılı: güçlü titreşim
    } on OkutmaHatasi catch (e) {
      hata = e;
      HapticFeedback.vibrate(); // hata/bilgi: titreşim
    }

    if (!mounted) return;
    // Tam ekran sonucu göster ve kapanmasını bekle.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OkutmaSonucEkrani(sonuc: sonuc, hata: hata),
      ),
    );
    if (!mounted) return;
    // Başarılı okutmadan sonra Ana Sayfa'ya dön (sekme değişince bu ekran ve kamera kapanır).
    // Hata/bilgi durumunda burada kal ve kamerayı tekrar aç ki hemen yeniden denenebilsin.
    if (sonuc != null) {
      widget.geriTiklandi();
      return;
    }
    setState(() => _isleniyor = false);
    await _kamera.start(); // yeni okutma için kamerayı tekrar aç
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        // Stack: widget'ları üst üste koyar. En altta kamera, üstünde çerçeve ve butonlar.
        children: [
          MobileScanner(
            controller: _kamera,
            onDetect: _qrBulundu,
            errorBuilder: (context, hata) => _KameraHatasi(hata: hata),
          ),
          const _TaramaCercevesi(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.geriTiklandi,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Geri',
                  ),
                  const Spacer(),
                  // ValueListenableBuilder: kamera durumu (flaş açık/kapalı) değişince butonu yeniler.
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _kamera,
                    builder: (context, durum, _) => IconButton(
                      onPressed: () => _kamera.toggleTorch(),
                      tooltip: 'Flaş',
                      icon: Icon(
                        durum.torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bölüm QR kodunu okutun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Giriş mi çıkış mı olduğu mevcut durumunuza göre otomatik belirlenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    if (_isleniyor) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ortadaki beyaz köşeli kare çerçeve (QR'ı buraya hizala).
class _TaramaCercevesi extends StatelessWidget {
  const _TaramaCercevesi();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

// Kamera açılamazsa (ör. izin reddedildi) gösterilen ekran.
class _KameraHatasi extends StatelessWidget {
  final MobileScannerException hata;
  const _KameraHatasi({required this.hata});

  @override
  Widget build(BuildContext context) {
    final izinYok = hata.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Renkler.lacivert,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            izinYok
                ? 'Kamera izni verilmedi.\nQR okutmak için telefon ayarlarından WorkFlow uygulamasına kamera izni verin.'
                : 'Kamera açılamadı. Uygulamayı kapatıp tekrar deneyin.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
