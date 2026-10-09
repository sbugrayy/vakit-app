#!/usr/bin/env python3
"""Durum çubuğu dakika simgelerini üretir: ic_stat_minute_00.xml … _60.xml.

Vakte son 60 dakikada kalıcı bildirimin küçük simgesi bir cami silüetidir;
gövdesinde kalan dakika yazar (Ezan Vakti Pro'daki gibi, Buğra'nın isteği).

Neden çalışma anında bitmap değil de 61 ayrı vektör kaynak:
- Durum çubuğu simgeyi ~14 dp'de çiziyor. Vektör kaynağı sistem tam o piksel
  boyutunda rasterleştiriyor, kenarlar keskin kalıyor. 24 dp'de çizilip
  küçültülen bitmap telefonda yumuşak ve tırtıklı görünüyordu (2026-10-04).
- Rakamlar sistem fontuna bağlı kalmıyor; Samsung'un yazı tipi ayarı ya da
  OEM fontu simgeyi bozamıyor.

Tasarım:
- Silüet tek parça: minareler, gövde, ana kubbe, omuzlar ve alem shapely ile
  birleştiriliyor. Ayrı parçalar arasında kenar yumuşatma dikişi oluşmuyor.
- Rakamlar Roboto Medium'un glif konturlarıdır (tool/fonts/, Apache 2.0).
  Hepsi aynı ölçekte; dakika değiştikçe rakam boyu zıplamaz.
- Rakamlar aynı yolda `fillType="evenOdd"` ile silüetten oyulur. "0", "6",
  "8", "9" gibi rakamların iç boşlukları evenOdd ile yeniden dolar.

Gereken: Python 3, fontTools, shapely. Önizleme için ayrıca Pillow ve numpy.

Kullanım:
  python tool/gen_status_icons.py              # dosyaları yaz
  python tool/gen_status_icons.py --check      # diskteki dosyalar güncel mi
  python tool/gen_status_icons.py --preview out.png

Üretilen dosyalar elle düzenlenmez; tasarım değişirse bu betik değişir ve
yeniden çalıştırılır.
"""
import argparse
import math
import pathlib
import sys

from fontTools.pens.basePen import BasePen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.ttLib import TTFont
from shapely.geometry import Polygon, box
from shapely.ops import unary_union

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "tool" / "fonts" / "Roboto-Medium.ttf"
OUT_DIR = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable"
MINUTES = range(0, 61)

# Silüet (24×24 görünüm alanı, y aşağı). Oranlar telefondaki Ezan Vakti
# simgesinden ölçülüp yeniden çizildi; kopya değil, aynı düzen.
MINARET_X0, MINARET_X1 = 1.15, 3.45  # sol minare; sağdaki simetrik
BASE_Y = 23.7
SPIRE_TIP_Y, SPIRE_BASE_Y = 0.3, 4.8
BALCONY_Y, BALCONY_H, BALCONY_W = 6.4, 0.7, 0.35  # şerefe
BODY_TOP_Y = 11.1
DOME_R, DOME_CY = 6.5, 10.8
# Omuz: kubbenin yanından minareye inen içbükey geçiş.
SHOULDER_X, SHOULDER_Y = 5.6, 7.6  # merkezden yatay uzaklık, y
SHOULDER_END_Y, SHOULDER_POW = 10.5, 0.55
ALEM_W, ALEM_TOP_Y = 0.75, 1.2

# Rakam kutusu: gövdenin içi, minarelerin arası. 2026-10-05'te 0,8 birim
# yukarı alındı (Buğra: rakamlar tabana çok yakındı). Alt boşluk 0,75 →
# 1,55 birim; rakamın üstü kubbe tabanına değmeden gövde üstünde kalıyor.
DIGIT_BOX = (3.75, 10.8, 20.25, 22.3)

# Görünüm alanı birimi başına 1/100 hassasiyet yeterli: 24 birim telefonda
# ~39 px, yani 0,01 birim ~0,02 px.
SIMPLIFY_TOLERANCE = 0.01


def ellipse(cx, cy, rx, ry, n=192):
    return Polygon([
        (cx + rx * math.cos(2 * math.pi * i / n),
         cy + ry * math.sin(2 * math.pi * i / n))
        for i in range(n)
    ])


