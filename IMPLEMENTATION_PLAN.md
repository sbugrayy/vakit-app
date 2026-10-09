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
| Bildirim (ek) | Buğra'nın isteğiyle eklendi (örnek Ezan Vakti Pro): "N saat kaldı" özeti ve vakte 60 dk kala durum çubuğunda dakika sayan cami simgesi, diğer zamanlarda hilal-yıldız. Yalnız kesin alarm izni varken; inexact alarm sayıyı ≥10 dk geciktirebilir | 2026-10-03 |
| Dakika simgesi | Tek parça Osmanlı silüeti + Roboto Medium rakamlar, 0–60 için üretilmiş vektör kaynak (`tool/gen_status_icons.py`). Bitmap telefonda yumuşak görünüyordu. Kalan süre aşağı yuvarlanır (geri sayım ve Ezan Vakti gibi); son dakikada 0 | 2026-10-04 |
| Logo | Koyu yeşil radyal zemin (#16935F → #07583B), sarı ay-yıldız (#FFC72C). Geometri durum çubuğundaki hilal-yıldızla aynı. Uyarlanabilir simge + temalı simge katmanı. Kaynak `design/logo/` | 2026-10-04 |
| Tasarım | Google Stitch → `design/stitch/` | 2026-10-02 |
| Vakit kaynağı | Diyanet verisi (`ezanvakti.emushaf.net`) + çevrimdışı yedek (`adhan`, Türkiye metodu) | 2026-10-02 |
| agy | `gemini-3.8-flash-high`. Global izin dosyasında `command(...)` izinleri kaldırıldı, vakit-app'e yalnız `lib/`, `test/`, `android/app/src/` yazma izni | 2026-10-02 |
| agy çağrısı | `--mode accept-edits` **kullanılmıyor**: izin listesini atlıyor (duman testinde köke yazdı). Bayraksız çağrıda izinsiz yazma reddediliyor | 2026-10-02 |
| Yığın | flutter_bloc (Cubit), go_router, dio, equatable, intl 0.20.2, very_good_analysis, bloc_test, mocktail | 2026-10-02 |
| Git | `flutter-rewrite` dalı; MVP'de PR ile `main`'e. Claude commit + push eder | 2026-10-02 |
| Git (sonra) | PR #1 2026-10-09'da birleşti. Yeni işler `main`'den açılan dallarda, PR ile; birleştirme Buğra'da | 2026-10-09 |

## 3. Eski uygulamadan çıkan dersler

| Eski hata | Yeni kural |
|---|---|
| Sabit renkler (hero kart, bildirimde `#FFFFFF`) | Token zorunluluğu (`lib/theme/`), her ekran açık + koyu test |
| `while(true)` coroutine + gün boyu dakikalık alarm | Sistem `Chronometer`'ı + vakit sınırında exact alarm. Dakikalık tik yalnız son 60 dakikada, cihazı uyandırmadan |
| Yalnız bugünün vakitleri, `cached_date` hiç kontrol edilmiyor | 30 günlük önbellek, tarih ve UTC ofset kontrolü |
| Yatsı sonrası "yarının İmsak'ı" bugünkü saatle tahmin | Ertesi günün kendi verisi |
| İmsak için Aladhan `Imsak` (Fajr−10 dk) | Diyanet verisi doğrudan |
| Kıblede manyetik sapma düzeltmesi yok (~5–7°) | rotation-vector + `GeomagneticField` |
| Özel action'lı `exported=true` receiver | `exported=false`, `FLAG_IMMUTABLE` |

## 4. Fazlar

### İş listesi (2026-10-06, Buğra: "sırasıyla tüm işleri tamamla")

Sesli uyarı **olmayacak** (Buğra, 2026-10-06; ilk karar da böyleydi).

1. [x] Yayın sürümü imzası ve release APK
2. [x] Günlük veri yenileme (WorkManager, native Diyanet çekimi), agy 023
3. [x] Ayarlar ekranı (bildirim aç/kapa, tema, konum, veri kaynağı), agy 024a/b
4. [x] Aylık Vakitler ekranı, agy 025/025b
5. [x] Kıble saati kartı, agy 026/026b
6. [x] Konum yedeği (geokodlama başarısızsa koordinatı sakla, ili elle seçtir), agy 027/027b/027c
7. [~] `code-review` + `security-review` yapıldı (2026-10-06). Güvenlik temiz; tek öneri `allowBackup`. Kod incelemesinin 5 doğruluk adayı **açık**:
   - ScheduleRefresher: indirme sırasında konum değişirse eski ilçe verisi yazılabiliyor.
   - Konum yedeği: saklanan koordinat elle seçilen uzak ile de iliştiriliyor.
   - Ters geokodlamada zaman aşımı yok; "Konumumu bul" takılı kalabiliyor.
   - Rotation-vector yolunda doğruluk `event.accuracy`'den güncellenmiyor; pusula hep "güvenilmez" olabilir.
   - Bildirime giden günler sıralanmıyor/tekilleştirilmiyor.
   - Temizlik: 1 sn'lik zamanlayıcı her tikte `PrayerSchedule` kuruyor ve arka planda duruyor; WorkManager ilk çalıştırmada gereksiz indirme; `load()` yalnız `PrayerTimesException` yakalıyor; kıble hata dalı ikisi de aynı mesaj; merkez ilçe kuralı iki yerde.
8. [x] PR #1 `flutter-rewrite` → `main` açıldı ve Buğra birleştirdi (2026-10-09)

Kapsam dışı: Stitch tasarımı (Buğra'nın adımı), AGP 9 / Gradle 9.1 (büyük indirme).

### Sıradaki adımlar (2026-10-03 akşamı itibarıyla)

1. **Buğra:** `design/STITCH_PROMPTS.md` ile Stitch'te ekranları üretip `design/stitch/` altına koymak (Faz 1). Ekranlar şu an geçici tasarımla çalışıyor.
2. **Gerçek telefonda deneme** — 2026-10-03 akşamı Buğra denedi: konum bulunuyor, kıble gösteriliyor, bildirimde canlı sayaç çalışıyor. İstediği eklemeler 018a–d'de yapıldı ve emülatörde doğrulandı (özet satırı, durum çubuğu simgeleri, yeniden başlatma). 2026-10-04: telefonda simge Ezan Vakti'ninkinin yanında kötü durdu; 019–020'de vektör simgeye ve aşağı yuvarlamaya geçildi. Telefonda bakılacak: yeni simge Ezan Vakti'ninkiyle yan yana nasıl duruyor, ikisi aynı dakikayı gösteriyor mu.
3. Geokodlama başarısız olursa koordinatı saklayıp ili elle seçtirme (Faz 2 notu).
4. Stitch gelince: Ana Sayfa ve Konum Seçimi'ni yeniden giydirme; Aylık Vakitler, Ayarlar ve İzinler ekranları; Kıble saati kartı.
5. İnternet uygun olunca:
   - WorkManager günlük yenileme.
   - AGP 9 / Gradle 9.1 geçişi.
6. Faz 6:
   - Release imzası.
   - `code-review` ve `security-review`.
   - PR `flutter-rewrite` → `main`.

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
- [x] agy 013/014: GPS ile konum, paket indirmeden native kanal `com.sbugrayy.vakit/konum` ile (Android `LocationManager` + `Geocoder`; Play Services gerekmez) + "Konumumu bul" akışı (izin → konum → ters geokod → Diyanet eşleme → koordinatlı kayıt)
- [x] **Emülatörde ters geokodlama çalışmıyor**: Norton, Play Services'in geokodlama trafiğini de kesiyor (`GmsGeocoder: reverse geocoding network failure`, "Trust anchor not found"). Uygulama hatayı doğru yakalayıp "listeden seçin" diyor. Gerçek telefonda çalışıyor (Buğra, 2026-10-03)
- [x] Konum yedeği (agy 027/027b/027c, 2026-10-06): "Konumumu bul" ili bulamazsa koordinat saklanıyor, il/ilçe elle seçilince konum o koordinatla kaydediliyor; kıble çalışıyor
  - Ayrıca bulundu ve düzeltildi: hata mesajı il listesinin yerini alıyordu; artık liste doluysa mesaj üstte bant olarak görünüyor.
  - Emülatörde: internet kapalıyken "Konumumu bul" → bant + liste → Ankara elle → Kıble 160°, 2.162 km.

### Faz 3 — Ekranlar — GEÇİCİ TASARIMLA ÇALIŞIYOR; Stitch bekleniyor

Stitch tasarımları gelmediği için ekranlar geçici temayla (`lib/theme/` yer
tutucu token'ları) yazıldı. Cubit'ler ve durumlar kalıcı; Stitch gelince
`stitch-to-flutter` ile yalnız görünüm ve token'lar değişecek.

- [x] agy 010a: uygulama kabuğu, go_router, Türkçe yerel, `main()` başlatma sırası, saat biçimleme (cihaz saat diliminden bağımsız)
- [x] agy 010b: Ana Sayfa + `PrayerTimesCubit`. Sıradaki vakit, canlı geri sayım, ilerleme, Miladi + Hicri tarih, 6 vakit, rozetler; ilk açılışta bildirim izni
- [x] agy 010c: Konum Seçimi (elle il → ilçe, Türkçe katlamalı arama, merkez ilçe başta)
- [x] Aylık Vakitler (agy 025/025b, 2026-10-06): bugünden itibaren ~30 gün, bugün vurgulu, Hicri tarih, çevrimdışı notu; Ana Sayfa'da vakit listesinin altında bağlantı. Emülatörde açık/koyu doğrulandı
- [x] Ayarlar (agy 024a/024b, 2026-10-06): kalıcı bildirim aç/kapa, tema (sistem/açık/koyu), konum, veri kaynağı bilgisi
  - Hata düzeltildi: Ana Sayfa her açılışta bildirimi yeniden açıyordu.
  - Emülatörde: kapatınca bildirim ve alarmlar kalktı, soğuk açılışta kapalı kaldı, açınca geri geldi; koyu tema bütün uygulamaya uygulandı.
- [x] agy 017: geçici çözüm olarak Ana Sayfa'da kesin alarm uyarı bandı ve "İzin ver". Uygulama öne gelince durum tazeleniyor
- [ ] İzinler ekranı (Stitch). "Alarmlar ve hatırlatıcılar" izni istenmezse vakit geçişi ~39 dk gecikebilir (emülatörde ölçüldü); şimdilik 017'deki bant bunu karşılıyor
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
- [x] agy 018a: kalan süre özeti ("9 saat kaldı" / "12 dakika kaldı") + görünüm tiki alarmı (`RTC`, yalnız kesin alarm izniyle)
- [x] agy 018b: durum çubuğu simgeleri. Hilal-yıldız; son 60 dakikada cami silüetinde kalan dakika (çalışma anında bitmap)
- [x] agy 018c: kanal `vakit_geri_sayim` (`IMPORTANCE_DEFAULT`, sessiz). `IMPORTANCE_LOW` iken simge durum çubuğunda hiç görünmüyordu (`hideSilentStatusBar=true`)
- [x] agy 018d: cami simgesinde rakam kutusu 13×8,5 → 14×12,5 birim; durum çubuğu boyutunda okunur
- [x] 2026-10-04, telefonda Ezan Vakti'nin yanında simgemiz parçalı ve yumuşak göründü. Nedenleri: minare-gövde boşluğu, kubbe dikişi ve sistemin 24 dp bitmap'i küçültmesi
  - Claude: `tool/gen_status_icons.py` + `tool/fonts/` (Roboto Medium, Apache 2.0). 61 üretilmiş vektör simge, tek parça silüet, evenOdd ile oyulmuş rakamlar
  - agy 019: `MinuteIcons` kaynak seçimi; eski bitmap çizimi silindi
- [x] agy 022 (2026-10-05, Buğra'nın isteği): özet saat kipinde de dakikalı ("1 saat 52 dk kaldı"), tik her dakika. Kanal `vakit_sayac` IMPORTANCE_HIGH + PRIORITY_MAX: sonradan gelen bildirim artık üste geçmiyor (sesli olan ~10 sn üstte kalıp geri iniyor); açılır uyarı çıkmıyor. Emülatörde doğrulandı
- [x] agy 020: kalan süre aşağı yuvarlanıyor (Buğra seçti: geri sayım 44:52 iken simge 44, Ezan Vakti gibi). Simge 60'tan başlar, son dakikada 0 ve "1 dakikadan az kaldı"
- [x] WorkManager günlük yenileme (agy 023, 2026-10-06). `work-runtime` 2.10.0
  - Yüke `districtId` eklendi.
  - Native taraf her gün (ağ koşuluyla) Diyanet'ten ilçenin vakitlerini çekip yükü ve bildirimi tazeliyor; Flutter gerekmiyor.
  - Emülatörde: `pm clear` + konum seçimi → iş hemen çalıştı (SUCCESS), yük Kotlin'in yazdığı alan sırasıyla 32 gün (01.10–01.11), bugünün vakitleri Diyanet'le birebir.
  - Not: WorkManager periyodik işi zorla tetiklemeye izin vermiyor ("executed before schedule"); test ilk çalıştırmayla yapılır.

### Faz 5 — Kıble — KOD TAMAM, cihazda doğrulama bekliyor (2026-10-03)

- [x] agy 015b: native yön, EventChannel `com.sbugrayy.vakit/kible`. `TYPE_ROTATION_VECTOR` (yoksa ivmeölçer + manyetometre), `GeomagneticField` sapmasıyla gerçek kuzey, vektörle yumuşatma. JVM testli
- [x] agy 015a: kıble açısı ve Kâbe'ye mesafe (bağımsız referansla ±0,1°: İstanbul 151,62°), `turnAngle`/`isAligned`, `HeadingSource`
- [x] agy 016: Kıble ekranı (geçici). Pusula kadranı, açı, hizalama metni, kalibrasyon kartı, mesafe; koordinat yoksa "Konumumu bul"a yönlendirme (emülatörde doğrulandı); Ana Sayfa'da "Kıble" eylemi
- [x] Diyanet "kıble saati" kartı (agy 026/026b, 2026-10-06): Kıble ekranında her durumda (koordinat ya da sensör yokken de). Emülatörde Ankara 11:39, Diyanet'le aynı; açık/koyu doğrulandı
- [x] Koordinatlı konumla pusulanın cihazda denenmesi: gerçek telefonda kıble gösteriliyor (Buğra, 2026-10-03)

### Faz 6 — Cila ve teslim

- [x] Uygulama adı "Vakit" (008b)
- [x] Uygulama logosu, agy 021 (2026-10-04). Buğra'nın tarifi: yeşil zemin, sarı ay-yıldız; dört seçenekten "koyu yeşil, hafif ışık" seçildi
  - Uyarlanabilir simge `mipmap-anydpi/ic_launcher.xml`: radyal yeşil zemin, ay-yıldız ön planı, Android 13+ temalı simge katmanı
  - Ay-yıldız durum çubuğu simgesiyle aynı geometride, 66 dp güvenli alanın içinde
  - Flutter'ın eski PNG'leri silindi
  - Ana dosya ve Play Store simgesi: `design/logo/` (SVG + 512 px PNG)
  - Emülatörde uygulama çekmecesinde doğrulandı
  - Bildirim panelindeki uygulama simgesi güncelleme sonrası eski Flutter logosu olarak kaldı. Sistem arayüzünün önbelleği olduğu düşünülüyor; yeniden başlatmadan sonra bakılacak
- [x] Release imzası (2026-10-06). Anahtar `~/.android-keys/vakit-release.jks`, parolalar `android/key.properties` (git dışı). `flutter build apk --release --split-per-abi` → telefon için `app-arm64-v8a-release.apk` (17,9 MB). Emülatörde temiz kurulum, Ankara vakitleri Diyanet'le birebir, bildirim çalışıyor
- [ ] README, `code-review` ve `security-review`
- [ ] Gerçek telefonda uçtan uca deneme
- [x] PR #1: `flutter-rewrite` → `main`, 2026-10-09'da birleşti

### iOS — ERTELENDİ (2026-10-05, Buğra'nın kararı)

Amaç: uygulamayı başka birinin iPhone'unda kullanmak. Buğra'nın Mac'i ve
Apple Developer hesabı yok. Konuşulan yol:

- **Derleme:** GitHub Actions macOS makinesinde imzasız `.ipa`. Depo açık
  olduğu için ücretsiz.
- **Kurulum:** Windows'ta Sideloadly ya da AltStore ile ücretsiz Apple ID
  imzası.
  - 7 günde bir yeniden imzalamak gerekir.
  - Apple ID'yi telefonun sahibi girer; Claude kimlik bilgisi görmez.
- **Kod:** Proje yalnız Android için kuruldu, `ios/` yok. Konum, kıble ve
  bildirim Kotlin kanallarına bağlı.
  - Konum ve kıble için Swift karşılıkları gerekir.
  - Durum çubuğu simgesi iOS'ta mümkün değil. Kalıcı bildirimin karşılığı
    Live Activity (kilit ekranı, Dynamic Island).
- **Onaylanan:** agy'ye yalnız `ios/Runner/` için yazma izni verilecek. Henüz
  verilmedi; iOS işine başlarken `~/.gemini/antigravity-cli/settings.json`'a
  eklenir.
- **Önerilen ilk aşama:** vakitler, konum ve kıble. Live Activity sonra.

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
| Exact izin yokken alarm inexact (~39 dk pencere) | ⚠ 017'de Ana Sayfa uyarı bandıyla karşılandı |
| **Canlı vakit geçişi**: 18:56:25'te bildirim, uygulama açılmadan "Balıkesir • Akşam 18:56" → "Balıkesir • Yatsı 20:13"; sonraki alarm 20:13:01, `window=0` | ✓ |
| Paket güncellemesinde (yeni sürüm kurulumu) alarm yeniden kuruldu | ✓ |
| Kıble: koordinatsız konumda "Konumumu bul"a yönlendirme | ✓ |
| "Konumumu bul": konum izni ve konum alındı, ters geokodlama Norton yüzünden düştü, "listeden seçin" gösterildi | ⚠ gerçek telefonda doğrulanmalı |
| Yeniden başlatma (BOOT_COMPLETED) sonrası bildirim | — yapılmadı; emülatör o sırada kullanılıyor görünüyordu (018 testinde yapıldı, aşağıda) |

## 5b. Kalan süre özeti ve durum çubuğu simgesi (018, 2026-10-03 gece, emülatör)

| Adım | Sonuç |
|---|---|
| Gerçek veri (Balıkesir, İmsak 05:38, saat 23:05): panelde "6 saat kaldı", geri sayım 6:32:43 | ✓ açık ve koyu tema, açık ve kapalı görünüm |
| Durum çubuğunda hilal-yıldız | ✓ 018c'den sonra (öncesinde sessiz kanal yüzünden simge yoktu) |
| Alarmlar: tik `RTC` 23:38:01 ("6 → 5 saat"), vakit sınırı `RTC_WAKEUP` 05:38:01; ikisi de `window=0` | ✓ |
| Sahte yük (vakit 9 dk sonra): cami simgesinde **9**; uygulama süreci kapalıyken 23:07:01 tikinde **8**, 23:14'te **1** | ✓ |
| Vakit geçişi 23:15: bildirim kendiliğinden "Yatsı 00:45"e geçti, simge hilal-yıldıza döndü, sonraki tik "1 saat → 60 dk" anına kuruldu | ✓ |
| İki haneli: **60** → 23:17:01'de **59**, panelde "59 dakika kaldı" | ✓ (018d'nin büyük rakamlarıyla) |
| **Yeniden başlatma** (`adb reboot`), uygulama açılmadan: bildirim, hilal-yıldız ve iki alarm (tik 23:38:01, vakit sınırı 05:38:01) geri geldi | ✓ BOOT_COMPLETED |

## 5c. Vektör dakika simgesi ve aşağı yuvarlama (019–020, 2026-10-04, emülatör)

| Adım | Sonuç |
|---|---|
| Gerçek veri, Balıkesir İkindi 16:18, saat 16:12: geri sayım 05:18, özet "5 dakika kaldı", simge **5** (yeni vektör, tek parça silüet) | ✓ |
| 16:17: simge **0**, özet "1 dakikadan az kaldı"; son dakikada tik kurulmadı, yalnız vakit sınırı alarmı | ✓ |
| 16:18: uygulama açılmadan "Akşam 18:55", "2 saat kaldı", hilal-yıldız; tik 16:55:01, vakit sınırı 18:55:01 | ✓ |
| Sahte yük, kalan 61:12: hilal-yıldız, tik `next - 61 dk + 1 sn`. 13 sn sonra simge **60**, özet "60 dakika kaldı" | ✓ |

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
