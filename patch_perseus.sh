@@ -1,98 +1,98 @@
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

    # Download JMBQ
if [ ! -d "azurlane" ]; then
    echo "download JMBQ"
    git clone https://github.com/fazzy305//azurlane
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
cp -r azurlane/.  ${bundle_id}/lib/

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

# 提取 onCreate 方法
oncreate=$(grep -n -m 1 'onCreate' "$smali_path" | sed 's/[0-9]*\:\(.*\)/\1/')
if [ -z "$oncreate" ]; then
    echo "Error: Could not find onCreate method in $smali_path"
    exit 1
fi
# 应用补丁
sed -i "N; s#\($oncreate\n    .locals 2\)#\1\n    const-string v0, \"JMBQ\"\n\n    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n#" "$smali_path"

echo "Build Patched Azur Lane apk"
java -jar apktool.jar build --force "${bundle_id}" --output "build/${bundle_id}.patched.apk"

if [ $? -eq 0 ]; then
    echo "Done! Patched APK is at build/${bundle_id}.patched.apk"
else
    echo "Error: Building patched APK failed"
    exit 1
fi
