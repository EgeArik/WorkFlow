import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // "as pw": PDF widget'ları Flutter'ınkilerle karışmasın
import 'package:printing/printing.dart';

import '../modeller/bolum.dart';

// Bölüm QR kodunu kapıya asılacak A4 PDF'e çevirir.
class PdfServisi {
  // PDF'i oluşturur ve Android'in yazdırma ekranını açar.
  // Orada "PDF olarak kaydet" seçilirse dosya İndirilenler'e kaydedilir; yazıcı seçilirse yazdırılır.
  // Bu yöntem depolama izni gerektirmez.
  Future<void> qrPdfIndir(Bolum bolum) async {
    await Printing.layoutPdf(
      name: 'WorkFlow_${bolum.ad.replaceAll(' ', '_')}_QR', // önerilen dosya adı
      format: PdfPageFormat.a4,
      onLayout: (_) => _pdfOlustur(bolum),
    );
  }

  // Uint8List: bayt (0-255 arası sayı) listesi; bir dosyanın ham içeriği.
  Future<Uint8List> _pdfOlustur(Bolum bolum) async {
    // Varsayılan PDF fontunda ç, ğ, ı, ş, ö, ü yok. Noto Sans Türkçe karakterleri içerir.
    // İlk seferde internetten indirilir, sonra telefonda saklanır.
    final normal = await PdfGoogleFonts.notoSansRegular();
    final kalin = await PdfGoogleFonts.notoSansBold();

    final belge = pw.Document();
    belge.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(bolum.ad,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: kalin, fontSize: 48)),
              pw.SizedBox(height: 32),
              // BarcodeWidget: QR'ı VEKTÖR olarak çizer (kareler çizgi/şekil olarak).
              // Resim değil, bu yüzden ne kadar büyütülürse büyütülsün bulanıklaşmaz.
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: bolum.qrIcerigi,
                width: 380,
                height: 380,
              ),
              pw.SizedBox(height: 32),
              pw.Text('Giriş ve çıkış için okutun',
                  style: pw.TextStyle(font: normal, fontSize: 26)),
              pw.SizedBox(height: 12),
              pw.Text('WorkFlow',
                  style: pw.TextStyle(font: normal, fontSize: 14, color: PdfColors.grey600)),
            ],
          ),
        ),
      ),
    );
    return belge.save(); // PDF dosyasının baytları
  }
}
