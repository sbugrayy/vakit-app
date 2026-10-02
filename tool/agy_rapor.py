"""agy'nin `--output-format stream-json` çıktısını okunur bir özete çevirir.

Kullanım:
    python tool/agy_rapor.py .agy/runs/NNN.jsonl

Gösterdikleri: model ve izin modu, araç adımları (hata verenler dahil), agy'nin
yazdığını söylediği dosyalar, komut denemeleri, reddedilen eylemler ve agy'nin
son raporu. Rapor bir iddiadır; yazılan dosyalar her zaman `git status` ile
karşılaştırılır (bkz. agy-gorev skill'i).

Çıkış kodu: 0 = rapor var ve reddedilen eylem yok; 1 = boş cevap, ret ya da
SUCCESS dışı durum (CLAUDE.md "agy kuralları" 3); 2 = dosya okunamadı.
"""

import json
import os
import sys

WRITE_TOOLS = {
    "write_to_file",
    "replace_file_content",
    "multi_replace_file_content",
    "sed_file",
    "notebook_edit",
}
COMMAND_TOOLS = {"run_command", "send_command_input", "command_status"}
PATH_KEYS = ("TargetFile", "AbsolutePath", "FilePath", "Path", "File")


def kisalt(metin, uzunluk=160):
    metin = " ".join(str(metin).split())
    return metin if len(metin) <= uzunluk else metin[: uzunluk - 1] + "…"


def hedef_yol(parametreler, cwd):
    if not isinstance(parametreler, dict):
        return None
    for anahtar in PATH_KEYS:
        deger = parametreler.get(anahtar)
        if isinstance(deger, str) and deger:
            yol = os.path.normpath(deger)
            if cwd:
                try:
                    goreli = os.path.relpath(yol, os.path.normpath(cwd))
                    if not goreli.startswith(".."):
                        return goreli.replace("\\", "/")
                except ValueError:
                    pass
            return yol.replace("\\", "/")
    return None


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    sys.stdout.reconfigure(encoding="utf-8")

    try:
        with open(sys.argv[1], encoding="utf-8") as dosya:
            satirlar = [s.rstrip("\n") for s in dosya if s.strip()]
    except OSError as hata:
        print(f"HATA: {sys.argv[1]} okunamadı: {hata}")
        return 2

    olaylar, json_disi = [], []
    for satir in satirlar:
        try:
            olaylar.append(json.loads(satir))
        except json.JSONDecodeError:
            json_disi.append(satir)

    init = next((o["init"] for o in olaylar if o.get("event") == "init"), {})
    sonuc = next(
        (o["result"] for o in olaylar if o.get("event") == "result"), None
    )
    cwd = init.get("cwd", "")

    print(f"model: {init.get('model')} | izin modu: "
          f"{init.get('permission_mode')} | cwd: {cwd}")

    print("\n== Araç adımları ==")
    yazilanlar, komutlar = [], []
    for olay in olaylar:
        adim = olay.get("step_update")
        if not adim or adim.get("step_type") != "tool":
            continue
        if adim.get("state") == "ACTIVE":
            continue
        bilgi = adim.get("tool_info") or {}
        ad = bilgi.get("name") or adim.get("tool_name")
        parametreler = bilgi.get("parameters")
        yol = hedef_yol(parametreler, cwd)
        cikti = bilgi.get("output") or ""
        print(f"  [{adim.get('step_index')}] {adim.get('state'):5} {ad}"
              f" {yol or kisalt(json.dumps(parametreler, ensure_ascii=False), 100)}"
              f"{' -> ' + kisalt(cikti, 120) if cikti else ''}")
        if ad in WRITE_TOOLS and adim.get("state") == "DONE" and yol:
            yazilanlar.append(yol)
        if ad in COMMAND_TOOLS:
            komutlar.append(kisalt(json.dumps(parametreler, ensure_ascii=False)))

    print("\n== agy'nin yazdığı dosyalar (git status ile karşılaştır) ==")
    for yol in sorted(set(yazilanlar)) or ["(yok)"]:
        print(f"  {yol}")

    sorun = False
    if komutlar:
        sorun = True
        print("\n!! KOMUT DENEMESİ (AGENTS.md kural 1 ihlali):")
        for komut in komutlar:
            print(f"  {komut}")

    if json_disi:
        print("\n== JSON dışı çıktı (stderr) ==")
        for satir in json_disi:
            print(f"  {kisalt(satir, 400)}")

    print("\n== Sonuç ==")
    if sonuc is None:
        print("HATA: result olayı yok; koşu yarıda kesilmiş olabilir.")
        return 1
    kullanim = sonuc.get("usage") or {}
    print(f"durum: {sonuc.get('status')} | süre: "
          f"{sonuc.get('duration_seconds', 0):.0f} sn | tur: "
          f"{sonuc.get('num_turns')} | token: {kullanim.get('total_tokens')}")
    reddedilenler = sonuc.get("denied_actions") or []
    if reddedilenler:
        sorun = True
        print("!! REDDEDİLEN EYLEMLER (izin dışı deneme):")
        for eylem in reddedilenler:
            print(f"  {eylem.get('action')} ({eylem.get('display_name')})")
    if sonuc.get("status") != "SUCCESS":
        sorun = True
    cevap = sonuc.get("response") or ""
    if not cevap.strip():
        sorun = True
        print("!! BOŞ CEVAP: izin reddi olabilir (CLAUDE.md 'agy kuralları' 3).")
    else:
        print("\n== agy'nin raporu ==")
        print(cevap)

    return 1 if sorun else 0


if __name__ == "__main__":
    sys.exit(main())
