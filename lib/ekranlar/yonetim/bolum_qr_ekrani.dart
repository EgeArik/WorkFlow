import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../modeller/bolum.dart';
import '../../servisler/pdf_servisi.dart';
import '../../tema.dart';

// Bir bölümün büyük QR kodu. Kapıya asılacak çıktı buradan alınır.
// "PDF olarak indir / yazdır" butonu A4 PDF oluşturur (servisler/pdf_servisi.dart).
class BolumQrEkrani extends StatelessWidget {
  final Bolum bolum;
  const BolumQrEkrani({super.key, required this.bolum});

  Future<void> _pdfIndir(BuildContext context) async {
    final mesajlar = ScaffoldMessenger.of(
      context,
    ); // await'ten önce alırız (ekran kapanabilir)
    try {
      await PdfServisi().qrPdfIndir(bolum);
    } catch (_) {
      mesajlar.showSnackBar(
        const SnackBar(
          content: Text(
            'PDF oluşturulamadı. İnternet bağlantınızı kontrol edin.',
          ),
          backgroundColor: Renkler.hata,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kodu'),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: kartDekorasyonu(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bolum.ad,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Renkler.lacivert,
                  ),
                ),
                const SizedBox(height: 20),
                // QrImageView: verilen metni QR koduna çevirip çizer.
                QrImageView(
                  data: bolum.qrIcerigi, // "workflow:bolum:<id>"
                  size: 260,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Giriş ve çıkış için okutun',
                  style: TextStyle(color: Renkler.griYazi, fontSize: 16),
                ),
                if (!bolum.aktif) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Bu bölüm pasif: okutulursa reddedilir.',
                    style: TextStyle(color: Renkler.hata),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _pdfIndir(context),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF olarak indir / yazdır'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
