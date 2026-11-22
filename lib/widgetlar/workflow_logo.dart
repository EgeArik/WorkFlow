import 'package:flutter/material.dart';

import '../tema.dart';

// Giriş ve kayıt ekranlarında ortak kullanılan logo + başlık bloğu.
// Widget: ekranda görünen her parça (yazı, buton, kutu...) Flutter'da bir widget'tır.
class WorkFlowLogo extends StatelessWidget {
  const WorkFlowLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Renkler.lacivert,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'WorkFlow',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Renkler.lacivert,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Personel takip sistemi',
          style: TextStyle(fontSize: 15, color: Renkler.griYazi),
        ),
      ],
    );
  }
}
