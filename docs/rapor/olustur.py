# WorkFlow proje raporunu oluşturur.
# kaynak/ klasöründeki parçaları birleştirir, kod parçalarını gerçek dosyalardan alıp renklendirir,
# görsel numaralarını verir, Microsoft Edge ile PDF'e çevirir ve içindekiler sayfa numaralarını doldurur.
# Çalıştırma:  python docs/rapor/olustur.py
import html
import re
import subprocess
import sys
from pathlib import Path

RAPOR = Path(__file__).resolve().parent
PROJE = RAPOR.parent.parent
KAYNAK = RAPOR / "kaynak"
CIKTI_HTML = RAPOR / "rapor.html"
CIKTI_PDF = RAPOR / "WorkFlow_Proje_Raporu.pdf"
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# ---------------- Kod renklendirme ----------------
DART_ANAHTAR = set("""import as show class final const var return if else for in async await try catch on
throw switch case default new extends implements with static required late void null true false this
super factory get set break continue while do enum rethrow is""".split())
KURAL_ANAHTAR = set("""rules_version service match allow if read write create update delete function let
return true false null in is""".split())

DESEN = re.compile(
    r"(?P<yorum>//[^\n]*)"
    r"|(?P<metin>'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\")"
    r"|(?P<sayi>\b\d+(?:\.\d+)?\b)"
    r"|(?P<kelime>[A-Za-z_][A-Za-z0-9_]*)"
    r"|(?P<diger>[\s\S])"
)


def renklendir(kod: str, kurallar: bool) -> str:
    anahtar = KURAL_ANAHTAR if kurallar else DART_ANAHTAR
    parcalar = []
    for m in DESEN.finditer(kod):
        tur = m.lastgroup
        deger = html.escape(m.group())
        if tur == "kelime":
            kelime = m.group()
            sonraki = kod[m.end():m.end() + 1]
            if kelime in anahtar:
                tur = "anahtar"
            elif kelime[0].isupper():
                tur = "tip"
            elif sonraki == "(":
                tur = "fonk"
            else:
                tur = "diger"
        if tur == "diger":
            parcalar.append(deger)
        else:
            parcalar.append(f'<span class="k-{tur}">{deger}</span>')
    return "".join(parcalar)


def kod_blogu(dosya: str, aralik: str, baslik: str) -> str:
    yol = PROJE / dosya
    satirlar = yol.read_text(encoding="utf-8").splitlines()
    bas, son = (int(x) for x in aralik.split("-"))
    secilen = satirlar[bas - 1:son]
    # Ortak girintiyi kaldır
    girinti = min((len(s) - len(s.lstrip()) for s in secilen if s.strip()), default=0)
    secilen = [s[girinti:] for s in secilen]
    kurallar = dosya.endswith(".rules")
    govde = renklendir("\n".join(secilen), kurallar).split("\n")
    numaralar = "\n".join(str(n) for n in range(bas, son + 1))
    sinif = "kod uzun" if son - bas > 24 else "kod"
    return (
        f'<figure class="{sinif}"><div class="kod-pencere">'
        '<div class="kod-ust"><span class="nokta n1"></span><span class="nokta n2"></span>'
        f'<span class="nokta n3"></span><span class="kod-dosya">{html.escape(dosya)}</span>'
        f'<span class="kod-satir">satır {bas}–{son}</span></div>'
        f'<div class="kod-govde"><pre class="kod-no">{numaralar}</pre>'
        f'<pre class="kod-metin">{chr(10).join(govde)}</pre></div></div>'
        f'<figcaption>{baslik}</figcaption></figure>'
    )


