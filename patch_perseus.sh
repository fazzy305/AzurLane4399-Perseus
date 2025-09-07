#!/bin/bash

# Check if bundle id is provided
if [ -z "$1" ]
then
    echo "No bundle id provided. Usage: ./patch_perseus.sh bundle.id.com.xy"
    exit 1
fi

# Set bundle id
bundle_id=$1

# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane
if [ ! -f "${bundle_id}.apk" ]; then
    echo "Get Azur Lane apk"

    download_success=false

    case "${bundle_id}" in
        "com.bilibili.AzurLane")
            if wget "https://pan.gfwl.top/f/n8qeCn/blhx_bilibili.apk" -O "${bundle_id}.apk" -q; then
                download_success=true
            fi
            ;;
        "com.bilibili.blhx.m4399")
            if wget "https://pan.gfwl.top/f/AaX5Fr/blhx.apk" -O "${bundle_id}.apk" -q; then
                download_success=true
            fi
            ;;
        "com.bilibili.blhx.mi")
        #可能是一次性链接
            if wget "https://s2.g.mi.com/7c6c36ff446ff728abe82363b6f2dfee/1757515776/package/AppStore/0778a75f7e0e64c5cb140f92866c2794ec0f2a02a/eyJhcGt2Ijo5NjExLCJuYW1lIjoiY29tLmJpbGliaWxpLmJsaHgubWkiLCJ2ZXJzaW9uIjoiMS4wIiwiY2lkIjoibWVuZ18xNDM5XzM0NV9hbmRyb2lkIiwibWQ1IjpmYWxzZX0/ce915ecd41db4e3016302cda639993a0" -O "${bundle_id}.apk" -q; then
                download_success=true
            fi
            ;;
        *)
            echo "Unknown bundle ID: ${bundle_id}"
            exit 1
            ;;
    esac

    if [ "$download_success" = true ]; then
        echo "${bundle_id}.apk downloaded !"
    else
        echo "Failed to download ${bundle_id}.apk"
        exit 1
    fi
    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    #unzip -o com.YoStarJP.AzurLane.xapk -d AzurLane
    #cp AzurLane/com.YoStarJP.AzurLane.apk .
fi

# 提取 APK 签名
echo "Extracting signature from APK..."
Signature_string=$(python3 extract_signature.py "${bundle_id}.apk")
if [ $? -ne 0 ] || [ -z "$Signature_string" ]; then
    echo "Error: Failed to extract signature from APK"
fi

#echo "Extracted signature: $Signature_string"
#exit 1

    # Download JMBQ
if [ ! -d "azurlane_JMBQ_Menu_2.8" ]; then
    echo "download JMBQ"
    git clone https://github.com/fazzy305/azurlane_JMBQ_Menu_2.8
fi

# 替换 PmsHook.smali 文件中的签名
PMS_HOOK_FILE="azurlane_JMBQ_Menu_2.8/smali_classes4/com/android/support/PmsHook.smali"

if [ -f "$PMS_HOOK_FILE" ]; then
    echo "Replacing signature in PmsHook.smali..."
    
    # 备份原始文件
    cp "$PMS_HOOK_FILE" "$PMS_HOOK_FILE.bak"
    
    # 替换签名
    if sed -i "s/\"3082[^\"]*\"/\"$Signature_string\"/g" "$PMS_HOOK_FILE"; then
        echo "Signature replaced successfully in PmsHook.smali"
    else
        echo "Error: Failed to replace signature in PmsHook.smali"
        # 恢复备份
        cp "$PMS_HOOK_FILE.bak" "$PMS_HOOK_FILE"
    fi
else
    echo "Error: PmsHook.smali not found at $PMS_HOOK_FILE"
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar decode --force --output "${bundle_id}" "${bundle_id}.apk"

# 检查反编译是否成功
if [ $? -ne 0 ]; then
    echo "Error: Decompilation failed"
    exit 1
fi

# 展示反编译后的目录结构
#echo "Decompiled directory structure:"
#echo "=================================="
#tree "${bundle_id}" -L 2 2>/dev/null || find "${bundle_id}" -maxdepth 2 -type d | sort
#echo "=================================="

echo "Copy JMBQ libs"
cp -r azurlane_JMBQ_Menu_2.8/lib/.  ${bundle_id}/lib/

