# vakit-app — Proje Bağlamı (Claude Code için)

Bu dosya, yeni bir Claude Code oturumunun konuşma geçmişi olmadan da doğru
bağlamla çalışabilmesi için var. Bir karar, konvansiyon ya da ortam bilgisi
değiştikçe bu dosyayı güncel tut.

## Proje Nedir

**Vakit**: Türkiye odaklı namaz vakitleri ve kıble uygulaması (Android). Flutter
ile sıfırdan yazılıyor. İlk sürüm Google AI Studio'da Kotlin/Compose ile
üretilmişti; `main` dalında ve git geçmişinde duruyor. O sürüm iki yüzden
bırakıldı: tasarım (açık/koyu temada tutarsız, sabit renkler) ve bildirim
çubuğunda istenen davranışa ulaşılamaması.

**Önce oku:** `IMPLEMENTATION_PLAN.md` — fazlar, checklist, açık kararlar ve
sıradaki adım. Projenin durumu için tek kaynak orası.

Ürünün omurgası:

- Diyanet ile birebir vakitler (ilçe bazlı), 30 günlük önbellek, internet ya da
  servis yoksa cihazda yedek hesap.
- **Canlı geri sayımlı kalıcı bildirim** (native Kotlin motoru, Flutter
  kapalıyken de çalışır). İçinde geri sayım ve "9 saat kaldı" gibi kısa bir
  özet var. Vakte 60 dakika kala durum çubuğu simgesi kalan dakikayı sayar
  (2026-10-03'te Buğra istedi, örnek Ezan Vakti Pro). Sesli ezan uyarısı ve
  bildirim butonları yok.
- Kıble pusulası (gerçek kuzeye göre).
- Tasarım Google Stitch'ten gelir (`design/stitch/`).

## Orkestra: Kim Ne Yapar

Claude orkestra şefidir; kodu **agy** (Antigravity CLI, Gemini 3.8 Flash High)
yazar. Düzenin kaynağı Buğra'nın Medium yazısı
([Yapay zekâlarla orkestra kurmak](https://medium.com/@bugrayildirim/yapay-zek%C3%A2larla-orkestra-kurmak-78de76f0157c))
ve finans-app'te (`../finans-app/CLAUDE.md` "Alt Ajanlar") doğrulanmış kurulum.
Medium sayfası WebFetch'e 403 dönüyor; yazıyı okumak gerekirse RSS akışından oku:
`https://medium.com/feed/@bugrayildirim`.

| İş | Kim |
|---|---|
| **Tüm terminal komutları**: flutter, dart, git, gh, adb, gradle, curl ve agy çağrısının kendisi | Claude |
| Planlama, görev brifi, mimari karar, paket/bağımlılık ekleme (`flutter pub add`) | Claude |
| Yapılandırma: `pubspec.yaml`, `analysis_options.yaml`, `android/**/*.gradle.kts`, `.gitignore`, `.gitattributes` | Claude |
| Dokümanlar ve orkestra dosyaları: `*.md`, `.claude/`, `tool/`, `design/STITCH_PROMPTS.md` | Claude |
| Doğrulama: format, analyze, test, emülatör/gerçek cihaz, diff incelemesi, commit/push | Claude |
| **Uygulama kodu**: `lib/`, `test/`, `android/app/src/` (Dart, Kotlin, manifest, res) | **agy** |

Kurallar:

- **Claude uygulama kodunu elle yazmaz ve düzeltmez**, tek satırlık düzeltme
  dahil. Yalnız mekanik araç çalıştırır (`dart format`). `flutter analyze` ya da
  test hatası olursa hata çıktısını brife ekleyip agy'yi yeniden çalıştırır.
- Üretilmiş dosyalar istisnadır; agy bunlara dokunmaz, Claude kendi aracıyla
  üretir:
  - `test/fixtures/`: gerçek API yanıtları, `curl` ile.
  - `ic_stat_minute_*.xml`: `tool/gen_status_icons.py` ile.

  Bu `flutter create` gibi mekanik bir çıktıdır, elle yazılmış uygulama kodu
  sayılmaz.
- **agy hiçbir terminal komutu çalıştırmaz**; sadece dosya okur ve yazar.
  Medium yazısındaki ders: komut izinleri headless modda çalışmıyor ve agy'nin
  komut çalıştırması tehlikeli.
- Sınır dört katmanda korunur:
  1. İzin dosyası: komut izni yok; yazma yalnız `lib/`, `test/` ve
     `android/app/src/` altında. Bu katman yalnız `--mode accept-edits`
     **olmadan** çalışır (aşağıya bak).
  2. `AGENTS.md`.
  3. Her prompt'taki sabit "hiçbir terminal komutu çalıştırma" cümlesi.
  4. Claude'un `git status` ve `tool/verify_agy.sh` kontrolü.
- Kullanıcıya **sorulacaklar**: yeni paket, yeni Android izni, Stitch tasarımında
  olmayan bir UX kararı, `main`'e birleştirme.

## agy Nasıl Çağrılır

Her seferinde elle kurma: **`agy-gorev` skill'ini kullan.** Aşağısı arka plan bilgisidir.

Çağrı Bash aracıyla yapılır (Git Bash; prompt'u `$(cat …)` ile vermek için) ve
**arka planda** çalıştırılır (`run_in_background`, timeout 30 dk). Bitince
bildirim gelir, beklerken yoklama yapılmaz.

```bash
agy -p "$(cat .agy/briefs/NNN-konu.md)" --model gemini-3.8-flash-high \
    --new-project --output-format stream-json \
    > .agy/runs/NNN.jsonl 2>&1
python tool/agy_rapor.py .agy/runs/NNN.jsonl   # özet: rapor, araçlar, retler
```

**Medium yazısındaki ve finans-app'teki çağrıdan farkı: `--mode accept-edits`
YOK.** 2026-10-02 duman testinde ölçüldü:

- Bu bayrakla agy izin listesine bakmadan çalışma alanındaki her düzenlemeyi
  onaylıyor. Yazma izni yalnız `lib/`, `test/` ve `android/app/src/` iken repo
  köküne dosya yazdı.
- Bayrak olmadan (`permission_mode: request-review`) `write_file(...)` kuralları
  uygulanıyor. İzinsiz yazma reddediliyor ve koşu boş cevapla bitiyor.

finans-app'te yazma izni bütün projeye verildiği için bu fark görünmemişti.

agy 1.2.10'da kullanılabilecek diğer bayraklar:

- `--effort low|medium|high`
- `--sandbox`: terminal kısıtlı çalışma
- `--json-schema`: son çıktıyı şemaya zorlar
- `--input-format stream-json`: prompt'u stdin'den NDJSON olarak alır

Model kimliği `agy models` ile teyit edildi: `gemini-3.8-flash-high`, "Gemini
3.8 Flash (High)". Oturum açık değilse agy "Please sign in" der. Giriş yalnız
etkileşimli `agy` ile yapılabiliyor; bunu Buğra yapar.

### agy kuralları — bunlara uymadan çalışmaz

1. **`--new-project` zorunlu.** agy kalıcı bir proje hafızası tutuyor ve bu
   hafıza başka bir projeye kilitlenebiliyor (finans-app'te başka projenin
   planını okuyup kendinden emin, yanlış bir cevap verdi).
2. **`~/.gemini/antigravity-cli/settings.json` BOM'suz olmalı.** PowerShell
   `Set-Content`/`Out-File` dosyaya BOM ekler; agy dosyayı ayrıştıramaz ve
   **sessizce varsayılanlara düşer**. Dosyayı Write aracıyla yaz, ilk bayt `7B`
   (`{`) olmalı. Geçerliliği yalnız etkileşimli `agy` bildirir ("Settings Error").
3. **Boş cevap = izin reddi.** Headless modda agy izin soramaz. İzinsiz bir
   araç çağrısı koşuyu o anda bitirir ve şu üç iz kalır:
   - Sonuç `status: SUCCESS`, `response: ""` olur; `result.denied_actions`
     reddedilen eylemi listeler (ör. `write_file`).
   - stderr'e `jetski: no output produced — a tool required the "write_file" permission ...` yazılır.
   - `step_update` içinde o araç `ERROR` durumundadır.

   `tool/agy_rapor.py` üçünü de gösterir. Modeli ya da prompt'u suçlamadan önce
   buna bak.
4. **`--dangerously-skip-permissions` ve `--mode accept-edits` kullanılmaz.**
   İkisi de izin listesini, yani sınırın birinci katmanını devre dışı bırakır.
5. **Terminal komutu çalıştırtma.** Her prompt'a yaz: "Hiçbir terminal komutu
   çalıştırma, sadece dosya oku ve yaz." İzin dosyasında komut izni olmadığı
   için `run_command` denemesi de reddedilir.

Bu makinedeki izin dosyası (2026-10-02; `command(...)` izinleri Buğra'nın
onayıyla kaldırıldı, önceki hali `settings.json.bak`'ta):

```json
"read_file(C:\\Users\\bugra\\Documents\\GitHub\\vakit-app)",
"write_file(C:\\Users\\bugra\\Documents\\GitHub\\vakit-app\\lib)",
"write_file(C:\\Users\\bugra\\Documents\\GitHub\\vakit-app\\test)",
"write_file(C:\\Users\\bugra\\Documents\\GitHub\\vakit-app\\android\\app\\src)",
"read_file(C:\\Users\\bugra\\AppData\\Local\\Pub\\Cache)",
"read_file(C:\\Users\\bugra\\dev\\flutter)"
```

Son iki satır 2026-10-03'te eklendi, yalnız okuma izni veriyorlar. agy paket
kaynağını okuyamayınca görevi durdurmuştu; artık paket ve Flutter API'sini
yerel kaynaktan doğrulayabiliyor.

**agy'nin internet erişimi yok.** `read_url` izni verilmedi; web'e bakmaya
çalışırsa koşu reddedilip boş biter. Brif gereken bilgiyi içermeli ya da
yerel kaynağı göstermeli (pub önbelleği, `test/fixtures/`).

`trustedWorkspaces` içinde de vakit-app var. Etkileşimli `agy` girişte aynı
klasörü bir kez daha `...\Github\vakit-app` yazımıyla ekledi; Windows'ta zararsız.
Dosya finans-app ve crmapi ile ortak, o projelerin girdilerine dokunma.

Duman testleri (2026-10-02, kayıtlar `.agy/runs/000*.jsonl`):

| Test | Sonuç |
|---|---|
| Salt-okuma | AGENTS.md'yi okudu, kuralları doğru özetledi |
| `accept-edits` ile köke yazma | yazdı (sınır delindi) |
| Bayraksız köke yazma | `denied_actions: write_file` ile reddedildi |
| Bayraksız `lib/` ve `test/` altına yazma (görev 001) | yazdı, yalnız brifteki 3 dosya |
| Bayraksız `flutter --version` denemesi | `denied_actions: command` ile reddedildi |

`--sandbox` gerekmiyor: komut izni olmadığı için `run_command` zaten reddediliyor.

## Görev Akışı (her kod işi)

1. `git status` temiz, dal `flutter-rewrite` (ya da ondan açılmış bir iş dalı).
2. Brif `.agy/briefs/NNN-konu.md` (şablon `agy-gorev` skill'inde). Dokunulacak
   dosyalar **tek tek** yazılır; ilgili `ANTIGRAVITY_CHECKLIST.md` maddeleri eklenir.
3. agy arka planda çalışır, çıktı `.agy/runs/NNN.jsonl`. Özet için
   `python tool/agy_rapor.py .agy/runs/NNN.jsonl` kullanılır.
4. Doğrulama:
   1. `git status`: yalnız brifteki dosyalar değişmiş olmalı.
   2. `dart format lib test`.
   3. `tool/verify_agy.sh --allowed "<önekler>"`.
   4. Diff brife ve checklist'e göre okunur: **rapora değil koda güven** (finans-app'te rapor "düzeltildi" dediği halde dosya değişmemişti).
   5. `flutter run` ile uygulama açılıyor mu.
   6. UI işlerinde açık ve koyu temada ekran görüntüsü `screen.png` ile karşılaştırılır.
5. Kabul edilmezse brif hata çıktısıyla güncellenir, yeniden çalıştırılır. **İki
   düzeltme turundan sonra** görev bölünür ya da Buğra'ya danışılır.
6. Kabulde commit + push; `IMPLEMENTATION_PLAN.md` checklist'i işaretlenir.

## Git

- Uzak depo: `github.com/sbugrayy/vakit-app`, Buğra'nın kişisel reposu.
  **Claude commit'ler ve push eder.**
- Çalışma dalı `flutter-rewrite`. `main` eski Kotlin sürümü; MVP bitince PR ile
  birleşir. `main`'e doğrudan push yok.
- Commit mesajı Türkçe ve Türkçe karakterli. Konu satırı Conventional Commits
  (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`), gövde madde madde
  ne ve neden.
- **Commit mesajlarına `Co-Authored-By` satırı eklenmez** (Buğra'nın kararı,
  finans-app ile aynı).
- İş yapıldığı gün commit'lenir, birikmiş halde bırakılmaz.

## Mimari Özet

Yığın finans-app ile aynı: flutter_bloc (Cubit), go_router, dio, equatable,
intl, very_good_analysis, bloc_test, mocktail. Platform eklentileri
(shared_preferences, geolocator, geocoding, permission_handler) ve `adhan`
ihtiyaç duyulan fazda eklenir; her eklemeden sonra APK derlenir.

```
lib/  main.dart · app/ · navigation/app_router.dart
  theme/          app_colors · app_spacing · app_typography · app_theme (açık/koyu)
  shared/         clock.dart, ortak widget'lar
  prayer_times/   cubit · models · repository · view · widgets
  location/       GPS + ters geokodlama → Diyanet il/ilçe eşleme, elle seçim
  qibla/          heading (EventChannel) · kıble açısı · pusula
  notifications/  native bildirim motoruna MethodChannel köprüsü
  settings/  onboarding/
android/app/src/main/kotlin/com/sbugrayy/vakit/
  notification/   store · alarm zamanlayıcı · receiver'lar · kalıcı bildirim · WorkManager
  qibla/          rotation-vector + GeomagneticField heading
```

### Vakit verisi: Diyanet

Kaynak `https://ezanvakti.emushaf.net`. Gayriresmî ama Diyanet verisini
birebir veriyor ve anahtar istemiyor. Resmî Diyanet API'si hesap istiyor;
mobil uygulamaya gömülecek bir sır gerektirdiği için kullanılmıyor.

| Uç | Dönen |
|---|---|
| `GET /sehirler/2` | Türkiye illeri: `SehirAdi`, `SehirAdiEn`, `SehirID` |
| `GET /ilceler/{SehirID}` | `IlceAdi`, `IlceAdiEn`, `IlceID` (ör. İstanbul `539`) |
| `GET /vakitler/{IlceID}` | ~30 gün, bugünden 1–2 gün öncesinden başlar |

`vakitler` alanları: `MiladiTarihKisa` (`30.09.2026`), `HicriTarihUzun`
(`19 Rebiulahir 1448`), `Imsak`, `Gunes`, `Ogle`, `Ikindi`, `Aksam`, `Yatsi`,
`KibleSaati`, `GunesDogus`, `GunesBatis`, `GreenwichOrtalamaZamani` (`3.0`).

- Vakit metinleri yerel saattir; `GreenwichOrtalamaZamani` ofsetiyle mutlak
  zamana çevrilir, cihaz saat dilimine güvenilmez.
- İlçe adları tutarsız yazılıyor ("ARNAVUTKOY" ve "BAŞAKŞEHİR" aynı listede):
  eşleştirme Türkçe karakterler ASCII'ye katlanarak yapılır.
- Servis ya da internet yoksa `adhan` paketiyle (Türkiye metodu) hesaplanır ve
  ekranda "çevrimdışı hesap" gösterilir.
- Eski uygulamadaki hata tekrarlanmasın: Aladhan'ın `Imsak` alanı Fajr−10 dk'dır,
  Diyanet İmsak'ı değildir.

### Kalıcı bildirim (native)

- Flutter vakitleri (epoch) MethodChannel ile native tarafa verir. Native taraf
  Dart'a ihtiyaç duymadan çalışır.
- Görünüm `DecoratedCustomViewStyle` ile tema uyumlu RemoteViews:
  - Kapalıyken: ilçe, sıradaki vakit, geri sayım ve kalan süre özeti
    ("9 saat kaldı"; son saatte "12 dakika kaldı").
  - Saat ve dakika **aşağı yuvarlanır**; yanındaki geri sayımın hanesiyle
    ve Ezan Vakti ile aynı (kalan 44:52 → 44). Buğra 2026-10-04'te seçti.
  - Dakika kipi kalan 61 dakikanın altında başlar: simge 60'tan sayar. Son
    dakikada simge 0, özet "1 dakikadan az kaldı".
  - Açıkken: aynı satırlar, altında 6 vakit, sıradaki vurgulu.
- Kanal `vakit_geri_sayim`: `IMPORTANCE_DEFAULT`; ses, titreşim ve ışık
  kapalı. Bildirim builder'da `setSilent` + `setOnlyAlertOnce`.
  - `IMPORTANCE_LOW` "sessiz" sayılır. Pixel'de varsayılan
    `hideSilentStatusBar=true` ve sessiz bildirimin simgesi durum çubuğunda
    gösterilmez; 2026-10-03'te emülatörde ölçüldü.
  - İlk kanal `vakit_kalici` bu yüzden siliniyor. Kanal önemi sonradan kodla
    yükseltilemiyor, yeni kimlik şart.
- Durum çubuğu simgesi:
  - Vakte 60 dakikadan fazla varken hilal-yıldız (`ic_stat_vakit`).
  - Son 60 dakikada cami silüeti, içinde kalan dakika. Her dakika için ayrı
    vektör kaynak var: `ic_stat_minute_00.xml` … `_60.xml`.
  - Bu kaynaklar **üretilmiş**. Üreten betik `tool/gen_status_icons.py`;
    tek parça silüet, Roboto Medium rakamları (`tool/fonts/`, Apache 2.0) ve
    `evenOdd` ile oyma kullanıyor. Tasarım betikte değişir, ardından
    `python tool/gen_status_icons.py --preview .agy/onizleme/x.png` çalıştırılır.
    `verify_agy.sh` dosyaların elle değişmediğini `--check` ile denetler.
    Gereken Python paketleri: fontTools, shapely; önizleme için Pillow, numpy.
  - Neden bitmap değil: 2026-10-04'te telefonda ilk sürüm (çalışma anında
    24 dp bitmap) Ezan Vakti'nin simgesinin yanında yumuşak ve parçalı
    görünüyordu. Sistem bitmap'i ~14 dp'ye küçültüyor; vektörü ise o boyutta
    yeniden çiziyor.
- Geri sayım RemoteViews içindeki countdown `Chronometer` ile işler. Eski
  uygulamadaki `while(true)` coroutine yaklaşımı yasak.
- Alarmlar tek seferliktir. Boot, saat ya da saat dilimi değişimi ve paket
  güncellemesinde yeniden kurulur. İki tür var:
  - **Vakit sınırı**: exact, `RTC_WAKEUP`.
  - **Görünüm tiki**: özetin ya da simgenin değişeceği an. Saat sınırlarında
    ve son 60 dakikada dakikada bir kurulur. `RTC` olduğu için cihazı
    uyandırmaz, ekran açılınca teslim edilir.
  - Tik `setExactAndAllowWhileIdle` ile kurulur. Bu bayraklı alarmlar uygulama
    bekleme kovası kotasından muaf; bayraksız `setExact` "working set"
    kovasında saatte ~10 alarma kısılıyor.
- Exact alarm izni yoksa vakit sınırı inexact kurulur ve uygulamada uyarı
  gösterilir. Özet ve dakika simgesi o durumda **hiç gösterilmez**: Android
  12+ inexact alarmı en az 10 dk geciktirebildiği için yanlış sayı göstermek
  yerine göstermemek seçildi.
- Veri her gün WorkManager ile yenilenir.

## Komutlar ve Ortam

- Flutter 3.44.6 / Dart 3.12.2: `C:\Users\bugra\dev\flutter` (PATH'te).
- Android SDK `%LOCALAPPDATA%\Android\Sdk`. **`adb` PATH'te değil**; Git Bash'te
  `"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"`.
- Emülatör: `Pixel_8`, başlatmak için
  `"$LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd Pixel_8`.
- **Gradle derlemesi `GRADLE_OPTS` ister** (aşağıda "Bilinen ortam sorunları").

```bash
flutter analyze --fatal-infos
flutter test --coverage
tool/verify_agy.sh --allowed "lib/shared/ test/shared/"
flutter run -d emulator-5554
flutter build apk --debug
```

- Dosyaları **Write/Edit aracıyla** yaz. PowerShell `Set-Content`/`Out-File`
  BOM ekler; agy ayar dosyasında bu sessiz kilitlenme yapıyor.
- agy ve `tool/*.sh` Bash aracıyla çalıştırılır.

## Doğrulama: "Testler Geçti" ≠ "Çalışıyor"

finans-app'te `flutter analyze` temizdi, 552 test geçiyordu, APK derleniyordu
ve uygulama Android'de hiç açılmıyordu (`runApp()`'ten önce eklenti
başlatılmış, `WidgetsFlutterBinding.ensureInitialized()` çağrılmamıştı). Birim
testleri bu sınıf hataları görmez. Sıra her zaman: statik analiz → testler →
emülatörde/cihazda çalıştırma. Hiçbiri atlanmaz.

- Hatayı `flutter run` gösterir; `flutter build apk` + `am start` göstermez.
- Bildirim ve alarm kanıtı:
  - `adb shell dumpsys notification --noredact`
  - `adb shell dumpsys alarm | grep com.sbugrayy.vakit`
- Vakit geçişi: emülatör saati sıradaki vakitten 1 dk önceye alınır, bildirimin
  bir sonraki vakte geçtiği görülür. Yeniden başlatmadan sonra bildirim geri gelmeli.
- Konum: `adb emu geo fix <boylam> <enlem>` (önce boylam). İstanbul için
  `adb emu geo fix 28.97 41.01`.
- Vakitler `curl https://ezanvakti.emushaf.net/vakitler/<IlceID>` çıktısıyla
  birebir karşılaştırılır.
- Bildirim hem açık hem koyu bildirim panelinde okunur olmalı.

## Emülatörde Uçtan Uca Test (2026-10-03'te kuruldu)

- **Emülatörü bağımsız başlat.** Bash arka plan görevleri ~30 dk'da
  öldürülüyor ve emülatörü de kapatıyor. PowerShell'den başlat:
  ```powershell
  Start-Process "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -ArgumentList '-avd','Pixel_8','-no-boot-anim','-dns-server','8.8.8.8,1.1.1.1'
  ```
  `-dns-server` şart: emülatörün yerleşik DNS vekili (10.0.2.3) bu makinede
  isim çözmüyor.
- **Norton ve HTTPS.** Norton, emülatör trafiğini de kendi köküyle yeniden
  imzalıyor ("Norton Web/Mail Shield Root"). İki önlem alındı:
  - Kök sertifika emülatörün kullanıcı deposuna yüklendi (Ayarlar →
    Encryption & credentials → Install a certificate → CA certificate).
  - `dart:io` kullanıcı sertifikalarını okumadığı için uygulama debug'da
    ek kökü derleme anında alıyor:
    ```bash
    flutter run -d emulator-5554 --dart-define=DEV_EXTRA_CA_PEM_B64=$(cat .agy/norton_root.pem.b64)
    ```
  `.agy/norton_root.*` git dışında ve makineye özel. Yeniden üretmek için
  sertifikayı Windows'un `Cert:\LocalMachine\Root` deposundan dışa aktar ve
  PEM'in base64'ünü al. Release derlemesinde bunların hiçbiri etkili değil.
- **Kesin alarm izni.** Android 14+'da "Alarmlar ve hatırlatıcılar" izni
  varsayılan kapalı; o zaman alarm inexact kalır (ölçülen pencere ~39 dk).
  Testte izni ver:
  `adb shell appops set com.sbugrayy.vakit SCHEDULE_EXACT_ALARM allow`
  Uygulama öne gelince (`onResume`) alarm kesinleşir: `dumpsys alarm`'da
  `window=0`. Kullanıcıya bu izni istettiren ekran henüz yok (Faz 3).
- **Arayüzü sürmek:** `python tool/adb_ui.py dump`, `tap "metin"`,
  `tap "=birebir"`, `has "metin"`. Türkçe karakter `adb shell input text` ile
  yazılamıyor; aramada ASCII kullan (`istanbul`), eşleştirme Türkçe
  karakterleri katlıyor.
- Emülatör imajı Play Store'lu (`adb root` yok); sistem saati değiştirilemez.
  Vakit geçişi gerçek saatle ya da `dumpsys alarm` ile doğrulanır. 2026-10-03'te
  Akşam → Yatsı geçişi canlı izlendi.
- **Saati değiştirmeden "son 60 dakika" testi (sahte yük).** Native motor
  yükü `shared_prefs/vakit_bildirim.xml` içindeki `payload_json`'dan okur.
  Debug sürümde:
  1. Uygulamayı arka plana al ve `adb shell am kill com.sbugrayy.vakit` ile
     kapat. `force-stop` kullanma: uygulama "stopped" olur, yayın almaz.
  2. Vakitleri birkaç dakika sonraya koyan XML'i yaz:
     `adb shell "run-as com.sbugrayy.vakit sh -c 'cat > shared_prefs/vakit_bildirim.xml'" < sahte.xml`
  3. Uygulamayı açmadan tazelemeyi tetikle:
     `appops set com.sbugrayy.vakit SCHEDULE_EXACT_ALARM deny`, ardından
     `allow`. İzin verilince sistem `SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED`
     yayınını gönderir.
  4. Uygulamayı açınca Dart gerçek yükü yeniden yazar.
  Durum çubuğu simgesi `dumpsys`'te yalnız `Icon(typ=BITMAP ...)` görünür;
  rakam ekran görüntüsünden okunur.
- **Emülatörde ters geokodlama çalışmıyor.** Play Services'in geokodlayıcısı
  da Norton'a takılıyor ve kullanıcı sertifikalarına güvenmiyor
  (`GmsGeocoder: reverse geocoding network failure`). "Konumumu bul" bu yüzden
  emülatörde "listeden seçin" ile biter. Akış gerçek telefonda doğrulanmalı.
  Konum testi için `adb emu geo fix <boylam> <enlem>`.
- Emülatörü Buğra da kullanabiliyor (2026-10-03'te konum elle Balıkesir'e
  çevrilmişti). Dokunma otomasyonundan önce ekranda ne olduğuna bak; birisi
  kullanıyorsa yalnız `dumpsys` gibi pasif gözlem yap.

## Bilinen Ortam Sorunları

- **PKIX / Norton**: Gradle (wrapper dahil) `PKIX path building failed` ile
  düşüyor; sebep Norton'un TLS taraması. Çözüm:
  ```bash
  export GRADLE_OPTS="-Djavax.net.ssl.trustStore=C:/Users/bugra/.gradle/cacerts-with-norton -Djavax.net.ssl.trustStorePassword=changeit"
  ```
- **İnternet yavaş, büyük indirmeler saatler sürebilir.** Norton taraması
  altında Gradle dağıtımı ~3,4 MB/dk indi. Bu yüzden:
  - İlk derlemeyi uzun zaman aşımıyla başlat (`run_in_background`, timeout
    7200000). 30 dk'lık sınıra takılan görev kabuğu öldürüyor ama Gradle
    wrapper'ı (java) arkada çalışmaya devam ediyor. Durdurmak için süreci
    `taskkill` ile kapat.
  - Wrapper yarım indirmeyi sürdürmez.
  - Android araç zinciri bu yüzden **önbellekteki sürümlere sabit**: AGP
    8.12.0, Kotlin 2.2.20, Gradle 9.0.0 (gerekçesi
    `android/settings.gradle.kts`'te). İndirmesiz derleme ~3 dk. Sürüm
    değiştirmek büyük indirme demek.
  - Yüzlerce MB'lık bir indirme başlatmadan önce Buğra'ya sor.
- **agy açılışta ağ hatası verebiliyor.** 2026-10-04'te koşu 0 sn'de
  `status: ERROR` ile bitti, hiçbir dosya yazılmadı. stderr:
  `Eligibility check failed: failed to get profile picture: … TLS handshake timeout`.
  Bu bir izin reddi değil, ağ zaman aşımı. Aynı brifle yeniden çalıştırmak
  yetti.
- **`flutter build` ile `flutter test` aynı anda çalıştırılmaz.** 2026-10-03'te
  derleme, arkada `tool/verify_agy.sh` çalışırken Gradle iç hatasıyla düştü
  (`Cannot invoke "java.util.List.get(int)" because "path" is null`). Tek
  başına tekrarlanınca 2 dakikada geçti. Derlemeyi agy ve doğrulama
  bitince başlat.
- **Emülatör saat dilimi UTC.** Uygulama vakitleri cihaz saat diliminden
  bağımsız hesaplamalı; ekranda gösterilen saatler yine Türkiye saatiyle
  (verinin ofsetiyle) yazılmalı.
- **intl 0.20.2 sabit**: Flutter 3.44.6'nın `flutter_localizations`'ı bunu
  istiyor; yükseltme `pub get`'i kırar (gerekçesi `pubspec.yaml`'da).
- **Satır sonları**: makinede `core.autocrlf=true`; `.gitattributes` her şeyi
  LF'e sabitliyor (CRLF'li `.sh` Git Bash'te kırılır).
- Arka planda çalışan komutun çıkış kodu **son komutunkidir**:
  `cmd > log; tail log` her zaman 0 döner. Derleme gibi işlerde
  `cmd > log 2>&1; ec=$?; tail log; exit $ec` kullan.

## Skill'ler

- **`agy-gorev`** (proje): bir kod işini agy'ye devretme prosedürü: brif
  şablonu, çağrı, doğrulama, düzeltme turu.
- **`stitch-to-flutter`** (proje): `design/stitch/<ekran>/` → token eşlemeli
  brif → agy → `screen.png` ile görsel karşılaştırma.
- `run`: uygulamayı başlatıp ekran görüntüsü almak için.
- `code-review`: faz sonunda, PR öncesi.
- `security-review`: release öncesi.

## Konvansiyonlar

- Ekran adları her yerde (kod, commit, plan) Türkçe ve Stitch'tekiyle aynı:
  "Ana Sayfa", "Kıble", "Aylık Vakitler", "Konum Seçimi", "Ayarlar", "İzinler".
- Vakit adları: İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı (Türkçe karakterli).
- Lint kuralı `// ignore:` ile susturulmaz. Bir kural mimariyle gerçekten
  çelişiyorsa `analysis_options.yaml`'da tek yerde ve gerekçesiyle kapatılır.
  Şu an kapalı olanlar: `public_member_api_docs`, `one_member_abstracts`.
- agy'nin yeni bir hata kalıbı bulununca `ANTIGRAVITY_CHECKLIST.md`'ye eklenir.
- Anlamlı bir iş bitince `IMPLEMENTATION_PLAN.md` güncellenir.
