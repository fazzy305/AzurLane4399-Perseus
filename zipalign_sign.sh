#!/bin/bash
# 调试：输出 Android SDK 路径
echo "ANDROID_HOME: $ANDROID_HOME"
# 调试：检查 zipalign 是否存在
ls -l $ANDROID_HOME/build-tools/32.0.0/zipalign

PATH=$PATH:$ANDROID_HOME/build-tools/32.0.0/
for f in build/*.apk; do
    mv $f ${f%.apk}.apk.unsigned
    echo "Zipaligning $f"
    zipalign -pvf 4 ${f%.apk}.apk.unsigned $f
    rm ${f%.apk}.apk.unsigned
    echo "Signing $f"
    echo $(apksigner --version)
    apksigner sign --key testkey.pk8 --cert testkey.x509.pem $f
done
