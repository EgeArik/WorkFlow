import 'package:flutter/material.dart';

import '../servisler/auth_servisi.dart';
import '../tema.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _gorevController = TextEditingController();
  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();
  final _authServisi = AuthServisi();

  bool _sifreGizli = true;
  bool _yukleniyor = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _gorevController.dispose();
    _epostaController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (!_formAnahtari.currentState!.validate()) return;

    setState(() => _yukleniyor = true);
    try {
      await _authServisi.kayitOl(
        adSoyad: _adSoyadController.text,
        gorev: _gorevController.text,
        eposta: _epostaController.text,
        sifre: _sifreController.text,
      );
      // Kayıt olunca Firebase kullanıcıyı otomatik giriş yaptırır.
      // Bu ekranı kapatıyoruz; altta kalan yer ana sayfaya dönüşmüş olacak.
      if (mounted) Navigator.of(context).pop();
    } on AuthHatasi catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.mesaj), backgroundColor: Renkler.hata),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  // Boş bırakılamayan alanlar için ortak doğrulama fonksiyonu.
  String? _bosOlamaz(String? deger, String alanAdi) {
    if (deger == null || deger.trim().isEmpty) return '$alanAdi girin';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
        backgroundColor: Renkler.arkaPlan,
        foregroundColor: Renkler.lacivert,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formAnahtari,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bilgilerinizi girin. Hesabınız personel olarak oluşturulur.',
                  style: TextStyle(color: Renkler.griYazi),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _adSoyadController,
                  textCapitalization:
                      TextCapitalization.words, // her kelimenin ilk harfi büyük
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (d) => _bosOlamaz(d, 'Ad soyad'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gorevController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Görev',
                    hintText: 'Örn. Montaj operatörü',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (d) => _bosOlamaz(d, 'Görev'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _epostaController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (d) {
                    if (d == null || d.trim().isEmpty) return 'E-posta girin';
                    if (!d.contains('@')) return 'Geçerli bir e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sifreController,
                  obscureText: _sifreGizli,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _kayitOl(),
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    helperText: 'En az 6 karakter',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _sifreGizli ? Icons.visibility : Icons.visibility_off,
                      ),
                      tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                      onPressed: () =>
                          setState(() => _sifreGizli = !_sifreGizli),
                    ),
                  ),
                  validator: (d) {
                    if (d == null || d.isEmpty) return 'Şifre girin';
                    if (d.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _yukleniyor ? null : _kayitOl,
                  child: _yukleniyor
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Hesap Oluştur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
