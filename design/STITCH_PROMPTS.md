# Stitch Prompt'ları — Vakit

Faz 1 (Tasarım) için Google Stitch'e verilecek prompt'lar. Claude yazar,
Buğra Stitch'te üretir. Çıktılar `design/stitch/` altına girer ve oradan
`stitch-to-flutter` skill'iyle agy'ye gider.

## Nasıl kullanılır

1. Stitch'te **Vakit** adında bir proje aç, cihaz olarak **Mobile** seç.
2. Önce aşağıdaki **"0. Tasarım sistemi"** prompt'unu ver. Bu, renk, yazı ve
   bileşen dilini sabitler.
3. Ekran prompt'larını sırayla ver. Her ekran için önce açık tema üretilir.
   Beğendiğin hali bulunca aynı ekranın **koyu** halini de iste: "Create the
   dark theme version of this screen with the same layout".
4. Stil seçimi: "Stil varyantları" bölümündeki üç yönü Ana Sayfa üzerinde dene,
   birini seç. Diğer ekranları seçilen yönle üret.
5. Dışa aktarım. Her ekran için klasör aç, ekranın HTML'ini ve görüntüsünü koy:

   ```
   design/stitch/
     DESIGN.md                 ← Stitch'in tasarım sistemi dışa aktarımı
     ana_sayfa/      code.html  screen.png  screen_dark.png
     kible/          code.html  screen.png  screen_dark.png
     aylik_vakitler/ code.html  screen.png  screen_dark.png
     konum_secimi/   code.html  screen.png  screen_dark.png
     ayarlar/        code.html  screen.png  screen_dark.png
     izinler/        code.html  screen.png  screen_dark.png
     bildirim/       screen.png  screen_dark.png   (HTML gerekmez)
   ```

   Klasör adlarını Stitch farklı verirse (bozuk Türkçe karakterli olabilir)
   olduğu gibi bırak; eşleştirmeyi skill yapar.

Prompt'lar İngilizce: Stitch İngilizce yönergeleri daha tutarlı uyguluyor.
Kullanıcıya görünen bütün metinler ise **Türkçe** verildi; Stitch'in bunları
çevirmemesi için her prompt'ta ayrıca belirtiliyor.

---

## 0. Tasarım sistemi (ilk prompt)

```
Design system for "Vakit", an Android app that shows Islamic prayer times
(Diyanet, Turkey) and a qibla compass. Audience: Turkish users of all ages,
including older people; it is opened many times a day for a quick glance.

Principles:
- Calm, modern, highly readable. Not kitsch: no heavy gold ornaments, no
  stock photos, no people. A subtle geometric pattern is allowed only as a
  very low-contrast background texture.
- Light AND dark themes are both first-class. Every color must have a light
  and a dark value; text contrast at least 4.5:1 on its background in BOTH
  themes. Never put white text on a background that can become light.
- Times and countdowns use tabular (monospaced) numerals so digits do not
  jump while counting.
- Typography must fully support Turkish characters (İ ı Ş ş Ğ ğ Ü ü Ö ö Ç ç).
- Large touch targets (min 48dp). Body text min 16sp.
- Material 3 based components: cards, list rows, bottom navigation with
  4 tabs, switches, chips, dialogs.
- All UI text is Turkish. Do not translate the Turkish strings I provide.

Define color tokens (primary, onPrimary, surface, surfaceContainer,
onSurface, onSurfaceVariant, outline, highlight for "next prayer",
warning, error) for light and dark, a spacing scale on a 4dp grid, corner
radius scale, and a type scale (display for countdown, headline, title,
body, label).
```

## Stil varyantları (Ana Sayfa üzerinde dene, birini seç)

- **A — Gökyüzü**: arka plan, içinde bulunulan vakte göre değişen yumuşak bir
  gökyüzü gradyanı (İmsak: koyu lacivertten şafak morluğuna, Öğle: açık mavi,
  İkindi: sıcak amber, Akşam: gün batımı mercanı, Yatsı: gece laciverti).
  İçerik buzlu cam kartlarda. Koyu tema aynı gradyanların koyulaştırılmış hali.