def silhouette():
    parts = []
    for x0, x1 in ((MINARET_X0, MINARET_X1), (24 - MINARET_X1, 24 - MINARET_X0)):
        cx = (x0 + x1) / 2
        parts.append(Polygon([
            (x0, BASE_Y), (x0, SPIRE_BASE_Y), (cx, SPIRE_TIP_Y),
            (x1, SPIRE_BASE_Y), (x1, BASE_Y),
        ]))
        parts.append(box(x0 - BALCONY_W, BALCONY_Y,
                         x1 + BALCONY_W, BALCONY_Y + BALCONY_H))
    parts.append(box(MINARET_X0, BODY_TOP_Y, 24 - MINARET_X0, BASE_Y))
    parts.append(ellipse(12, DOME_CY, DOME_R, DOME_R)
                 .intersection(box(0, 0, 24, BODY_TOP_Y + 0.01)))
    end_x = 12 - MINARET_X1
    curve = []
    for i in range(25):
        t = i / 24
        curve.append((SHOULDER_X + (end_x - SHOULDER_X) * t,
                      SHOULDER_Y + (SHOULDER_END_Y - SHOULDER_Y) * t ** SHOULDER_POW))
    for sign in (-1, 1):
        poly = [(12 + sign * x, y) for x, y in curve]
        poly += [(12 + sign * end_x, BODY_TOP_Y + 0.02),
                 (12 + sign * SHOULDER_X * 0.9, BODY_TOP_Y + 0.02)]
        parts.append(Polygon(poly).buffer(0))
    parts.append(box(12 - ALEM_W / 2, ALEM_TOP_Y, 12 + ALEM_W / 2, BODY_TOP_Y))
    shape = unary_union(parts).simplify(SIMPLIFY_TOLERANCE)
    if shape.geom_type != "Polygon" or len(shape.interiors) != 0:
        sys.exit("HATA: silüet tek parça ve deliksiz olmalı")
    return shape


