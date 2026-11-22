import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../tema.dart';

// İnternet bağlantısı yoksa kırmızı "İnternet bağlantısı yok" şeridi gösterir (Gün 7).
// Bağlantı varken hiç yer kaplamaz. Alt menünün hemen üstünde durur; her sekmede görünür.
class InternetSeridi extends StatefulWidget {
  const InternetSeridi({super.key});

  @override
  State<InternetSeridi> createState() => _InternetSeridiState();
}

class _InternetSeridiState extends State<InternetSeridi> {
  // onConnectivityChanged: Wi-Fi / mobil veri açılıp kapandıkça yeni değer gönderen akış.
  late final Stream<List<ConnectivityResult>> _akis =
      Connectivity().onConnectivityChanged;
  // Akış ilk değişikliğe kadar değer göndermeyebilir; açılıştaki durumu ayrıca sorarız.
  late final Future<List<ConnectivityResult>> _ilkDurum = Connectivity()
      .checkConnectivity();

  // Listede sadece "none" varsa hiçbir ağa bağlı değiliz.
  bool _baglantiYok(List<ConnectivityResult>? sonuc) =>
      sonuc != null && sonuc.every((r) => r == ConnectivityResult.none);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: _ilkDurum,
      builder: (context, ilk) => StreamBuilder<List<ConnectivityResult>>(
        stream: _akis,
        builder: (context, snapshot) {
          // Akıştan değer geldiyse onu, gelmediyse açılıştaki durumu kullan.
          final sonuc = snapshot.data ?? ilk.data;
          if (!_baglantiYok(sonuc)) return const SizedBox.shrink(); // görünmez
          return Container(
            width: double.infinity,
            color: Renkler.hata,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'İnternet bağlantısı yok',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
