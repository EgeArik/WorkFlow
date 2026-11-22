import 'package:flutter/material.dart';

import '../servisler/auth_servisi.dart';
import '../tema.dart';

// Profil > Şifre Değiştir. Mevcut şifre + yeni şifre + yeni şifre tekrar.
class SifreDegistirEkrani extends StatefulWidget {
  const SifreDegistirEkrani({super.key});

  @override
  State<SifreDegistirEkrani> createState() => _SifreDegistirEkraniState();
}

class _SifreDegistirEkraniState extends State<SifreDegistirEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _mevcut = TextEditingController();
  final _yeni = TextEditingController();
  final _yeniTekrar = TextEditingController();
  bool _gizli = true;
  bool _yukleniyor = false;

  @override
  void dispose() {
    _mevcut.dispose();
    _yeni.dispose();
    _yeniTekrar.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;
    setState(() => _yukleniyor = true);
    final mesajlar = ScaffoldMessenger.of(context);
    final gezgin = Navigator.of(context);
    try {
      await AuthServisi().sifreDegistir(
        mevcutSifre: _mevcut.text,
        yeniSifre: _yeni.text,
      );
      mesajlar.showSnackBar(
        const SnackBar(
          content: Text('Şifreniz değiştirildi.'),
          backgroundColor: Renkler.basari,
        ),
      );
      gezgin.pop(); // başarılıysa Profil'e geri dön
    } on AuthHatasi catch (e) {
      mesajlar.showSnackBar(
        SnackBar(content: Text(e.mesaj), backgroundColor: Renkler.hata),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  // Üç şifre alanı aynı görünümde; tekrar yazmamak için ortak fonksiyon.
  Widget _sifreAlani(
    TextEditingController c,
    String etiket,
    String? Function(String?) kontrol, {
    TextInputAction eylem = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: _gizli,
        textInputAction: eylem,
        onFieldSubmitted: eylem == TextInputAction.done
            ? (_) => _kaydet()
            : null,
        decoration: InputDecoration(
          labelText: etiket,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        validator: kontrol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifre Değiştir'),
        backgroundColor: Renkler.lacivert,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formAnahtari,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sifreAlani(
                _mevcut,
                'Mevcut şifre',
                (d) =>
                    (d == null || d.isEmpty) ? 'Mevcut şifrenizi girin' : null,
              ),
              _sifreAlani(_yeni, 'Yeni şifre', (d) {
                if (d == null || d.length < 6) {
                  return 'Yeni şifre en az 6 karakter olmalı';
                }
                if (d == _mevcut.text) {
                  return 'Yeni şifre eskisiyle aynı olamaz';
                }
                return null;
              }),
              _sifreAlani(
                _yeniTekrar,
                'Yeni şifre (tekrar)',
                (d) => d != _yeni.text ? 'Şifreler eşleşmiyor' : null,
                eylem: TextInputAction.done,
              ),
              // Tek düğmeyle üç alanın da göster/gizle durumu değişir.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _gizli = !_gizli),
                  icon: Icon(_gizli ? Icons.visibility : Icons.visibility_off),
                  label: Text(_gizli ? 'Şifreleri göster' : 'Şifreleri gizle'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _yukleniyor ? null : _kaydet,
                child: _yukleniyor
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Şifreyi Değiştir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
