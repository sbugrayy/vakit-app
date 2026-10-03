# agy Taslakları İçin Kontrol Listesi

agy'nin ürettiği kodda tekrar tekrar çıkan hata kalıplarını toplar. İki
kullanımı var:

- Claude her brife ilgili maddeleri "aşağıdaki hata kalıplarından kaçın"
  şeklinde ekler.
- Teslimatı incelerken diff bu listeyle karşılaştırılır.

`flutter analyze` bunların çoğunu **yakalamaz**; widget testi ya da
emülatör/cihaz denemesiyle bulunurlar.

1–5. maddeler finans-app'te gerçekten yaşanmış kalıplar (`../finans-app/ANTIGRAVITY_CHECKLIST.md`).
6. ve sonrası vakit-app'e özgü risklerdir. Yeni bir kalıp bulununca buraya eklenir.

## 1. Zaten `Expanded`/`Flexible` olan widget'ı tekrar sarmalama

Hem geniş (Row) hem dar (Column) düzende kullanılan alt widget'ları **çıplak**
tanımla. `Expanded`/`Flexible` sarmalamasını yalnız kullanıldığı yerde yap.
Aynı widget'ı iki kez sarmalamak "competing ParentDataWidgets" çökmesine yol açar.

## 2. Sınırsız eksende `Expanded`/`Flexible`

`SingleChildScrollView` ya da `ListView` (shrinkWrap'sız) içindeki bir
`Column`/`Row`'a o eksende `Expanded` koyma. İki şekilde çıkar:

- Çökme: "RenderFlex children have non-zero flex but incoming height constraints are unbounded".
- Daha sinsisi: `pumpAndSettle timed out` / sonsuz relayout.

Doğru desen: o eksende flex'siz widget kullanmak.

## 3. `DropdownButtonFormField` tuzakları (il/ilçe seçimi)

- `isExpanded: true` ve öğe metninde `overflow: TextOverflow.ellipsis`
  kullanılır. Uzun ilçe adlarıyla ("AFYONKARAHİSAR", "KAHRAMANMARAŞ") taşma olur.
- `value`, `items` içindeki hiçbir öğeyle eşleşmezse Flutter sert assertion ile
  çöker. Değeri vermeden önce listede var mı diye kontrol et, yoksa `null` ver.
  Liste henüz yüklenmemişken de aynı kural geçerli.

## 4. Rapor ≠ gerçek kod

Rapor "X düzeltildi" dese bile dosyayı oku. finans-app'te rapor "AppBar başlığı
güncellendi" dediği halde dosyada değişiklik yoktu. Rapordaki her iddia diff
üzerinde doğrulanır.

## 5. Görev sınırı ve sessiz değişiklikler

finans-app'te "sadece test yaz" görevinde üç üretim dosyası sessizce değişmişti:

- Bir "neden" yorumu silinmişti.
- Kullanıcıya görünen bir etiket değişmişti.
- İlgisiz bir tasarım detayı kaldırılmıştı.

Hiçbiri raporda geçmiyordu. Kontrol edilecekler:

- `git status` yalnız brifteki dosyaları göstermeli (`tool/verify_agy.sh --allowed`).
- Var olan "neden" yorumları silinmemiş olmalı.
- Görevle ilgisiz kullanıcı metni değişmemiş olmalı.
- "%100 coverage", "testler geçer" gibi iddialar ölçümle doğrulanır.

## 6. Zaman ve saat dilimi

- `DateTime.now()` kullanılmış mı? Yalnız `Clock` üzerinden olmalı.
- Vakit metni, cihaz saat dilimiyle `DateTime(y, m, d, h, min)` olarak mı
  kurulmuş? Diyanet'in `GreenwichOrtalamaZamani` ofseti kullanılmalı.
- Yatsı'dan sonra sıradaki vakit **ertesi günün** verisinden mi geliyor? Bugünün
  İmsak saatine +1 gün eklemek yanlış.
- Ay sonu ve yıl sonu (31 Aralık → 1 Ocak) ile 30 günlük verinin son günü test edilmiş mi?

## 7. Tema: açık/koyu

- `Colors.white`, `Colors.black` ya da `Color(0x…)` `lib/theme/` dışında
  geçmemeli.
- Ekran yalnız koyu temada mı denenmiş? Widget testi iki temada pump edilmeli.
- Native bildirimde sabit metin rengi (`#FFFFFF`) var mı? Eski uygulamanın açık
  panelde okunmayan bildirimi bundandı.

## 8. Kaynak sızıntısı ve sonsuz döngü

- `Timer.periodic`, `StreamSubscription`, sensör dinleyicisi `close()`/`dispose`
  içinde iptal edilmeli.
- Kotlin'de `while(true)`, global `CoroutineScope`, dakikalık alarm zinciri
  olmamalı. Geri sayım `Chronometer` ile yapılır.
- Saniyelik geri sayım widget'ı yalnız kendini yeniden çizmeli, bütün sayfayı
  değil. `BlocBuilder` için `buildWhen` ya da ayrı küçük widget kullanılır.

## 9. Türkçe karakter

- Dart'ın `toUpperCase()`/`toLowerCase()` fonksiyonları Türkçe'ye duyarlı
  değil: `'i'.toUpperCase()` `'I'` döner, `'İ'` değil. İlçe eşleştirmede iki
  taraf da ASCII'ye katlanarak karşılaştırılır (İ/ı→I, Ş→S, Ğ→G, Ü→U, Ö→O, Ç→C).
- Kullanıcıya görünen metinde ASCII yazım olmamalı: `Ogle`, `Kible`, `Ikindi`,
  `Aksam`, `Yatsi` yanlış; `Öğle`, `Kıble`, `İkindi`, `Akşam`, `Yatsı` doğru.

## 10. Platform kanalları

- Kanal adı Dart ve Kotlin'de birebir aynı mı (`com.sbugrayy.vakit/<ad>`)?
- Native tarafta karşılığı olmayan metot `MissingPluginException` verir. Dart
  tarafı bunu yakalayıp anlamlı davranmalı.
- Testlerde `TestDefaultBinaryMessengerBinding` ile kanal sahte cevaplanır;
  gerçek kanala çıkılmaz.

## 11. Başlatma sırası

`main()` içinde eklentiye dokunmadan önce `WidgetsFlutterBinding.ensureInitialized()`
çağrılmalı. Bu hatayı yalnız `flutter run` gösterir: finans-app'te bütün testler
geçerken uygulama hiç açılmıyordu.

## 12. Paket API'si hakkında eski bilgi

agy'nin bir paketin API'si hakkındaki bilgisi projedeki sürümden eski olabilir.
Görev 003'te dio 5.11'deki `DioExceptionType.transformTimeout`'u bilmediği için
`switch` eksik kaldı ve kod derlenmedi.

- Paket enum'ları üzerindeki `switch`'ler tam olmalı ve `default:` kullanılmamalı.
  Böylece yeni bir değer derleme hatası verip fark ettirir.
- Brifte, kullanılacak paketin sürümüne özgü bilinen ayrıntıları (yeni enum
  değeri, ad çakışması gibi) önceden yaz. Görev 006'da `adhan_dart`'ın
  `Prayer` çakışması böyle verildi.
