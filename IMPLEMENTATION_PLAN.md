# Vakit — Uygulama Planı

Projenin durumu için tek kaynak. Bir iş bitince ilgili kutu işaretlenir, bir
karar değişince "Kararlar" tablosu güncellenir. Çalışma kuralları `CLAUDE.md`,
agy kuralları `AGENTS.md`'de.

## 1. Neden

Uygulamanın ilk sürümü Google AI Studio'da Kotlin/Compose ile üretildi (`main`
dalı). İki yerde beklentiyi karşılamadı:

- **Tasarım**: koyu renkler sabit kodlanmıştı, açık temada tutarsızdı.
- **Bildirim çubuğu**: geri sayım global bir `while(true)` döngüsüne bağlıydı,
  süreç ölünce duruyordu. Bildirim metni `#FFFFFF` sabitti, açık panelde okunmuyordu.

Flutter ile yeniden yazılıyor. Geliştirme Claude (şef) + agy (kod) orkestrasıyla
yürüyor.

## 2. Kararlar

| Konu | Karar | Tarih |
|---|---|---|
| Platform | Flutter, yalnız Android. `com.sbugrayy.vakit`, minSdk 26 | 2026-10-02 |
| Bildirim | Tek özellik: canlı geri sayımlı kalıcı bildirim. Sesli uyarı, durum çubuğu dakika ikonu, aksiyon butonu yok | 2026-10-02 |
| Tasarım | Google Stitch → `design/stitch/` | 2026-10-02 |
| Vakit kaynağı | Diyanet verisi (`ezanvakti.emushaf.net`) + çevrimdışı yedek (`adhan`, Türkiye metodu) | 2026-10-02 |
| agy | `gemini-3.8-flash-high`. Global izin dosyasında `command(...)` izinleri kaldırıldı, vakit-app'e yalnız `lib/`, `test/`, `android/app/src/` yazma izni | 2026-10-02 |
| agy çağrısı | `--mode accept-edits` **kullanılmıyor**: izin listesini atlıyor (duman testinde köke yazdı). Bayraksız çağrıda izinsiz yazma reddediliyor | 2026-10-02 |
| Yığın | flutter_bloc (Cubit), go_router, dio, equatable, intl 0.20.2, very_good_analysis, bloc_test, mocktail | 2026-10-02 |
| Git | `flutter-rewrite` dalı; MVP'de PR ile `main`'e. Claude commit + push eder | 2026-10-02 |

## 3. Eski uygulamadan çıkan dersler

| Eski hata | Yeni kural |
|---|---|
| Sabit renkler (hero kart, bildirimde `#FFFFFF`) | Token zorunluluğu (`lib/theme/`), her ekran açık + koyu test |
| `while(true)` coroutine + dakikalık alarm | Sistem `Chronometer`'ı + yalnız vakit sınırında exact alarm |
| Yalnız bugünün vakitleri, `cached_date` hiç kontrol edilmiyor | 30 günlük önbellek, tarih ve UTC ofset kontrolü |
| Yatsı sonrası "yarının İmsak'ı" bugünkü saatle tahmin | Ertesi günün kendi verisi |
| İmsak için Aladhan `Imsak` (Fajr−10 dk) | Diyanet verisi doğrudan |
| Kıblede manyetik sapma düzeltmesi yok (~5–7°) | rotation-vector + `GeomagneticField` |
| Özel action'lı `exported=true` receiver | `exported=false`, `FLAG_IMMUTABLE` |

## 4. Fazlar

### Faz 0 — Kurulum ve orkestra (Claude) — TAMAM (2026-10-03)

2026-10-02 akşamı Gradle 9.1.0 dağıtımının indirmesi (~225 MB, ~3,4 MB/dk)
Buğra'nın isteğiyle durduruldu. 2026-10-03'te Buğra "sorma, yapabildiğin
kadar ilerle" dedi. Büyük indirmeden kaçınmak için Android araç zinciri
makinenin önbelleğindeki sürümlere sabitlendi:

