---
name: stitch-to-flutter
description: "Stitch'ten dışa aktarılmış bir ekranı (design/stitch/<ekran>/code.html + screen.png) vakit-app'te gerçek bir Flutter ekranına çevirme akışı. Kodu agy yazar; bu skill brifi hazırlar, agy-gorev ile çalıştırır ve sonucu screen.png ile açık/koyu temada karşılaştırır. Tetikleyiciler: ekranı uygula, ekranı Flutter'a çevir, mockup'ı koda dök, Stitch ekranı, convert screen, implement screen."
---

# /stitch-to-flutter

`design/stitch/<ekran>/code.html` (statik Tailwind HTML) + `screen.png` (görsel
referans) çiftini vakit-app mimarisine uygun bir Flutter ekranına çevirir.
finans-app'teki aynı adlı skill'den uyarlandı. Farkı: orada kodu Claude
yazıyordu, burada **kodu agy yazar** (bkz. `agy-gorev`). Claude bağlamı
toplar, brifi yazar ve görsel doğrulamayı yapar.

## Kullanım

```
/stitch-to-flutter "Ana Sayfa"
/stitch-to-flutter ana_sayfa
/stitch-to-flutter "design/stitch/kible"
```

Girdi Türkçe ekran adı, ASCII yaklaşık ad ya da klasör yolu olabilir;
`design/stitch/` altındaki gerçek klasörle eşleştir. Stitch dışa aktarımında
klasör adları bozuk Türkçe karakter içerebilir (`k_ble` gibi). Bunları
**yeniden adlandırma**.

## Ön koşullar

- `lib/theme/` (DESIGN.md token'larından türetilmiş açık/koyu `ThemeData`)
  yoksa **önce onu** agy'ye yaptır. Ekranlar renk ve boşluğu tek kaynaktan alır.
- Ekranın veri tarafı (Cubit'in besleneceği repository) hazır değilse brifte
  geçici sahte repository kullanılacağını açıkça yaz.

## Adımlar

### 1. Bağlamı topla

- `screen.png`'yi görüntüle. Görsel doğruluk kaynağı ekran görüntüsüdür.
- `code.html`'i yalnız yapıyı (bileşen hiyerarşisi, metinler, etkileşimli
  öğeler) anlamak için oku. 25 KB'ı aşıyorsa yalnız `<body>` içindeki ana
  bölümleri oku.
- `design/stitch/DESIGN.md`'deki ilgili bileşen kurallarına bak (kartlar,
  listeler, butonlar, alt gezinme).
- Ekranın hangi modüle ait olduğunu `IMPLEMENTATION_PLAN.md`'den bul (ör.
  "Ana Sayfa" → `lib/prayer_times/`).

### 2. Token eşlemesini brife yaz

agy'ye eşlemeyi hazır ver, tahmin etmesine bırakma:

| Stitch / Tailwind | Flutter |
|---|---|
| Renk class'ları (`bg-primary`, `text-on-surface-variant`) | `ColorScheme` / tema extension'daki aynı adlı alan |
| Boşluk (`p-4`, `gap-3`) | `lib/theme/app_spacing.dart` |
| Köşe (`rounded-xl`) | `app_spacing.dart` radius ölçeği |
| Tipografi (`text-display-lg`) | `lib/theme/app_typography.dart` → `TextTheme` |
| Material Symbols | En yakın `Icons.*`. Birebir karşılık yoksa brifte hangisinin kullanılacağını sen seç |

Stitch'teki yer tutucu metinleri (örnek şehir, marka adı) brifte gerçek
kaynağıyla değiştir: ilçe adı state'ten, vakit adları Türkçe sabitlerden gelir.

### 3. Brifi `agy-gorev` şablonuyla yaz

Dokunulacak dosyalar genelde şunlardır:

- `lib/<modul>/view/<ekran>_page.dart`
- `lib/<modul>/widgets/...` (tekrar eden parçalar; birden çok ekranda geçenler
  `lib/shared/widgets/`)
- Gerekirse `lib/<modul>/cubit/<ekran>_cubit.dart` + `_state.dart`
- `test/<modul>/view/<ekran>_page_test.dart`: 360 dp, açık + koyu, yükleniyor
  / boş / hata / dolu durumları, `tester.takeException()` null.

Kabul kriterine şunu da yaz: "screen.png'deki hiyerarşi ve sıralama korunur;
renk/boşluk yalnız token'lardan gelir".

### 4. Çalıştır ve doğrula

1. `agy-gorev` 3–5. adımları: çalıştırma, `verify_agy.sh` ve diff incelemesi.
2. `flutter run -d emulator-5554` ile ekranı aç. Açık ve koyu temada ekran
   görüntüsü al (`run` skill'i ya da `adb exec-out screencap -p`).
3. `screen.png` ile yan yana karşılaştır. Renk, boşluk ve tipografi sapmalarını
   listele:
   - Sapma `lib/theme/`'deki eksik bir token'dan geliyorsa düzeltme oraya yapılır, ekrana değil.
   - Sapma ekran kodundaysa düzeltme turu (`NNNb`) açılır.
4. Sapmaları Buğra'ya kısaca özetle; "yaklaşık doğru" deyip geçme.

### 5. Kapat

- `IMPLEMENTATION_PLAN.md`'de ekranın checkbox'ını işaretle.
- Birden çok ekranda aynı yapı tekrar ediyorsa (kart, vakit satırı) sonraki
  brifte onu `lib/shared/widgets/`'a çıkarmayı öner; kopyala-yapıştırla ilerleme.

## Sınırlar

- Yalnız bu repodaki `design/stitch/` ile çalışır. Stitch'te yeni bir ekran
  varsa önce dışa aktarılıp (code.html + screen.png) repoya eklenir.
- Native bildirimin görünümü (RemoteViews) de Stitch'teki "Bildirim" ekranından
  gelir. O iş için brif, `AGENTS.md`'deki native kurallarını (tema uyumlu metin
  stilleri, Chronometer) ayrıca vurgular.
