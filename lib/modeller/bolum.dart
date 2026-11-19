import 'package:cloud_firestore/cloud_firestore.dart';

// QR içeriğinin sabit öneki. QR = "workflow:bolum:<bolumId>"
const qrOneki = 'workflow:bolum:';

// "bolumler" koleksiyonundaki bir bölüm (A Bölümü, Yemekhane...).
class Bolum {
  final String id; // rastgele doküman kimliği; QR'ın içinde bu var
  final String ad;
  final bool aktif; // pasif bölümler okutulamaz ama silinmez (eski kayıtlar bozulmasın)

  const Bolum({required this.id, required this.ad, required this.aktif});

  factory Bolum.firestoredan(DocumentSnapshot<Map<String, dynamic>> dokuman) {
    final veri = dokuman.data()!;
    return Bolum(
      id: dokuman.id,
      ad: veri['ad'] as String? ?? '',
      aktif: veri['aktif'] as bool? ?? false,
    );
  }

  // Bu bölümün QR koduna yazılacak metin.
  String get qrIcerigi => '$qrOneki$id';
}