# ---------------- Tekrar eden çizim parçaları ----------------
IKON = {  # 24x24 basit çizgi ikonlar
    "ev": '<path d="M4 11 12 4l8 7v9h-5v-6H9v6H4z"/>',
    "qr": '<path d="M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h2v2h-2zM18 14h2v2h-2zM14 18h2v2h-2zM18 18h2v2h-2z"/>',
    "yonetim": '<path d="M12 3 5 6v5c0 4.5 3 8 7 10 4-2 7-5.5 7-10V6z"/>',
    "gecmis": '<path d="M12 5a7 7 0 1 1-7 7M12 8v4l3 2M5 5v4h4"/>',
    "profil": '<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c1-4 4-6 8-6s7 2 8 6"/>',
}
MENU_ADLARI = [("ev", "Ana Sayfa"), ("qr", "QR Tara"), ("yonetim", "Yönetim"), ("gecmis", "Geçmiş"), ("profil", "Profil")]


def alt_menu(rol: str, secili: str) -> str:
    ogeler = [m for m in MENU_ADLARI if rol == "yonetici" or m[0] != "yonetim"]
    parcalar = []
    for anahtar, ad in ogeler:
        sinif = ' class="sec"' if anahtar == secili else ""
        parcalar.append(
            f'<div{sinif}><span class="ik"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
            f'stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round">{IKON[anahtar]}</svg></span>{ad}</div>'
        )
    return '<div class="alt-menu">' + "".join(parcalar) + "</div>"


def logo(boyut: int, koyu: bool) -> str:
    k = max(2, round(boyut * 0.06))
    isaret = (f'<div class="isaret{" beyaz" if koyu else ""}" style="width:{boyut}px;height:{boyut}px;--k:{k}px">'
              f'<i class="a"></i><i class="b"></i><span style="font-size:{boyut * 0.55:.0f}px">W</span></div>')
    yazi = (f'<div class="logo-yazi{" koyu" if koyu else ""}" style="font-size:{boyut * 0.62:.0f}px">'
            f'Work<em>Flow</em></div>')
    return (f'<div style="display:flex;align-items:center;gap:{boyut * 0.25:.0f}px">{isaret}{yazi}</div>')


def qr_cizim(boyut: int, tohum: int = 7) -> str:
    # Görsel amaçlı QR deseni (köşe kareleri gerçek QR gibi). Okutulamaz.
    import random
    rnd = random.Random(tohum)
    n = 25
    hucre = boyut / n
    kareler = []

    def bulucu(x, y):
        return (f'<rect x="{x}" y="{y}" width="7" height="7" fill="#111"/>'
                f'<rect x="{x + 1}" y="{y + 1}" width="5" height="5" fill="#fff"/>'
                f'<rect x="{x + 2}" y="{y + 2}" width="3" height="3" fill="#111"/>')

    for y in range(n):
        for x in range(n):
            koşe = (x < 8 and y < 8) or (x > n - 9 and y < 8) or (x < 8 and y > n - 9)
            if not koşe and rnd.random() < 0.48:
                kareler.append(f'<rect x="{x}" y="{y}" width="1.02" height="1.02" fill="#111"/>')
    icerik = "".join(kareler) + bulucu(0, 0) + bulucu(n - 7, 0) + bulucu(0, n - 7)
    return (f'<svg class="qr-cizim" width="{boyut}" height="{boyut}" viewBox="-1 -1 {n + 2} {n + 2}">'
            f'<rect x="-1" y="-1" width="{n + 2}" height="{n + 2}" fill="#fff"/>{icerik}</svg>')


def durum_cubugu(tur: str = "") -> str:
    sinif = f" {tur}" if tur else ""
    return (f'<div class="durum-cubugu{sinif}"><span>09:41</span><span class="s">'
            '<i style="height:4px"></i><i style="height:6px"></i><i style="height:8px"></i>'
            '<span style="margin-left:4px">100%</span></span></div>')


def parcalari_uygula(govde: str) -> str:
    govde = re.sub(r"<!--MENU\s+(\w+)\s+(\w+)\s*-->", lambda m: alt_menu(m.group(1), m.group(2)), govde)
    govde = re.sub(r"<!--LOGO\s+(\d+)\s+(koyu|acik)\s*-->", lambda m: logo(int(m.group(1)), m.group(2) == "koyu"), govde)
    govde = re.sub(r"<!--QR\s+(\d+)(?:\s+(\d+))?\s*-->",
                   lambda m: qr_cizim(int(m.group(1)), int(m.group(2) or 7)), govde)
    govde = re.sub(r"<!--DURUM\s*(\w*)\s*-->", lambda m: durum_cubugu(m.group(1)), govde)
    return govde


