#!/usr/bin/env bash
# Bir agy teslimatını kabul etmeden önce çalıştırılır: rapora değil, ölçülen
# sonuca güvenir (bkz. ANTIGRAVITY_CHECKLIST.md madde 4-5). finans-app'teki
# tool/verify_antigravity.sh'ten uyarlandı.
#
# agy ancak temiz bir `git status` üzerinde çalıştırıldığı için (bkz.
# agy-gorev skill'i) buradaki her değişiklik agy'nindir; kapsam kontrolü bu
# varsayıma dayanıyor.
#
# Kullanım:
#   tool/verify_agy.sh --allowed "lib/shared/ test/shared/" [--threshold 90]
#                      [--skip-tests]
#
#   --allowed     Bu görevde değişmesine izin verilen yol önekleri (boşlukla
#                 ayrılmış). Dışındaki her değişiklik hata sayılır.
#   --threshold   lib/ geneli satır kapsama eşiği, yüzde (varsayılan 90).
#   --skip-tests  Testleri ve kapsamayı atla (yalnız hızlı kontrol).
set -uo pipefail

ALLOWED=""
THRESHOLD=90
SKIP_TESTS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --allowed) ALLOWED="$2"; shift 2 ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --skip-tests) SKIP_TESTS=1; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Bilinmeyen argüman: $1" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.." || exit 2

FAIL=0

# Türkçe karakterli yollar sekizlik kaçışla gelmesin diye quotePath kapalı.
CHANGED=$(git -c core.quotePath=false status --porcelain --untracked-files=all \
  | sed -E 's/^.. //; s/.* -> //; s/^"(.*)"$/\1/')

echo "== 1) Kapsam: yalnız izin verilen yollar mı değişti? =="
if [ -z "$CHANGED" ]; then
  echo "UYARI: hiç değişiklik yok. agy bir şey yazmadıysa izinlere bak"
  echo "(boş cevap = izin reddi, bkz. CLAUDE.md 'agy kuralları' 3)."
elif [ -z "$ALLOWED" ]; then
  echo "HATA: --allowed verilmedi; kapsam ölçülmeden teslimat kabul edilmez."
  FAIL=1
else
  OUTSIDE=""
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    ok=0
    for prefix in $ALLOWED; do
      case "$path" in "$prefix"*) ok=1; break ;; esac
    done
    [ "$ok" -eq 0 ] && OUTSIDE="${OUTSIDE}  ${path}"$'\n'
  done <<< "$CHANGED"
  if [ -n "$OUTSIDE" ]; then
    echo "HATA: izin verilen yolların ($ALLOWED) dışında değişiklik var:"
    printf '%s' "$OUTSIDE"
    FAIL=1
  else
    echo "OK: değişen $(echo "$CHANGED" | grep -c .) dosyanın hepsi izinli yollarda."
  fi
fi

echo
echo "== 2) Biçim: dart format =="
if FORMAT_OUT=$(dart format --output=none --set-exit-if-changed lib test 2>&1); then
  echo "OK: biçim temiz."
else
  echo "$FORMAT_OUT"
  echo "HATA: biçimlenmemiş dosya var. Önce 'dart format lib test' çalıştır."
  FAIL=1
fi

echo
echo "== 3) Statik analiz: flutter analyze --fatal-infos =="
if ANALYZE_OUT=$(flutter analyze --fatal-infos 2>&1); then
  echo "OK: analiz temiz."
else
  echo "$ANALYZE_OUT" | grep -E "^\s*(error|warning|info) " || echo "$ANALYZE_OUT"
  echo "HATA: analiz temiz değil."
  FAIL=1
fi

