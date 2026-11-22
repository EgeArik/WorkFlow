import 'package:flutter/material.dart';

import '../servisler/auth_servisi.dart';
import '../tema.dart';
import '../widgetlar/workflow_logo.dart';
import 'kayit_ekrani.dart';

// StatefulWidget: içinde değişen bilgi (yükleniyor mu, şifre görünüyor mu) tutan ekran.
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  // Form anahtarı: formdaki tüm alanları tek seferde doğrulamamızı sağlar.
  final _formAnahtari = GlobalKey<FormState>();
  // Controller: yazı alanına yazılan metni okumamızı sağlar.
  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();
  final _authServisi = AuthServisi();

  bool _sifreGizli = true;
  bool _yukleniyor = false;

  @override
  void dispose() {
    // Ekran kapanınca controller'ları serbest bırakırız (bellek sızıntısı olmasın).
    _epostaController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    // Alanlardan biri hatalıysa (boş vb.) Firebase'e hiç gitmeyiz.
    if (!_formAnahtari.currentState!.validate()) return;

    setState(() => _yukleniyor = true);
    try {
      await _authServisi.girisYap(
        eposta: _epostaController.text,
        sifre: _sifreController.text,
      );
      // Başarılı olursa bir şey yapmamıza gerek yok: main.dart'taki oturum dinleyicisi
      // kullanıcının giriş yaptığını görüp ana sayfayı otomatik açar.
    } on AuthHatasi catch (e) {
      _hataGoster(e.mesaj);
    } finally {
      // "mounted": ekran hâlâ açık mı? Kapandıysa setState çağırmak hata verir.
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _hataGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Renkler.hata),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // SingleChildScrollView: klavye açılınca ekran taşarsa kaydırılabilsin.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formAnahtari,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const WorkFlowLogo(),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _epostaController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (deger) {
                    if (deger == null || deger.trim().isEmpty)
                      return 'E-posta girin';
                    if (!deger.contains('@'))
                      return 'Geçerli bir e-posta girin';
                    return null; // null = hata yok
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sifreController,
                  obscureText: _sifreGizli,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _girisYap(),
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    // Şifreyi göster/gizle butonu
                    suffixIcon: IconButton(
                      icon: Icon(
                        _sifreGizli ? Icons.visibility : Icons.visibility_off,
                      ),
                      tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                      onPressed: () =>
                          setState(() => _sifreGizli = !_sifreGizli),
                    ),
                  ),
                  validator: (deger) =>
                      (deger == null || deger.isEmpty) ? 'Şifre girin' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _yukleniyor ? null : _girisYap,
                  child: _yukleniyor
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Giriş Yap'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _yukleniyor
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const KayitEkrani(),
                          ),
                        ),
                  child: const Text('Hesabınız yok mu? Hesap oluştur'),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Doğru İnsan, Doğru Bölüm, Daha Verimli Üretim.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Renkler.griYazi,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
