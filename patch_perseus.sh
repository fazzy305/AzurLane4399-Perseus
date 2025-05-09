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
    
    case "${bundle_id}" in
        "com.bilibili.AzurLane")
            wget https://pkg.biligame.com/games/blhx_8.2.1_0820_1_20240830_041443_51682.apk -O ${bundle_id}.apk -q
            ;;
        "com.bilibili.blhx.m4399")
            wget https://ty.ly93.cc/1197/325091193480790562/blhx.apk -O ${bundle_id}.apk -q
            ;;
        "com.bilibili.blhx.mi")
            wget https://c2.g.mi.com/package/AppStore/05e20856eb7314270b3351b3f8fcbec1cc685c319/eyJhcGt2Ijo4MjEwLCJuYW1lIjoiY29tLmJpbGliaWxpLmJsaHgubWkiLCJ2ZXJzaW9uIjoiMS4wIiwiY2lkIjoibWVuZ18xNDM5XzM1Ml9hbmRyb2lkIiwibWQ1Ijp0cnVlfQ/ae0d1d2fe57f558acbd01db2b950b68c -O ${bundle_id}.apk -q
            ;;
        *)
            echo "Unknown bundle ID: ${bundle_id}"
            ;;
    esac

    echo "${bundle_id}.apk downloaded !"   
    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    #unzip -o com.YoStarJP.AzurLane.xapk -d AzurLane
    #cp AzurLane/com.YoStarJP.AzurLane.apk .
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d ${bundle_id}.apk

echo "Copy Perseus libs"
cp -r Perseus/src/libs/. ${bundle_id}/lib/

echo "Patching Azur Lane with Perseus"
if [ "${bundle_id}" == "com.bilibili.AzurLane" ]; then
    oncreate=$(grep -n -m 1 'onCreate' ${bundle_id}/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
    sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" ${bundle_id}/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
    sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" ${bundle_id}/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
else
    oncreate=$(grep -n -m 1 'onCreate' ${bundle_id}/smali/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
    sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" ${bundle_id}/smali/com/unity3d/player/UnityPlayerActivity.smali
    sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" ${bundle_id}/smali/com/unity3d/player/UnityPlayerActivity.smali
fi

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b ${bundle_id} -o build/${bundle_id}.patched.apk