#  复制 JMBQ smali 文件
echo "Copy JMBQ smali ..."
SRC_DIR="azurlane_JMBQ_Menu_2.8/smali_classes4"

# 检查原始源目录是否存在
#if [ ! -d "$SRC_DIR" ]; then
	#echo "Error:  $SRC_DIR not found！"
	#exit 1
#fi

# 查找目标目录中最大的 smali_classes 目录编号，smali_classes4需改为smali_classes（n+1）
MAX_CLASS_NUM=3
if [ -d "${bundle_id}/" ]; then
	# 使用 find 查找所有 smali_classesX 目录，并提取最大的编号,如果没有找到，将编号重置为 3
	MAX_CLASS_NUM=$(find "${bundle_id}/" -maxdepth 1 -type d -name "smali_classes*" | sed 's/.*smali_classes//' | sort -n | tail -1)
	[ -z "$MAX_CLASS_NUM" ] && MAX_CLASS_NUM=3
fi

# 计算新的 smali_classes 目录编号
NEW_CLASS_NUM=$((MAX_CLASS_NUM + 1))
NEW_SRC_PATH="azurlane_JMBQ_Menu_2.8/smali_classes${NEW_CLASS_NUM}"

# 只有当新的目录路径与旧的目录路径不同时，才执行重命名
if [ "$SRC_DIR" != "$NEW_SRC_PATH" ]; then
	echo "正在将 $SRC_DIR 重命名为 $NEW_SRC_PATH"
	mv "$SRC_DIR" "$NEW_SRC_PATH"
	if [ $? -ne 0 ]; then
		echo "Error: Failed to move smali file ！"
		exit 1
	fi
else
	echo "Don't need to rename"
fi

# 复制新的目录到目标位置
cp -r "$NEW_SRC_PATH" "${bundle_id}/"
if [ $? -ne 0 ]; then
	echo "Error: Failed to copy smali${NEW_CLASS_NUM}！"
	exit 1
fi
echo "Move JMBQ smali to ${bundle_id}/smali_classes${NEW_CLASS_NUM}/ Success!"

#展示移动后结构
#echo "Moved directory structure:"
#echo "=================================="
#tree "${bundle_id}" -L 2 2>/dev/null || find "${bundle_id}" -maxdepth 2 -type d | sort
#echo "=================================="
#exit 1

echo "Patching Azur Lane with JMBQ"
# 尝试搜索整个目录
echo "Searching for UnityPlayerActivity.smali in all directories..."
smali_path=$(find "${bundle_id}" -name "UnityPlayerActivity.smali" | head -n 1)
if [ -z "$smali_path" ]; then
    echo "Error: Could not find UnityPlayerActivity.smali"
    echo "Available smali files:"
    find "${bundle_id}" -name "*.smali" | head -10
    echo "Available directories:"
    find "${bundle_id}" -type d | grep -E "(smali|unity)" | head -10
    exit 1
else
    echo "Found UnityPlayerActivity.smali at: $smali_path"
fi

# 提取 <init>
init=$(grep -n "\.method public constructor <init>()V" "$smali_path" | cut -d: -f1)
if [ -z "$init" ]; then
    echo "Error: Could not find onCreate method in $smali_path"
    exit 1
fi

# 修改smail
sed -i -e "/\.method public constructor <init>()V/,/\.end method/{" \
	-e "/\.locals 0/a\    invoke-static {}, Lcom/android/support/Main;->Start()V" \
	-e "}" "$smali_path"
 
#  修改 AndroidManifest.xml
sed -i 's#</application>#    <service android:name="com.android.support.Launcher" android:enabled="true" android:exported="false" android:stopWithTask="true"/>\n    </application>\n    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>#' "${bundle_id}/AndroidManifest.xml"
if [ $? -ne 0 ]; then
	    echo "Error：Failed to modify AndroidManifest.xml."
	    exit 1
	else
	    echo "Modify AndroidManifest.xml Success."
fi

 
echo "Build Patched Azur Lane apk"
java -jar apktool.jar build --force "${bundle_id}" --output "build/${bundle_id}.patched.apk"

if [ $? -eq 0 ]; then
    echo "Done! Patched APK is at build/${bundle_id}.patched.apk"
else
    echo "Error: Building patched APK failed"
    exit 1
fi
