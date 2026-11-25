import 'package:flutter/material.dart';

import '../tema.dart';

// Profil fotoğrafı yerine kullanılan, baş harfleri gösteren köşeleri yuvarlak kare.
class BasHarfAvatar extends StatelessWidget {
  final String harfler;
  final double boyut;

  const BasHarfAvatar({super.key, required this.harfler, this.boyut = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boyut,
      height: boyut,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE7E4), // çok açık petrol
        borderRadius: BorderRadius.circular(boyut * 0.24),
      ),
      child: Text(
        harfler,
        style: TextStyle(
          color: Renkler.petrol,
          fontWeight: FontWeight.w500,
          fontSize: boyut * 0.36, // yazı boyutu avatar boyutuna göre ölçeklenir
        ),
      ),
    );
  }
}
