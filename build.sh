#!/usr/bin/env bash
# Rebuild Holiday Brilliant 1.3 for modern Android, fully offline.
# Usage: ./build.sh <original HolidayBrilliant 1.3 .apk> [keystore.jks alias storepass keypass]
# Needs: Java 11+, Python 3, curl, unzip.
set -euo pipefail
cd "$(dirname "$0")"
ORIG="${1:?usage: ./build.sh original.apk [keystore alias storepass keypass]}"
KS="${2:-holidaybrilliant.jks}"; ALIAS="${3:-hb}"; SP="${4:-changeit}"; KP="${5:-$SP}"

mkdir -p tools build
[ -f tools/apktool.jar ] || curl -fsSL -o tools/apktool.jar https://github.com/iBotPeaches/Apktool/releases/download/v2.10.0/apktool_2.10.0.jar
[ -f tools/uber-apk-signer.jar ] || curl -fsSL -o tools/uber-apk-signer.jar https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar

rm -rf build/src build/out build/unsigned.apk
java -jar tools/apktool.jar d -f "$ORIG" -o build/src
python3 patch.py build/src
java -jar tools/apktool.jar b build/src -o build/unsigned.apk

if [ ! -f "$KS" ]; then
  echo "No keystore found; creating $KS (keep it safe: updates must be signed with the same key)"
  keytool -genkeypair -keystore "$KS" -storepass "$SP" -keypass "$KP" -alias "$ALIAS" \
    -keyalg RSA -keysize 2048 -validity 20000 -dname "CN=HolidayBrilliant Offline"
fi
java -jar tools/uber-apk-signer.jar -a build/unsigned.apk --ks "$KS" --ksAlias "$ALIAS" \
  --ksPass "$SP" --ksKeyPass "$KP" -o build/out
cp build/out/unsigned-aligned-signed.apk HolidayBrilliant_1.3-offline.apk
echo "Done: HolidayBrilliant_1.3-offline.apk"
