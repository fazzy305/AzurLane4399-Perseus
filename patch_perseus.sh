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
            if wget "https://pan.gfwl.top/f/PeXs2/blhx_bilibili.apk" -O "${bundle_id}.apk" -q; then
                download_success=true
            fi
            ;;
        "com.bilibili.blhx.m4399")
            if wget "https://pan.gfwl.top/f/y64hj/blhx.apk" -O "${bundle_id}.apk" -q; then
                download_success=true
            fi
            ;;
        "com.bilibili.blhx.mi")
            if wget "https://s2.g.mi.com/ed47af393a8d535d8c59de660c54c389/1747460096/package/AppStore/024db3d6bc5c74227838ab997e88123d30ebec9d1/eyJhcGt2Ijo5NTEwLCJuYW1lIjoiY29tLmJpbGliaWxpLmJsaHgubWkiLCJ2ZXJzaW9uIjoiMS4wIiwiY2lkIjoibWVuZ18xNDM5XzM0NV9hbmRyb2lkIiwibWQ1IjpmYWxzZX0/9a79b483552727b4f2bf0000c6084fc6" -O "${bundle_id}.apk" -q; then
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
java -jar apktool.jar -q -f d ${bundle_id}.apk

echo "Copy JMBQ libs"
cp -r azurlane/.  ${bundle_id}/lib/

echo "Patching Azur Lane with JMBQ"
if [ "${bundle_id}" == "com.bilibili.AzurLane" ]; then
    oncreate=$(grep -n -m 1 'onCreate' ${bundle_id}/smali_classes3/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
    sed -ir "N; s#\($oncreate\n    .locals 2\)#\1\n    const-string v0, \"JMBQ\"\n\n    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n#" ${bundle_id}/smali_classes3/com/unity3d/player/UnityPlayerActivity.smali
   else
    oncreate=$(grep -n -m 1 'onCreate' ${bundle_id}/smali/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
    sed -ir "N; s#\($oncreate\n    .locals 2\)#\1\n    const-string v0, \"JMBQ\"\n\n    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n#" ${bundle_id}/smali/com/unity3d/player/UnityPlayerActivity.smali
fi

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b ${bundle_id} -o build/${bundle_id}.patched.apk