def fmt(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


class GlyphPen(BasePen):
    """Glifi dönüştürür; SVG yol komutlarını ve düzleştirilmiş konturları toplar."""

    def __init__(self, glyph_set, transform):
        super().__init__(glyph_set)
        self.transform = transform
        self.commands = []
        self.contours = []
        self._points = None
        self._last = None

    def _moveTo(self, pt):
        x, y = self.transform(pt)
        self.commands.append(f"M{fmt(x)},{fmt(y)}")
        self._points = [(x, y)]
        self._last = (x, y)

    def _lineTo(self, pt):
        x, y = self.transform(pt)
        self.commands.append(f"L{fmt(x)},{fmt(y)}")
        self._points.append((x, y))
        self._last = (x, y)

    def _qCurveToOne(self, pt1, pt2):
        (x1, y1), (x2, y2) = self.transform(pt1), self.transform(pt2)
        self.commands.append(f"Q{fmt(x1)},{fmt(y1)} {fmt(x2)},{fmt(y2)}")
        x0, y0 = self._last
        for i in range(1, 9):
            t = i / 8
            self._points.append((
                (1 - t) ** 2 * x0 + 2 * (1 - t) * t * x1 + t * t * x2,
                (1 - t) ** 2 * y0 + 2 * (1 - t) * t * y1 + t * t * y2,
            ))
        self._last = (x2, y2)

    def _curveToOne(self, pt1, pt2, pt3):
        raise NotImplementedError("TrueType glifinde kübik eğri beklenmiyor")

    def _closePath(self):
        self.commands.append("Z")
        self.contours.append(self._points)
        self._points = None

    _endPath = _closePath


class Digits:
    def __init__(self):
        font = TTFont(FONT)
        self.glyphs = font.getGlyphSet()
        self.cmap = font.getBestCmap()
        zero = self._bounds("0")
        self.baseline = zero[1]
        figure_h = zero[3] - zero[1]
        x0, y0, x1, y1 = DIGIT_BOX
        # Ortak ölçek: en geniş sayı da kutuya sığsın, bütün simgelerde
        # rakam boyu aynı kalsın.
        scale = (y1 - y0) / figure_h
        widest = max(self._ink(str(m))[1] - self._ink(str(m))[0] for m in MINUTES)
        self.scale = min(scale, (x1 - x0) / widest)

    def _name(self, ch):
        return self.cmap[ord(ch)]

    def _bounds(self, ch):
        pen = BoundsPen(self.glyphs)
        self.glyphs[self._name(ch)].draw(pen)
        return pen.bounds

    def _ink(self, text):
        """Metnin font birimlerinde mürekkep başlangıcı ve bitişi."""
        pen_x, left, right = 0, None, None
        for ch in text:
            b = self._bounds(ch)
            left = pen_x + b[0] if left is None else left
            right = pen_x + b[2]
            pen_x += self.glyphs[self._name(ch)].width
        return left, right

    def render(self, text):
        x0, _, x1, y1 = DIGIT_BOX
        s = self.scale
        left, right = self._ink(text)
        origin_x = (x0 + x1) / 2 - (right - left) * s / 2 - left * s
        commands, contours, pen_x = [], [], 0
        for ch in text:
            def transform(pt, px=pen_x):
                return (origin_x + (pt[0] + px) * s,
                        y1 - (pt[1] - self.baseline) * s)
            pen = GlyphPen(self.glyphs, transform)
            self.glyphs[self._name(ch)].draw(pen)
            commands += pen.commands
            contours += pen.contours
            pen_x += self.glyphs[self._name(ch)].width
        return commands, contours


def ring_commands(ring):
    pts = list(ring.coords)[:-1]
    out = [f"M{fmt(pts[0][0])},{fmt(pts[0][1])}"]
    out += [f"L{fmt(x)},{fmt(y)}" for x, y in pts[1:]]
    return out + ["Z"]


def check_geometry(shape, contours, minute):
    """evenOdd'un doğru oyması için: rakam konturları silüetin içinde ve
    birbirini kısmen kesmiyor (iç içe olabilir)."""
    polys = [Polygon(c) for c in contours]
    for p in polys:
        if not shape.contains(p):
            sys.exit(f"HATA: {minute} rakamı silüetin dışına taşıyor")
    for i, a in enumerate(polys):
        for b in polys[i + 1:]:
            if a.intersection(b).area > 1e-6 and not (a.contains(b) or b.contains(a)):
                sys.exit(f"HATA: {minute} konturları kesişiyor; evenOdd yanlış oyar")


XML = """<!-- Üretilmiş dosya, elle düzenleme: tool/gen_status_icons.py -->
<!-- Durum çubuğu simgesi, vakte {minute} dakika kala. Tek renkli maske; sistem -->
<!-- yalnız alfayı kullanır, beyaz dolgu bu yüzden serbest. Rakamlar Roboto -->
<!-- Medium glifleri (Apache 2.0, tool/fonts/) ve evenOdd ile oyuluyor. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:fillType="evenOdd"
        android:pathData="{path}" />
</vector>
"""


def build():
    shape = silhouette()
    sil_cmds = ring_commands(shape.exterior)
    digits = Digits()
    files = {}
    rendered = {}
    for minute in MINUTES:
        commands, contours = digits.render(str(minute))
        check_geometry(shape, contours, minute)
        path = "".join(sil_cmds + commands)
        files[f"ic_stat_minute_{minute:02d}.xml"] = XML.format(minute=minute, path=path)
        rendered[minute] = [list(shape.exterior.coords)] + contours
    return files, rendered


def write_preview(rendered, out, px=39, zoom=4):
    import numpy as np
    from PIL import Image, ImageDraw

    def alpha(polys, ss=16):
        size = px * ss
        k = size / 24
        acc = np.zeros((size, size), bool)
        for poly in polys:
            m = Image.new("1", (size, size), 0)
            ImageDraw.Draw(m).polygon([(x * k, y * k) for x, y in poly], fill=1)
            acc ^= np.array(m)
        return acc.reshape(px, ss, px, ss).mean(axis=(1, 3))

    cols = 11
    rows = math.ceil(len(rendered) / cols)
    cell = px + 4
    sheet = Image.new("L", (cols * cell, rows * cell), 24)
    for i, minute in enumerate(sorted(rendered)):
        a = (alpha(rendered[minute]) * 255).astype("uint8")
        bg = Image.new("L", (px, px), 24)
        bg.paste(255, (0, 0), Image.fromarray(a))
        sheet.paste(bg, ((i % cols) * cell + 2, (i // cols) * cell + 2))
    sheet = sheet.resize((sheet.width * zoom, sheet.height * zoom), Image.LANCZOS)
    sheet.save(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true",
                        help="dosyaları yazma; diskteki hali güncel değilse 1 ile çık")
    parser.add_argument("--preview", metavar="PNG",
                        help="bütün simgelerin önizlemesini (telefondaki boyut ×4) yaz")
    args = parser.parse_args()
    # Windows konsolu cp1254/cp1252 olabilir; Türkçe çıktı bozulmasın.
    sys.stdout.reconfigure(encoding="utf-8")

    files, rendered = build()
    if args.preview:
        write_preview(rendered, args.preview)
        print(f"önizleme: {args.preview}")
    if args.check:
        stale = [name for name, text in files.items()
                 if not (OUT_DIR / name).exists()
                 or (OUT_DIR / name).read_text(encoding="utf-8") != text]
        if stale:
            print("HATA: güncel değil:", ", ".join(stale))
            sys.exit(1)
        print(f"OK: {len(files)} simge güncel.")
        return
    for name, text in files.items():
        (OUT_DIR / name).write_text(text, encoding="utf-8", newline="\n")
    print(f"{len(files)} simge yazıldı: {OUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
