# vakit-app — Kod Yazan Ajanlar İçin Kurallar

Bu dosya `agy` (Antigravity CLI) gibi kod üreten ajanlar için. Claude ve
insanlar için asıl bağlam `CLAUDE.md`'dedir; buradaki kurallar onun kod
yazmayla ilgili özetidir. Sana verilen görev metni (brif) bu dosyayla
çelişirse durma noktası budur: çelişkiyi raporda yaz, kendi yorumunla devam etme.

Uygulama: **Vakit**, Türkiye odaklı namaz vakitleri ve kıble uygulaması.
Flutter (Android). Paket adı `vakit`, Android paketi `com.sbugrayy.vakit`.

## Mutlak kurallar

1. **Hiçbir terminal komutu çalıştırma.** `flutter`, `dart`, `git`, `gradle`,
   `adb` — hiçbiri. Sadece dosya oku ve yaz. Derleme, test, biçimlendirme ve
   doğrulama Claude tarafından yapılır.
2. **Yalnız brifte adı geçen dosyalara yaz.** Brif üç dosya diyorsa üç dosya
   değişir; "bu arada şunu da düzelttim" kabul edilmez. Kapsam dışında bir hata
   görürsen düzeltme, raporda `dosya:satır` ile yaz.
3. **Yazabileceğin yerler yalnız `lib/`, `test/` ve `android/app/src/`.**
   Şunlara dokunma: bütün `*.md` dosyaları (bu dosya dahil), `.claude/`,
   `.agy/`, `tool/`, `design/`, `pubspec.yaml`, `pubspec.lock`,
   `analysis_options.yaml`, `android/**/*.gradle.kts`, `android/gradle.properties`.
4. **Lint denetimini kapatma.** `// ignore_for_file:` ve `// ignore:` satırları
   yasak. Kural rahatsız ediyorsa kodu düzelt, kuralı susturma.
5. **Yeni paket ya da Android izni ekleme.** Gerekiyorsa raporda gerekçesiyle
   iste. Kullanılabilir paketler `pubspec.yaml`'da.
6. `.agy/` klasörünü okuma. Görevin yalnız sana verilen brif.

## Kod stili

Analiz `flutter analyze --fatal-infos` ile yapılıyor; bilgi seviyesindeki uyarı
bile teslimatı geri çevirir.

- `very_good_analysis` kuralları geçerli.
- **Satır uzunluğu en fazla 80 karakter.**
- Import'lar alfabetik (`directives_ordering`). Proje içi import'lar her zaman
  `package:vakit/...` biçiminde; göreli yol kullanma.
- Mümkün olan her widget ve kurucu `const`.
- `catch (e)` yerine `on Exception catch (e)`: tip belirtilmeli.
- Dosya başındaki açıklama `///` değil `//` ile yazılır (`///` import'lardan
  önce gelirse `dangling_library_doc_comments` hatası verir).
- `print` yok. Kişisel veri (konum, koordinat) hiçbir yerde loglanmaz.

Analizin bu projede en sık yakaladığı kurallar. Yazarken bunlara baştan uy,
düzeltme turu gerekmesin:

| Kural | Ne ister |
|---|---|
| `cascade_invocations` | Nesneyi oluşturduktan hemen sonra aynı değişkende çağrı yapılıyorsa çağrıyı oluşturma ifadesine `..` ile bağla: `final c = FixedClock(t)..advance(d);` |
| `directives_ordering` | `dart:` → `package:` → göreli import; her grup kendi içinde alfabetik |
| `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` | Sabit olabilen her kurucu ve liste `const` |
| `sort_constructors_first` | Kurucular alanlardan ve metotlardan önce |
| `avoid_redundant_argument_values` | Varsayılan değere eşit argümanı yazma |
| `prefer_int_literals` | `double` parametreye tam değer verirken `90.0` değil `90` yaz |
| `prefer_final_locals` | Yeniden atanmayan yerel değişken `final` |
| `avoid_catches_without_on_clauses` | `on Exception catch (e)` |
| `lines_longer_than_80_chars` | Satır en fazla 80 karakter |

Test dosyaları `test/helpers/` altındaki yardımcıları göreli yolla içe aktarır
(`../helpers/fixed_clock.dart`); `package:vakit/` yalnız `lib/`'i gösterir.

## Tasarım token'ları — elle değer yazma

Renk, boşluk, köşe yarıçapı, yazı stili ve görsel yolu **asla** elle yazılmaz:

| Ne | Nereden |
|---|---|
| Renk | `lib/theme/app_colors.dart` (ColorScheme + ThemeExtension) |
| Boşluk, köşe yarıçapı | `lib/theme/app_spacing.dart` |
| Yazı stilleri | `lib/theme/app_typography.dart` |
| Görsel yolu | `lib/theme/app_assets.dart` |

`Color(0xFF...)`, `Colors.white`, `EdgeInsets.all(16)`, `'assets/...'` gibi
ifadeler `lib/theme/` dışında geri çevrilir.

- Her ekran **hem açık hem koyu temada** okunur olmalı. Renkleri
  `Theme.of(context).colorScheme` ya da tema extension'ından al; arka planı
  varsayarak sabit beyaz/siyah metin yazma. Eski uygulamanın en büyük hatası buydu.
- Tasarım kaynağı `design/stitch/<ekran>/screen.png` (görsel doğruluk
  kaynağı) ve `code.html` (yalnız yapıyı anlamak için). Stitch'teki yer tutucu
  marka adlarını ve örnek metinleri kopyalama.

## Dil

- Kullanıcının gördüğü **bütün metinler Türkçe** ve **Türkçe karakterlerle**:
  `İmsak`, `Güneş`, `Öğle`, `İkindi`, `Akşam`, `Yatsı`, `Kıble`, `Ayarlar`.
  Karaktersiz yazım (`Ogle`, `Kible`) kabul edilmez; brifte ASCII görsen bile.
