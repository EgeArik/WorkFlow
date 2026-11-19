import 'package:flutter/material.dart';

import '../tema.dart';

// Profil fotoğrafı yerine kullanılan, baş harfleri gösteren yuvarlak avatar.
class BasHarfAvatar extends StatelessWidget {
  final String harfler;
  final double boyut;

  const BasHarfAvatar({super.key, required this.harfler, this.boyut = 52});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: boyut / 2,
      backgroundColor: Renkler.mavi,
      child: Text(
        harfler,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: boyut * 0.36, // yazı boyutu avatar boyutuna göre ölçeklenir
        ),
      ),
    );
  }
}
