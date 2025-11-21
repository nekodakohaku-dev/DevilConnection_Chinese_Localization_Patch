#!/usr/bin/env bash
set -e

echo "[Install]"

# ---------- 0) checks ----------
if ! command -v npx >/dev/null 2>&1; then
    echo "[ERR] npx not found"
    exit 1
fi

if [ ! -f "app.asar" ]; then
    echo "[ERR] app.asar not found"
    exit 1
fi

# detect language pack: zh-tw.asar or zh-cn.asar
if [ -f "zh-tw.asar" ]; then
    LANG_ASAR="zh-tw.asar"
elif [ -f "zh-cn.asar" ]; then
    LANG_ASAR="zh-cn.asar"
else
    echo "[ERR] neither zh-tw.asar nor zh-cn.asar found"
    exit 1
fi

echo "[INFO] Using language pack: $LANG_ASAR"


# ---------- 1) extract app.asar ----------
mkdir -p _asar_app
npx @electron/asar extract app.asar _asar_app


# ---------- 2) extract language pack ----------
mkdir -p _asar_lang
npx @electron/asar extract "$LANG_ASAR" _asar_lang


# ---------- 3) cover (copy overwrite) ----------
cp -rf _asar_lang/* _asar_app/


# ---------- 4) backup ----------
if [ -f app.asar ]; then
    mv app.asar app.asar.bak
fi


# ---------- 5) pack ----------
npx @electron/asar pack _asar_app app.asar --unpack "*.node"


# ---------- 6) cleanup ----------
rm -rf _asar_app
rm -rf _asar_lang

echo "[Finish]"
exit 0

