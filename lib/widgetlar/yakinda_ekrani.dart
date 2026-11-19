import 'package:flutter/material.dart';

import '../tema.dart';

// Henüz yapılmamış sekmeler için geçici ekran ("Gün 3'te eklenecek" gibi).
class YakindaEkrani extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final String aciklama;

  const YakindaEkrani({
    super.key,
    required this.baslik,
    required this.ikon,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(baslik),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, size: 64, color: Renkler.griYazi),
              const SizedBox(height: 16),
              Text(
                aciklama,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Renkler.griYazi, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