- **B — Sade**: nötr zemin, tek vurgu rengi (zümrüt ya da petrol yeşili),
  büyük tipografik geri sayım, sıradaki vakit tek renkle vurgulu. En kolay
  okunan ve en zamansız seçenek.
- **C — Gece mavisi**: koyu tema öncelikli. Lacivert zemin, sıcak altın-sarı
  vurgu. Açık temada kırık beyaz zemin, lacivert metin.

Varyantı denemek için Ana Sayfa prompt'unun sonuna şunu ekle:
`Visual direction: <A/B/C açıklamasının İngilizcesi>`.

---

## 1. Ana Sayfa

```
Screen: "Ana Sayfa" (home) of the Vakit prayer times app. Mobile, portrait,
360dp wide. Turkish UI text exactly as given.

Top area:
- Location: "Kadıköy, İstanbul" with a small location icon; tapping it opens
  location selection.
- Dates under it: "2 Ekim 2026 Cuma" and the Hijri date "21 Rebiulahir 1448".

Hero card (the most important element, visible without scrolling):
- Small label "Sıradaki vakit".
- Prayer name large: "Akşam", and its time "18:52".
- A large live countdown "01:23:45" (hours:minutes:seconds, tabular digits).
- A thin progress bar showing how much of the current period has passed
  (from İkindi 16:15 to Akşam 18:52).

Today's six prayer times as a list, one row each, name left and time right:
İmsak 05:30, Güneş 06:54, Öğle 12:58, İkindi 16:15, Akşam 18:52, Yatsı 20:11.
- The NEXT prayer (Akşam) is clearly highlighted.
- Prayers already passed today are slightly muted.

Small status chips that may appear above the list (show one as an example):
"Çevrimdışı hesap" (times calculated on device because there is no internet)
and "Veriler güncellenmeli".

Below the list, a small info row: "Kıble saati 11:32".

Bottom navigation with 4 tabs: "Vakitler" (selected), "Kıble", "Aylık",
"Ayarlar".
```

## 2. Kıble

```
Screen: "Kıble" (qibla compass) of the Vakit app. Mobile, portrait, 360dp.
Turkish UI text exactly as given.

- Title "Kıble".
- A large circular compass dial in the center. Cardinal letters in Turkish:
  "K" (north), "D" (east), "G" (south), "B" (west). Degree ticks every 15°.
- A Kaaba marker on the dial edge at the qibla bearing (151°), and a fixed
  indicator at the top showing where the phone points.
- Under the dial, a big readout "151°" with the label "Kıble açısı".
- Alignment state text: "Kıbleye dönüksünüz" (aligned, positive color) — also
  show the unaligned variant as small text "Telefonu sağa çevirin".
- A warning card (only when compass accuracy is low): "Pusula hassasiyeti
  düşük. Telefonu havada 8 çizerek kalibre edin." with a small figure-8 icon.
- Info rows: "Kâbe'ye uzaklık 2.394 km" and "Bugün 11:32'de güneş kıble
  yönünde; gölgenin tersi kıbleyi gösterir."

Bottom navigation: "Vakitler", "Kıble" (selected), "Aylık", "Ayarlar".
```

## 3. Aylık Vakitler

```
Screen: "Aylık Vakitler" (monthly prayer times) of the Vakit app. Mobile,
portrait, 360dp. Turkish UI text exactly as given.

- Title "Aylık Vakitler", subtitle "Kadıköy, İstanbul".
- A compact table for 30 days. Columns: date ("2 Eki Cum"), İmsak, Güneş,
  Öğle, İkindi, Akşam, Yatsı. Times like 05:30, tabular digits.
- Today's row is highlighted; past days slightly muted.
- The table must fit 360dp width without horizontal scrolling: use compact
  type for times and a sticky header row.
- Footer text: "Kaynak: Diyanet İşleri Başkanlığı".

Bottom navigation: "Vakitler", "Kıble", "Aylık" (selected), "Ayarlar".
```

## 4. Konum Seçimi

