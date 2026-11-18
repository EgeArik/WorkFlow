import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../servisler/auth_servisi.dart';
import '../tema.dart';

// GEÇİCİ ana sayfa: giriş/kayıt işinin çalıştığını göstermek için.
// Gün 2'de yerini alt menülü gerçek ana sayfa alacak.
class GeciciAnaSayfa extends StatelessWidget {
  const GeciciAnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // snapshots(): dokümanı canlı dinler; Firestore'da değişince ekran kendiliğinden güncellenir.
    final kullaniciAkisi =
        FirebaseFirestore.instance.collection('kullanicilar').doc(uid).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkFlow'),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      // StreamBuilder: bir Stream'i dinler ve her yeni veri geldiğinde ekranı yeniden çizer.
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: kullaniciAkisi,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final veri = snapshot.data!.data()!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hoş geldiniz, ${veri['adSoyad']}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Görev: ${veri['gorev']}'),
                Text('Rol: ${veri['rol']}'),
                Text('E-posta: ${veri['eposta']}'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => AuthServisi().cikisYap(),
                  style: ElevatedButton.styleFrom(backgroundColor: Renkler.hata),
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