- Kod içindeki tanımlayıcılar İngilizce.
- Yorumlar Türkçe ve kodun ne yaptığını değil, **neden** öyle yazıldığını anlatır.

## Mimari

Özellik bazlı (feature-first) yapı:

```
lib/<modul>/
  cubit/        durum yönetimi (flutter_bloc Cubit)
  models/       veri modelleri (equatable)
  repository/   abstract XRepository + uygulamaları, native kanal sarmalayıcıları
  view/         sayfalar
  widgets/      o modüle özel widget'lar
```

- Durum yönetimi **flutter_bloc** (Cubit). Başka durum kütüphanesi ekleme.
- Yönlendirme **go_router**, tek yerde: `lib/navigation/app_router.dart`.
- Repository pattern: UI ve cubit verinin nereden geldiğini (Diyanet, önbellek,
  çevrimdışı hesap, native kanal) bilmez.
- Native kanal adları `com.sbugrayy.vakit/<ad>` biçiminde ve iki tarafta aynı.
- `main()` içinde herhangi bir eklentiye dokunmadan önce
  `WidgetsFlutterBinding.ensureInitialized()` çağrılır.

## Zaman ve vakit kuralları (kritik)

- **`DateTime.now()` yasak.** Şimdiki zaman `lib/shared/clock.dart`'taki
  `Clock` üzerinden alınır; testlerde sabit zaman verilir.
- Diyanet vakitleri (`"05:28"`) yerel saat metnidir. `MiladiTarihKisa`
  (`"30.09.2026"`) ile birleştirilip `GreenwichOrtalamaZamani` (saat cinsinden
  UTC ofseti, ör. `3.0`) kullanılarak **mutlak zamana (UTC)** çevrilir.
  Cihazın saat dilimine güvenme.
- Gün dönümü: Yatsı'dan sonra sıradaki vakit **ertesi günün kendi** İmsak'ıdır;
  bugünün İmsak saatiyle tahmin edilmez.
- `Timer`, `StreamSubscription` ya da sensör dinleyicisi açan her Cubit bunları
  `close()` içinde iptal eder.

## Native Android (Kotlin) kuralları

- Dosyalar `android/app/src/main/kotlin/com/sbugrayy/vakit/<modul>/` altında.
- Bildirim motoru Dart'a ihtiyaç duymadan çalışır (Flutter kapalıyken de).
- Geri sayım RemoteViews içindeki countdown `Chronometer` ile yapılır.
  Saniyelik ya da dakikalık güncelleme döngüsü, `while(true)`, sürekli çalışan
  servis **yasak**. Alarm yalnız vakit sınırlarında kurulur.
- Bildirim metin renkleri sabit yazılmaz: `DecoratedCustomViewStyle` ve
  `TextAppearance.Compat.Notification.*` stilleri kullanılır. Bildirim açık ve
  koyu panelde okunur olmalı.
- Receiver'lar `android:exported="false"`. Yalnız sistem yayınlarını
  (`BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED`, `MY_PACKAGE_REPLACED`)
  dinleyen receiver `exported="true"` olabilir ve özel action kabul etmez.
- `PendingIntent` her zaman `FLAG_IMMUTABLE`.
- Exact alarm öncesi `canScheduleExactAlarms()` kontrol edilir. İzin yoksa
  inexact alarma düşülür, uygulama çökmez.
- Kullanıcıya görünen metinler `res/values/strings.xml`'de, Türkçe.

## Güvenlik ve gizlilik

- Kodda sır yok: API anahtarı, keystore parolası, imza bilgisi.
- Cihaz dışına yalnız Diyanet vakit isteği gider (il/ilçe kimliği); koordinat
  hiçbir sunucuya gönderilmez.
- Kullanıcıya istisnanın metnini (`e.toString()`) gösterme; sabit ve
  anlaşılır bir Türkçe mesaj göster.
- TLS'i gevşetme, düz HTTP kullanma.

## Testler

- Yazdığın her kod yolunun testi olmalı: hata dalları, `null` durumları,
  `close()`/`dispose` dahil.
- Saf hesap fonksiyonları (sıradaki vakit, gün dönümü, ofset dönüşümü, ilçe
  eşleme, kıble açısı) **her dalıyla** test edilir.
- Testler gerçek ağa çıkmaz. `test/fixtures/` altındaki gerçek Diyanet
  yanıtlarını kullan; bu dosyaları Claude ekler, sen değiştirme.
- Widget testleri 360 dp genişlikte, hem açık hem koyu temada pump edilir.
- Sonsuz animasyon ya da periyodik `Timer` içeren ekranda `pumpAndSettle`
  kullanma; `pump(Duration)` kullan.
- `lib/` genelinde satır kapsama eşiği %90.

## Rapor (her görevin sonunda zorunlu)

Son mesajın şu başlıkları içerir:

1. **Değişen dosyalar**: her dosya için bir satır neden.
2. **Yapılmayanlar**: ve nedeni.
3. **Varsayımlar**.
4. **Kapsam dışında fark edilen hatalar**: `dosya:satır`, düzeltilmeden.
5. **İstenen paket/izin**: gerekli görüp eklemediklerin.

Testleri ya da analizi sen çalıştıramazsın; "testler geçiyor", "analiz temiz"
gibi doğrulanmamış iddialar yazma.

## Dokunulmayacak dosyalar

- `design/stitch/`: Stitch dışa aktarımları, yalnız referans. Bozuk görünen
  klasör adlarını "düzeltme".
- `test/fixtures/`: gerçek API yanıtları.
- Kural 3'teki bütün dosyalar.