# ---------------- Birleştirme ----------------
def birlestir() -> str:
    stil = (KAYNAK / "stil.css").read_text(encoding="utf-8")
    govde = "\n".join(p.read_text(encoding="utf-8") for p in sorted(KAYNAK.glob("*.html")))
    govde = parcalari_uygula(govde)
    # <!--KOD dosya | 10-20 | Başlık-->
    govde = re.sub(
        r"<!--KOD\s+(.+?)\s*\|\s*(\d+-\d+)\s*\|\s*(.+?)-->",
        lambda m: kod_blogu(m.group(1).strip(), m.group(2), m.group(3).strip()),
        govde,
    )
    # Görsel numaraları: figcaption'ı olan her figure sırayla numaralanır.
    sayac = 0
    kimlikler = {}

    def numarala(m):
        nonlocal sayac
        sayac += 1
        kimlik = re.search(r'id="([^"]+)"', m.group(1))
        if kimlik:
            kimlikler[kimlik.group(1)] = sayac
        return f'{m.group(1)}<figcaption><b>Görsel {sayac}:</b> '

    govde = re.sub(r"(<figure[^>]*>(?:(?!</figure>)[\s\S])*?)<figcaption>", numarala, govde)
    # [[g-kimlik]] -> "Görsel 7"
    govde = re.sub(r"\[\[(g-[a-z0-9-]+)\]\]", lambda m: f"Görsel {kimlikler.get(m.group(1), '?')}", govde)
    return (
        '<!doctype html><html lang="tr"><head><meta charset="utf-8">'
        f"<title>WorkFlow Proje Raporu</title><style>{stil}</style></head><body>{govde}</body></html>"
    )


def pdf_yap(icerik: str):
    import time
    CIKTI_HTML.write_text(icerik, encoding="utf-8")
    gecici = RAPOR / "_yazdiriliyor.pdf"
    gecici.unlink(missing_ok=True)
    subprocess.run(
        [EDGE, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
         f"--print-to-pdf={gecici}", CIKTI_HTML.as_uri()],
        capture_output=True,
    )
    # Edge PDF'i arka planda yazar; dosya oluşup boyutu sabitlenene kadar bekle.
    onceki = -1
    for _ in range(120):
        time.sleep(0.5)
        if gecici.exists() and gecici.stat().st_size == onceki and onceki > 0:
            break
        onceki = gecici.stat().st_size if gecici.exists() else -1
    else:
        raise SystemExit("PDF oluşturulamadı")
    CIKTI_PDF.unlink(missing_ok=True)
    gecici.rename(CIKTI_PDF)


def sayfa_metinleri():
    cikti = subprocess.run(["pdftotext", "-layout", "-enc", "UTF-8", str(CIKTI_PDF), "-"],
                           capture_output=True, check=True).stdout.decode("utf-8")
    return cikti.split("\f")


def sade(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip().lower()


def icindekiler_doldur(icerik: str, sayfalar) -> str:
    # <span class="ic-no" data-ara="2.5 Firebase Bağlantısı"></span>
    def bul(m):
        aranan = sade(html.unescape(m.group(1)))
        for i, metin in enumerate(sayfalar[2:], start=3):  # kapak ve içindekiler hariç
            if aranan in sade(metin):
                return f'<span class="ic-no" data-ara="{m.group(1)}">{i}</span>'
        return f'<span class="ic-no" data-ara="{m.group(1)}">–</span>'

    return re.sub(r'<span class="ic-no" data-ara="([^"]+)"></span>', bul, icerik)


if __name__ == "__main__":
    icerik = birlestir()
    pdf_yap(icerik)
    icerik = icindekiler_doldur(icerik, sayfa_metinleri())
    pdf_yap(icerik)
    print(f"Hazır: {CIKTI_PDF}  ({len(sayfa_metinleri()) - 1} sayfa)")
    sys.exit(0)