```
Screen: "Konum Seçimi" (location selection) of the Vakit app. Mobile,
portrait, 360dp. Turkish UI text exactly as given.

- App bar with back arrow and title "Konum Seçimi".
- Primary button "Konumumu bul" with a GPS icon; under it small text
  "İlçeniz otomatik bulunur. Koordinatlarınız hiçbir sunucuya gönderilmez."
- Current selection card: "Seçili konum: Kadıköy, İstanbul".
- Search field with placeholder "İl ara".
- A list of provinces (İller): "Adana", "Adıyaman", "Afyonkarahisar",
  "Ağrı", "Aksaray"... Tapping a province opens its districts (show a second
  state of the same screen titled "İstanbul" listing "Adalar", "Arnavutköy",
  "Ataşehir", "Avcılar", "Bağcılar"... with "Kadıköy" checked).
```

## 5. Ayarlar

```
Screen: "Ayarlar" (settings) of the Vakit app. Mobile, portrait, 360dp.
Turkish UI text exactly as given. Grouped list sections:

Section "Konum":
- Row "Konum" with value "Kadıköy, İstanbul" and a chevron.

Section "Bildirim":
- Switch row "Kalıcı bildirim" with subtitle "Sıradaki vakti ve geri sayımı
  bildirim çubuğunda gösterir" (on).
- Status row "Kesin zamanlı alarm" with subtitle "Bildirim vakit girer girmez
  güncellenir" and a trailing state "İzin verildi" (also show a variant with a
  warning color and a button "İzin ver").
- Row "Pil optimizasyonu" with subtitle "Bazı telefonlarda bildirimin
  kaybolmaması için" and a chevron.

Section "Görünüm":
- Row "Tema" with a segmented control: "Sistem", "Açık", "Koyu".

Section "Hakkında":
- Row "Veri kaynağı" value "Diyanet İşleri Başkanlığı".
- Row "Sürüm" value "1.0.0".

Bottom navigation: "Vakitler", "Kıble", "Aylık", "Ayarlar" (selected).
```

## 6. İzinler (ilk açılış)

```
Screen: "İzinler" (first-run permission onboarding) of the Vakit app.
Mobile, portrait, 360dp. Turkish UI text exactly as given. One step per
page with a progress indicator (3 steps), a friendly line illustration
(no people), a primary button and a secondary text button.

Step 1: title "Konum", text "Vakitleri bulunduğunuz ilçeye göre
gösterebilmemiz için konum izni gerekiyor. İsterseniz ilçenizi elle de
seçebilirsiniz." Buttons "Konum izni ver" and "Elle seçeceğim".

Step 2: title "Bildirim", text "Sıradaki vakti ve canlı geri sayımı bildirim
çubuğunda gösterebilmemiz için." Buttons "Bildirime izin ver" and "Şimdi
değil".

Step 3: title "Kesin zamanlı alarm", text "Bildirimin vakit girdiği anda bir
sonraki vakte geçmesi için. İzin vermezseniz birkaç dakika gecikebilir."
Buttons "Ayarları aç" and "Atla".
```

## 7. Bildirim (kapalı ve açık)

```
Mockup of an Android notification in the notification shade (Android 15
style), for the Vakit app. Show it twice, in a LIGHT shade and in a DARK
shade, each with collapsed and expanded states. Follow the standard Android
notification template: system header with small app icon and app name
"Vakit", rounded notification card from the system — do not design a custom
card background.

Collapsed: "Kadıköy • Akşam 18:52" and a live countdown "01:23:45" on the
right.

Expanded: the same first line, then a row of six columns: "İmsak 05:30",
"Güneş 06:54", "Öğle 12:58", "İkindi 16:15", "Akşam 18:52", "Yatsı 20:11";
the next prayer (Akşam) highlighted with the app's highlight color and bold.
Text colors must follow the system notification text colors so they read
well in both shades.
```

---

## Claude'un inceleme listesi (dışa aktarım geldiğinde)

- Her ekranın açık ve koyu hali var mı, kontrast yeterli mi?
- Vakit adları ve metinler Türkçe karakterli mi (Stitch bazen ASCII'ye çevirir)?
- Rakamlar tabular mı (geri sayım zıplamasın)?
- 360dp'de yatay taşma var mı (özellikle Aylık Vakitler tablosu)?
- Bildirim tasarımı Android şablonunun yapabileceği kadar mı? Özel arka plan
  ve sabit renk varsa uyarlanır.
- `DESIGN.md` token'ları `lib/theme/`'e bire bir aktarılabilir mi?
