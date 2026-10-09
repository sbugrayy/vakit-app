---
name: agy-gorev
description: "vakit-app'te bir kod işini agy'ye (Antigravity CLI, Gemini 3.8 Flash High) devretme prosedürü: brif yaz, agy'yi çağır, sonucu ölç ve kabul et ya da düzeltme turuna gönder. Claude bu projede uygulama kodunu elle yazmaz; lib/, test/ ya da android/app/src/ altında herhangi bir değişiklik gerektiğinde bu skill kullanılır. Tetikleyiciler: agy'ye ver, agy ile yaz, görev ver, uygula, kodla, implement, düzelt (kod için), testi yaz."
---

# /agy-gorev

Bir kod işini agy'ye devretmek için standart akış. Sınır: **kodu agy yazar,
terminal ve doğrulama Claude'da** (bkz. `CLAUDE.md` "Orkestra"). Bu skill
olmadan `lib/`, `test/` ya da `android/app/src/` altına elle yazma.

## Kullanım

```
/agy-gorev "lib/shared/clock.dart: Clock soyutlaması ve testi"
/agy-gorev Faz 2 — Diyanet API istemcisi
```

## 1. Ön koşullar

- `git status --porcelain` boş olmalı. Değilse önce commit et ya da sor; agy'nin
  değişikliklerini başkalarından ayırmanın tek yolu bu.
- `main`'den açılmış bir iş dalı (`feat/…`, `fix/…`). Asla doğrudan `main`.
- İş tek bir brife sığmalı: en fazla ~6–8 dosya ve tek bir sorumluluk. Büyükse
  böl; agy küçük ve net görevlerde çok daha isabetli.
- Gereken paket ya da Android izni varsa agy'den önce **Claude** ekler
  (`flutter pub add`, gradle). Yeni paket ve izin için önce Buğra'ya sorulur.

## 2. Brif yaz

Numara: `.agy/briefs/` altındaki en büyük numara + 1 (`001`, `002`, …). Düzeltme
turları aynı numaraya harf alır (`003b`, `003c`). Dosya
`.agy/briefs/NNN-kisa-konu.md`, şablon:

```markdown
# Görev NNN: <tek cümlelik başlık>

Hiçbir terminal komutu çalıştırma, sadece dosya oku ve yaz.
AGENTS.md'deki kurallara uy; bu brifle çelişen bir şey görürsen dur ve raporda yaz.

## Bağlam
<1–3 cümle: bu parça neden var, neye bağlanacak>

## Hedef
<ne yapılacak; davranış olarak, ölçülebilir>

## Dokunabileceğin dosyalar (yalnız bunlar)
- lib/...    (oluştur | değiştir)
- test/...   (oluştur)

## Okuman gereken referanslar
- <mevcut dosyalar, design/stitch/<ekran>/screen.png, test/fixtures/...>

## Kabul kriterleri
- [ ] <test edilebilir madde>
- [ ] <hata/boş/yükleniyor durumları>
- [ ] Testler: <hangi senaryolar>

## Kaçınılacak hata kalıpları (ANTIGRAVITY_CHECKLIST.md)
- <ilgili maddeler, kısa>

## Rapor
Sonunda AGENTS.md "Rapor" bölümündeki 5 başlıkla rapor ver.
```

Brif yazarken:

- Dosya listesi **tam yol** ile; "gerekirse başka dosyalar" yazma.
- Var olan kodu değiştirecekse ilgili sınıf/fonksiyon adını ver; agy'nin
  bütün projeyi taraması gerekmesin.
- Tasarım işinde ekranın `screen.png` + `code.html` yolunu ve kullanılacak
  token dosyalarını yaz (bkz. `stitch-to-flutter`).
- Gerçek veri gerekiyorsa önce `curl` ile `test/fixtures/` altına al, brifte
  dosya adını ver.

## 3. agy'yi çalıştır

Bash aracıyla, **arka planda** (`run_in_background: true`, timeout 1800000).
Bitince bildirim gelir; beklerken yoklama yapma, bu sırada başka iş yapılabilir.

```bash
cd "C:/Users/bugra/Documents/GitHub/vakit-app" && \
agy -p "$(cat .agy/briefs/NNN-konu.md)" --model gemini-3.8-flash-high \
    --new-project --output-format stream-json \
    > .agy/runs/NNN.jsonl 2>&1; python tool/agy_rapor.py .agy/runs/NNN.jsonl
```

