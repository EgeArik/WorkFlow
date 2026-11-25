import 'package:flutter/material.dart';

import '../modeller/kullanici.dart' show turkceBuyukHarf;

// "İçeride", "Giriş", "Çıkış" gibi küçük renkli etiketler.
// Arka plan, aynı rengin çok açık (saydam) hâlidir.
class Rozet extends StatelessWidget {
  final String yazi;
  final Color renk;

  const Rozet({super.key, required this.yazi, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12), // %12 opaklık: açık arka plan
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        turkceBuyukHarf(yazi), // tabela gibi büyük harf
        style: TextStyle(
          color: renk,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
