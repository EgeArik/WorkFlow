import 'package:flutter/material.dart';

import '../tema.dart';

// LOGO İŞARETİ: içinde "W" olan kare. Sol üst ve sağ alt köşedeki hardal çizgiler
// QR tarama çerçevesini hatırlatır. Resim dosyası yok; tamamen kodla çizilir.
// koyuZemin: true ise logo petrol renkli bir zeminin üstünde duruyordur (kare beyaz olur).
class LogoIsareti extends StatelessWidget {
  final double boyut;
  final bool koyuZemin;

  const LogoIsareti({super.key, this.boyut = 52, this.koyuZemin = false});

  @override
  Widget build(BuildContext context) {
    final kose = boyut * 0.23; // köşe çizgisinin uzunluğu
    final kalinlik = boyut * 0.06;
    final bosluk = boyut * 0.12;
    final cizgi = BorderSide(color: Renkler.hardal, width: kalinlik);
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(
        color: koyuZemin ? Colors.white : Renkler.petrol,
        borderRadius: BorderRadius.circular(boyut * 0.2),
      ),
      // Stack: çocukları üst üste koyar; Positioned ile her birinin yeri ayarlanır.
      child: Stack(
        children: [
          Positioned(
            top: bosluk,
            left: bosluk,
            child: Container(
              width: kose,
              height: kose,
              decoration: BoxDecoration(
                border: Border(top: cizgi, left: cizgi),
              ),
            ),
          ),
          Positioned(
            bottom: bosluk,
            right: bosluk,
            child: Container(
              width: kose,
              height: kose,
              decoration: BoxDecoration(
                border: Border(bottom: cizgi, right: cizgi),
              ),
            ),
          ),
          Center(
            child: Text(
              'W',
              style: TextStyle(
                fontSize: boyut * 0.55,
                fontWeight: FontWeight.w600,
                height: 1,
                color: koyuZemin ? Renkler.petrol : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// LOGO YAZISI: "Work" yarı kalın, "Flow" ince ve renkli.
// Text.rich: tek yazının içinde farklı biçimli parçalar (TextSpan) kullanmamızı sağlar.
class LogoYazisi extends StatelessWidget {
  final double boyut;
  final bool koyuZemin;

  const LogoYazisi({super.key, this.boyut = 32, this.koyuZemin = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: boyut, height: 1),
        children: [
          TextSpan(
            text: 'Work',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: koyuZemin ? Colors.white : Renkler.yazi,
            ),
          ),
          TextSpan(
            text: 'Flow',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: koyuZemin ? Renkler.hardal : Renkler.petrol,
            ),
          ),
        ],
      ),
    );
  }
}

// İşaret + yazı yan yana. Ana sayfanın üst şeridinde ve giriş ekranında kullanılır.
class LogoSatiri extends StatelessWidget {
  final double boyut; // işaretin boyutu; yazı buna göre ölçeklenir
  final bool koyuZemin;

  const LogoSatiri({super.key, this.boyut = 52, this.koyuZemin = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // sadece içindekiler kadar yer kapla
      children: [
        LogoIsareti(boyut: boyut, koyuZemin: koyuZemin),
        SizedBox(width: boyut * 0.25),
        LogoYazisi(boyut: boyut * 0.62, koyuZemin: koyuZemin),
      ],
    );
  }
}

// Giriş ve kayıt ekranlarındaki logo bloğu: logo satırı + altında kısa açıklama.
class WorkFlowLogo extends StatelessWidget {
  const WorkFlowLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LogoSatiri(),
        SizedBox(height: 10),
        Text(
          'Bölüm giriş-çıkış takibi',
          style: TextStyle(fontSize: 15, color: Renkler.griYazi),
        ),
      ],
    );
  }
}
