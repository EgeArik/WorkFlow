import 'package:flutter/material.dart';

import '../../tema.dart';
import 'bolumler_ekrani.dart';
import 'genel_ekrani.dart';
import 'hareketler_ekrani.dart';
import 'personeller_ekrani.dart';

// Yönetim sekmesi: 4 alt sekme (Genel, Personeller, Bölümler, Hareketler).
// DefaultTabController: üstteki sekme çubuğu (TabBar) ile alttaki sayfaları (TabBarView)
// birbirine bağlar; birine basınca diğeri de değişir.
class YonetimEkrani extends StatelessWidget {
  const YonetimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim'),
          backgroundColor: Renkler.lacivert,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            // Dar ekranda "Personeller" yazısı kesiliyordu; sekmeler yazı kadar geniş olsun,
            // sığmazsa yana kaydırılsın.
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Genel'),
              Tab(text: 'Personeller'),
              Tab(text: 'Bölümler'),
              Tab(text: 'Hareketler'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GenelEkrani(),
            PersonellerEkrani(),
            BolumlerEkrani(),
            HareketlerEkrani(),
          ],
        ),
      ),
    );
  }
}