echo
echo "== 4) Yasak kalıplar (değişen .dart / .kt dosyaları) =="
PATTERN_FAIL=0
report() { echo "HATA: $1"; echo "$2" | sed 's/^/    /'; PATTERN_FAIL=1; }
while IFS= read -r f; do
  [ -z "$f" ] || [ ! -f "$f" ] && continue
  case "$f" in
    *.dart|*.kt) ;;
    *) continue ;;
  esac
  if hits=$(grep -n -E "//[[:space:]]*ignore(_for_file)?:" "$f"); then
    report "$f: lint susturma yasak" "$hits"
  fi
  case "$f" in
    lib/*.dart)
      if [ "$f" != "lib/shared/clock.dart" ] \
        && hits=$(grep -n "DateTime\.now()" "$f"); then
        report "$f: DateTime.now() yasak, Clock kullan" "$hits"
      fi
      case "$f" in
        lib/theme/*) ;;
        *)
          if hits=$(grep -n -E "Color\(0x|Colors\.(white|black)\b" "$f"); then
            report "$f: sabit renk yasak, lib/theme/ token'larını kullan" "$hits"
          fi
          ;;
      esac
      if hits=$(grep -n -E "(^|[^A-Za-z_.])(debugP|p)rint\(" "$f"); then
        report "$f: print/debugPrint yasak" "$hits"
      fi
      ;;
    *.kt)
      if hits=$(grep -n -E "while[[:space:]]*\([[:space:]]*true[[:space:]]*\)" "$f"); then
        report "$f: sonsuz döngü yasak, geri sayım Chronometer ile" "$hits"
      fi
      # setTextColor'ın kendisi serbest: values/ + values-night/ renk
      # kaynağıyla vurgu yapmak meşru. Yasak olan sabit renk değeri.
      if hits=$(grep -n -E "parseColor\(\"#|Color\.(WHITE|BLACK)|0x[Ff]{2}[0-9A-Fa-f]{6}" "$f"); then
        report "$f: sabit renk yasak (TextAppearance.Compat.Notification.* ya da res/values{,-night} rengi)" "$hits"
      fi
      ;;
  esac
done <<< "$CHANGED"
if [ "$PATTERN_FAIL" -eq 0 ]; then
  echo "OK: yasak kalıp yok."
else
  FAIL=1
fi

echo
if [ "$SKIP_TESTS" -eq 1 ]; then
  echo "== 5) Testler ve kapsama ATLANDI (--skip-tests) =="
elif [ -z "$(find test -name '*_test.dart' 2>/dev/null | head -1)" ]; then
  echo "== 5) Testler: test/ altında hiç test yok =="
  echo "HATA: teslimat test içermeli (AGENTS.md 'Testler')."
  FAIL=1
else
  echo "== 5) Testler: flutter test --coverage =="
  if ! flutter test --coverage; then
    echo "HATA: testler geçmedi."
    FAIL=1
  fi

  echo
  echo "== 6) Kapsama: lib/ geneli >= %$THRESHOLD =="
  LCOV="coverage/lcov.info"
  if [ ! -f "$LCOV" ]; then
    echo "HATA: $LCOV oluşmadı."
    FAIL=1
  else
    # lcov SF: yolları Windows'ta ters bölü ile gelir; düz bölüye çevir.
    NORMALIZED="$(mktemp)"
    tr '\\' '/' < "$LCOV" > "$NORMALIZED"

    SUMMARY=$(awk '
      /^SF:/ { f=$0; sub(/^SF:/,"",f); cur=(f ~ /(^|\/)lib\//)?1:0; next }
      /^DA:/ { if (cur) { split($0,a,":"); split(a[2],b,",");
               found++; if (b[2]+0>0) hit++ } }
      END { printf "%d %d %.1f", hit+0, found+0, (found>0?100*hit/found:0) }
    ' "$NORMALIZED")
    HIT=$(echo "$SUMMARY" | cut -d' ' -f1)
    FOUND=$(echo "$SUMMARY" | cut -d' ' -f2)
    PCT=$(echo "$SUMMARY" | cut -d' ' -f3)
    echo "lib/: $HIT/$FOUND satır = %$PCT"

    BELOW=$(awk -v p="$PCT" -v t="$THRESHOLD" 'BEGIN{print (p+0 < t+0)?1:0}')
    if [ "$BELOW" = "1" ]; then
      echo "HATA: eşik %$THRESHOLD altında. Kapsanmayan satırlar:"
      awk '
        /^SF:/ { f=$0; sub(/^SF:/,"",f); cur=(f ~ /(^|\/)lib\//)?1:0; next }
        /^DA:/ { if (cur) { split($0,a,":"); split(a[2],b,",");
                 if (b[2]+0==0) print "    " f ":" b[1] } }
      ' "$NORMALIZED" | sed -E 's#^    .*/lib/#    lib/#' | head -40
      FAIL=1
    fi

    # lcov yalnız testlerin yüklediği dosyaları içerir; hiç yüklenmeyen dosya
    # kapsamayı olduğundan yüksek gösterir. Onları ayrıca yakala.
    MISSING=""
    while IFS= read -r src; do
      [ "$src" = "lib/main.dart" ] && continue
      grep -qF "$src" "$NORMALIZED" || MISSING="${MISSING}    ${src}"$'\n'
    done < <(find lib -name '*.dart' | sort)
    if [ -n "$MISSING" ]; then
      echo "HATA: hiçbir testin yüklemediği dosyalar (kapsama %0):"
      printf '%s' "$MISSING"
      FAIL=1
    fi
    rm -f "$NORMALIZED"
  fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "SONUÇ: TÜM KONTROLLER GEÇTİ."
  exit 0
else
  echo "SONUÇ: EN AZ BİR KONTROL BAŞARISIZ. Yukarısını incele; düzeltme agy'ye"
  echo "yeni brifle gider (bkz. agy-gorev skill'i, adım 6)."
  exit 1
fi
