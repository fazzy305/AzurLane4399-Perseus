#!/bin/bash
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
if [ ! -f "com.bilibili.blhx.m4399.apk" ]; then
    echo "Get Azur Lane apk"

    # eg: wget "your download link" -O "your packge name.apk" -q
    #if you want to patch .xapk, change the suffix here to wget "your download link" -O "your packge name.xapk" -q
    wget https://116-142-255-140.pd1.cjjd19.com:30443/download-cdn.cjjd19.com/123-363/86155fd7/1817312562-0/86155fd71d2e1a357bc736202788396b/c-m12?v=5&t=1725607988&s=1725607988b76ceed1869c4f7809f1ab122075e2ad&r=KZSSYS&bzc=1&bzs=1817037063&filename=com.bilibili.blhx.m4399.apk&x-mf-biz-cid=859ea07f-4999-49fb-8d70-9a9d20ca79e4-c4937c&auto_redirect=0&cache_type=1&xmfcid=c4c1b7c4-4890-42c2-9d14-cc9b8de44217 -O com.bilibili.blhx.m4399.apk -q
    echo "apk downloaded !"
    
    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    #unzip -o com.YoStarJP.AzurLane.xapk -d AzurLane
    #cp AzurLane/com.YoStarJP.AzurLane.apk .
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.bilibili.blhx.m4399.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.bilibili.blhx.m4399/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.bilibili.blhx.m4399/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.bilibili.blhx.m4399/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.bilibili.blhx.m4399/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.bilibili.blhx.m4399 -o build/com.bilibili.blhx.m4399.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.bilibili.blhx.m4399 -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
