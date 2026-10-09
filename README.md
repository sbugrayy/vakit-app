# Vakit

Türkiye için namaz vakitleri ve kıble uygulaması (Android, Flutter).

- **Diyanet ile birebir vakitler**: ilçe bazlı, 30 günlük önbellek; internet
  yoksa cihazda yedek hesap.
- **Canlı geri sayımlı kalıcı bildirim**: sıradaki vakit ve saniye saniye işleyen
  geri sayım, uygulama kapalıyken de.
- **Kıble pusulası**: manyetik sapması düzeltilmiş, gerçek kuzeye göre.

> Durum: Flutter sürümü `main`'de (2026-10-09). İlk sürüm (Kotlin/Compose) git
> geçmişinde. İlerleme ve açık işler için `IMPLEMENTATION_PLAN.md`.

## Çalıştırma

Gereksinimler: Flutter 3.44+, Android SDK, Android 8.0+ (API 26) cihaz ya da
emülatör.

```bash
flutter pub get
flutter run
```

Bu makinede Gradle, Norton'un TLS taraması yüzünden `PKIX path building failed`
verirse `CLAUDE.md` → "Bilinen Ortam Sorunları" bölümüne bak.

## Geliştirme düzeni

Kod, Claude Code (şef: plan, terminal, doğrulama) ve agy (Antigravity CLI,
Gemini: kod yazımı) arasında bölünmüş bir orkestrayla yazılıyor:

- `CLAUDE.md`: proje bağlamı, iş bölümü, agy çağrısı, doğrulama kuralları
- `AGENTS.md`: kod yazan ajanın uyduğu kurallar
- `ANTIGRAVITY_CHECKLIST.md`: agy taslaklarında aranan hata kalıpları
- `tool/verify_agy.sh`: her agy teslimatından sonra çalışan doğrulama

## Veri kaynağı

Vakitler Diyanet İşleri Başkanlığı verisinden, `ezanvakti.emushaf.net`
üzerinden alınır.