- AGP 8.12.0 + Gradle 9.0.0: finans-app ve catscrmobil ile aynı, bu Flutter
  sürümüyle APK ürettiği kanıtlı.
- Kotlin 2.2.20: 2.2.10 Flutter'ın "destek yakında kalkacak" uyarısını veriyordu.

Sonuç: APK ~3 dakikada, indirmesiz derlendi. AGP 9 / Gradle 9.1'e geçiş internet
uygun olduğunda ayrı bir iş (Faz 6'da).

- [x] Repo klonlandı, `flutter-rewrite` dalı, Kotlin dosyaları kaldırıldı (git geçmişinde)
- [x] `flutter create --empty --org com.sbugrayy --project-name vakit --platforms android`
- [x] minSdk 26, very_good_analysis, temel paketler, `.gitattributes` (LF), `.gitignore` (`.agy/`)
- [x] `CLAUDE.md`, `AGENTS.md`, `ANTIGRAVITY_CHECKLIST.md`, bu plan, README
- [x] `.claude/settings.json`, `agy-gorev` ve `stitch-to-flutter` skill'leri, `tool/verify_agy.sh`
- [x] agy global izin dosyası güncellendi (BOM'suz, yedek `settings.json.bak`)
- [x] Debug APK derlemesi (`GRADLE_OPTS` + Norton truststore; önbellekteki AGP 8.12.0 / Kotlin 2.2.20 / Gradle 9.0.0)
- [x] agy oturumu (Buğra etkileşimli `agy` ile giriş yaptı, Settings Error yok)
- [x] `agy models` → `gemini-3.8-flash-high` ("Gemini 3.8 Flash (High)")
- [x] Duman testi (a): salt-okuma görevi doğru cevap verdi
- [x] Duman testi (c): bayraksız çağrıda repo köküne yazma `denied_actions` ile reddedildi. `accept-edits` ile reddedilmiyordu; bayrak çağrıdan çıkarıldı
- [x] `tool/agy_rapor.py`: stream-json özetleyici (rapor, araçlar, retler, komut denemeleri)
- [x] Duman testi (b) + ilk gerçek agy görevi: `lib/shared/clock.dart` (`Clock` + `SystemClock`) + test. 001'de iki `cascade_invocations` uyarısı çıktı, 001b düzeltme turunda giderildi; 6 test, `lib/` kapsaması %100
- [x] Duman testi (d): komut denemesi (`flutter --version`) `denied_actions: command` ile reddedildi. `--sandbox` gereksiz bulundu
- [x] AGENTS.md'ye en sık yakalanan lint kuralları tablosu eklendi (düzeltme turlarını azaltmak için)
- [x] İskelet `flutter run` ile `Pixel_8` emülatöründe açıldı, günlükte hata yok. Not: emülatör saat dilimi UTC; saat dilimi bağımsızlığı testi için işe yarar

### Faz 1 — Tasarım (Stitch); Faz 2 ile paralel

- [x] Claude `design/STITCH_PROMPTS.md`'yi yazar. İçeriği: tasarım sistemi, 3 stil varyantı (Gökyüzü / Sade / Gece mavisi), ekran başına prompt, dışa aktarım klasör yapısı
- [ ] Ekranlar: Ana Sayfa · Kıble · Aylık Vakitler · Konum Seçimi · Ayarlar · İzinler · Bildirim (kapalı/açık)
- [ ] Buğra Stitch'te üretir, `design/stitch/<ekran>/{code.html,screen.png}` + `design/stitch/DESIGN.md` olarak repoya ekler
- [ ] Claude inceler: tutarlılık, açık/koyu, erişilebilir kontrast
- [ ] agy: `lib/theme/` (app_colors, app_spacing, app_typography, app_theme; açık + koyu)

### Faz 2 — Veri katmanı — TAMAM (GPS hariç), 2026-10-03

- [x] Claude: gerçek yanıtlar → `test/fixtures/diyanet/` (81 il; İstanbul/Ankara/Van ilçeleri ve 32 günlük vakitleri)
- [x] Claude: `shared_preferences` ve `adhan_dart`. `adhan` yerine `adhan_dart` seçildi: 2026 sürümü, 160/160 puan. `adhan` 2023'ten beri bakımsız. Türkiye metodu Diyanet'ten en fazla 2 dk sapıyor (ölçüldü)
- [x] agy 002: `Prayer`, `PrayerDay` (mutlak UTC, Hicri, kıble saati), Diyanet JSON çözümleme
- [x] agy 003: Diyanet API istemcisi (dio, tam switch'li hata eşlemesi), `City`/`District`
- [x] agy 004: Türkçe katlama ve il/ilçe eşleştirme (ASCII/Türkçe karışık adlar, `(V)` ekleri, listede olmayan merkez ilçe → il merkezi)
- [x] agy 005: `PrayerSchedule` (sıradaki vakit, geri sayım, gün dönümü, "bugün" verinin ofsetiyle)
- [x] agy 006: çevrimdışı hesap (`adhan_dart` Türkiye metodu)
- [x] agy 007a/b: `KeyValueStore`, `SelectedLocation`, önbellekli vakit deposu (Diyanet → önbellek → çevrimdışı)
- [ ] GPS ile konum: paket indirmeden Android'in kendi `LocationManager` ve `Geocoder`'ıyla native kanal olarak yapılacak (Play Services gerekmez). Planlı görevler 013–014

### Faz 3 — Ekranlar — GEÇİCİ TASARIMLA ÇALIŞIYOR; Stitch bekleniyor

Stitch tasarımları gelmediği için ekranlar geçici temayla (`lib/theme/` yer
tutucu token'ları) yazıldı. Cubit'ler ve durumlar kalıcı; Stitch gelince
`stitch-to-flutter` ile yalnız görünüm ve token'lar değişecek.

- [x] agy 010a: uygulama kabuğu, go_router, Türkçe yerel, `main()` başlatma sırası, saat biçimleme (cihaz saat diliminden bağımsız)
- [x] agy 010b: Ana Sayfa + `PrayerTimesCubit`. Sıradaki vakit, canlı geri sayım, ilerleme, Miladi + Hicri tarih, 6 vakit, rozetler; ilk açılışta bildirim izni
- [x] agy 010c: Konum Seçimi (elle il → ilçe, Türkçe katlamalı arama, merkez ilçe başta)
- [ ] Aylık Vakitler (30 gün)
- [ ] Ayarlar (kalıcı bildirim aç/kapa, tema, konum, veri kaynağı bilgisi)
- [ ] İzinler. **Öncelikli:** "Alarmlar ve hatırlatıcılar" (exact alarm) izni istenmezse vakit geçişi ~39 dk gecikebilir (emülatörde ölçüldü). `NotificationBridge.openExactAlarmSettings()` hazır
- [ ] Stitch tasarımlarıyla yeniden giydirme (Faz 1'e bağlı)

### Faz 4 — Kalıcı bildirim (native) — TAMAM (WorkManager hariç), 2026-10-03

- [x] agy 008a: Kotlin motoru
  - Yük deposu.
  - Sıradaki vakit hesabı; yükün ofsetiyle biçimleme.
  - Yalnız sıradaki vakte tek exact alarm; izin yoksa inexact.
  - Receiver'lar: boot, saat, saat dilimi, paket güncellemesi, exact izin değişimi.
  - JVM testleri.
- [x] agy 008c: MethodChannel `com.sbugrayy.vakit/bildirim` + Android 13+ bildirim izni + `onResume` tazelemesi
- [x] agy 009: Dart köprüsü `NotificationBridge`
- [x] agy 008b: özel görünüm. `DecoratedCustomViewStyle` + RemoteViews; geri sayan Chronometer ve 6 vakit; vurgu yalnız XML'de (values/values-night). Uygulama adı "Vakit"
- [x] agy 011: ana manifestte INTERNET (release'te eksikti); debug'da kullanıcı sertifikalarına güven
- [x] agy 012: yalnız debug'da, `--dart-define` ile verilirse ek kök sertifika (Norton/emülatör)
- [x] Claude: emülatörde kanıt (aşağıda "Uçtan uca sonuçlar")
- [ ] WorkManager günlük yenileme: `work-runtime` önbellekte yok, indirme gerekiyor; ertelendi. Uygulama her açılışta tazeliyor, 30 gün bitince bildirim "uygulamayı açın" diyor

### Faz 5 — Kıble

- [ ] agy: native heading (`TYPE_ROTATION_VECTOR` + `GeomagneticField` sapması) → EventChannel `com.sbugrayy.vakit/kible`
- [ ] agy: kıble açısı (saf fonksiyon) + bilinen şehir testleri, Kâbe'ye mesafe
- [ ] agy: pusula ekranı, doğruluk/kalibrasyon uyarısı, Diyanet "kıble saati" kartı
- [ ] Claude: emülatör sanal sensörleriyle doğrulama, gerçek cihazda kontrol

### Faz 6 — Cila ve teslim

- [ ] Uygulama ikonu ve adı ("Vakit")
- [ ] Release imzası (keystore yolu ve parolalar env değişkeninden; repoya sır girmez)
- [ ] README, `code-review` ve `security-review`
- [ ] Gerçek telefonda uçtan uca deneme
- [ ] PR: `flutter-rewrite` → `main`

## 5a. Uçtan uca sonuçlar (2026-10-03, Pixel_8 emülatörü, Android 37)

| Adım | Sonuç |
|---|---|
| Temiz kurulum → bildirim izni iletişim kutusu → izin | ✓ |
| Konum seç → 81 il (Türkçe adlarla) → `istanbul` araması → İstanbul (merkez) | ✓ |
| Ana Sayfa: bugünün vakitleri Diyanet'le birebir (05:31 06:55 12:58 16:14 18:51 20:10, 22 Rebiulahir 1448) | ✓ |
| Emülatör UTC'deyken saatler Türkiye saatiyle | ✓ |
| Kalıcı bildirim: ongoing, sessiz, "İstanbul • Akşam 18:51" ve geri sayım | ✓ |
| Özel görünüm açık ve koyu panelde okunur; vurgu temayla değişiyor | ✓ |
| Alarm Akşam + 1 sn'ye kurulu; exact izin verilip uygulama öne gelince `window=0` | ✓ |
| Exact izin yokken alarm inexact (~39 dk pencere) | ⚠ İzinler ekranı gerekli |

Yol üstünde bulunup düzeltilenler:

- Release'te INTERNET izni yoktu.
- Emülatör DNS'i bozuktu (`-dns-server`).
- Norton TLS taraması emülatörü engelliyordu (debug'a özel çözüm).

## 5. Uçtan uca doğrulama senaryosu

1. Temiz kurulum → İzinler → `adb emu geo fix 28.97 41.01` → doğru ilçe seçilir.
2. Bugünün vakitleri `curl https://ezanvakti.emushaf.net/vakitler/<IlceID>` ile birebir aynıdır.
3. Kalıcı bildirim sıradaki vakti ve saniye saniye işleyen geri sayımı gösterir.
4. Emülatör saati sıradaki vakitten 1 dk önceye alınır; bildirim bir sonraki vakte geçer.
5. Yeniden başlatmadan sonra bildirim geri gelir. Bildirim açık ve koyu panelde okunur.
6. Uçak modunda "çevrimdışı hesap" rozeti görünür ve uygulama çalışmaya devam eder.
7. Kıble: sanal sensörle yön değişir; bilinen şehirlerde açı doğrudur.

## 6. İsteğe bağlı (Buğra isterse)

- GitHub Actions: push/PR'da `flutter analyze` + `flutter test`
- Ana ekran widget'ı (`home_widget`)
- Büyük Stitch çıktıları için finans-app'teki salt-okunur `opencode` analizcisi
- agy raporunu `--json-schema` ile yapılandırılmış hale getirmek; değişen dosya listesi otomatik karşılaştırılabilir