- `--new-project` zorunlu.
- **`--mode accept-edits` ve `--dangerously-skip-permissions` yasak.** İkisi
  de izin listesini atlıyor. 2026-10-02'de `accept-edits` ile agy izni olmayan
  repo köküne yazdı. Bayraksız çağrıda `write_file(...)` kuralları uygulanıyor.

## 4. Sonucu oku

`python tool/agy_rapor.py .agy/runs/NNN.jsonl` şunları gösterir:

- model ve izin modu
- araç adımları (`ERROR` olanlar dahil)
- agy'nin yazdığı dosyalar
- komut denemeleri
- reddedilen eylemler
- agy'nin raporu

Çıkış kodu 1 ise sorun var.

- **Boş cevap + `denied_actions` = izin reddi**, model hatası değil. agy
  izinsiz bir yere yazmaya (ya da komut çalıştırmaya) çalıştı ve koşu o anda
  bitti. İki ihtimal var:
  - Brif yanlış bir yeri işaret ediyor: brifi düzelt.
  - agy kapsam dışına çıktı: düzeltme turunda kısıtı vurgula.

  İzin dosyasından şüpheleniyorsan `~/.gemini/antigravity-cli/settings.json`
  BOM'suz olmalı (ilk bayt `7B`) ve vakit-app girdilerini içermeli.
- **Kısmi iş**: ret koşuyu yarıda kestiği için bir kısım dosya yazılmış
  olabilir. `git status`'a bak; yarım kalan iş ya geri alınır ya da düzeltme
  turunda tamamlatılır.
- Rapor bir iddiadır, kanıt değil: her maddeyi diff üzerinde doğrula.
  "agy'nin yazdığı dosyalar" listesi `git status` ile birebir örtüşmeli.

## 5. Doğrula (atlama yok)

1. `git status --porcelain`: yalnız brifteki dosyalar mı değişmiş? Fazlası
   varsa nedenini rapordan bul. Gerekçesizse geri al (`git checkout -- <dosya>`
   ya da yeni dosyaysa sil) ve düzeltme turuna not et.
2. `dart format lib test`: mekanik, Claude çalıştırır.
3. `tool/verify_agy.sh --allowed "<brifteki yol önekleri>"`: analyze
   (`--fatal-infos`), testler + coverage, yasak kalıplar ve kapsam dışı
   değişiklik kontrolü.
4. Diff'i oku: brifin kabul kriterleri ve `ANTIGRAVITY_CHECKLIST.md`. Analiz
   aracının yakalamadığı mantık hatalarına bak (gün dönümü, saat dilimi, tema).
5. Uygulama davranışını değiştiren işlerde `flutter run -d emulator-5554` ile
   açıldığını gör. UI işinde açık ve koyu temada ekran görüntüsü al
   (`run` skill'i). Native işte adb kanıtı topla (bkz. `CLAUDE.md` "Doğrulama").

## 6. Kabul ya da düzeltme turu

- **Kabul**: commit (Türkçe Conventional Commits, `Co-Authored-By` yok) ve
  push. `IMPLEMENTATION_PLAN.md` checklist'i işaretlenir. Yeni bir hata kalıbı
  görüldüyse `ANTIGRAVITY_CHECKLIST.md`'ye eklenir.
- **Düzeltme**: `NNNb` brifi yazılır. İçinde şunlar olur:
  - Hatanın **ham çıktısı** (analyze/test satırları).
  - Hangi dosyada ne beklendiği.
  - "Yalnız şu dosyalara dokun" listesi.

  Claude kodu elle düzeltmez; bu tek satırlık bir lint hatası için de geçerli.
- **İki düzeltme turundan sonra** hâlâ olmuyorsa: görevi böl ya da Buğra'ya
  durumu özetleyip sor (model değişikliği, kapsam daraltma gibi).

## Sınırlar

- Bu skill yalnız uygulama kodu içindir. `*.md`, `.claude/`, `tool/` ve
  yapılandırma dosyalarını Claude doğrudan yazar.
- agy'ye asla terminal komutu, git işlemi ya da paket kurulumu yaptırılmaz.
