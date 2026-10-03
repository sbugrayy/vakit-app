"""Emülatörde arayüzü metinle sürmek için küçük yardımcı (Claude'un doğrulama aracı).

Kullanım:
    python tool/adb_ui.py dump                 # görünen metin/etiketleri listeler
    python tool/adb_ui.py tap "Konum seç"      # metni ya da etiketi içeren öğeye dokunur
    python tool/adb_ui.py tap "=Allow"         # başına = konursa birebir eşleşme
    python tool/adb_ui.py has "Sıradaki vakit" # varsa 0, yoksa 1 ile çıkar

Flutter widget'ları erişilebilirlik ağacına `text` ya da `content-desc` olarak
düşer; `uiautomator dump` bu ağacı verir.
"""

import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

ADB = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk",
                   "platform-tools", "adb.exe")
SERIAL = os.environ.get("ANDROID_SERIAL", "emulator-5554")


def adb(*args):
    return subprocess.run([ADB, "-s", SERIAL, *args], capture_output=True)


def nodes():
    adb("shell", "uiautomator", "dump", "/sdcard/vakit_ui.xml")
    raw = adb("exec-out", "cat", "/sdcard/vakit_ui.xml").stdout
    root = ET.fromstring(raw.decode("utf-8"))
    for node in root.iter("node"):
        label = (node.get("text") or "") or (node.get("content-desc") or "")
        bounds = node.get("bounds") or ""
        if label.strip():
            yield label, bounds


def center(bounds):
    x1, y1, x2, y2 = map(int, re.findall(r"\d+", bounds))
    return (x1 + x2) // 2, (y1 + y2) // 2


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    cmd = sys.argv[1]
    if cmd == "dump":
        for label, bounds in nodes():
            print(f"{bounds:28} {label.replace(chr(10), ' | ')}")
        return 0
    target = sys.argv[2]
    exact = target.startswith("=")
    if exact:
        target = target[1:]
    for label, bounds in nodes():
        if (label.strip() == target) if exact else (target in label):
            if cmd == "has":
                return 0
            x, y = center(bounds)
            adb("shell", "input", "tap", str(x), str(y))
            print(f"dokunuldu: {label!r} @ {x},{y}")
            return 0
    print(f"bulunamadı: {target!r}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
