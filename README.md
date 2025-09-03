# ~~Perseus 构建~~
# JMBQ构建

此仓库模板可让您通过 GitHub Actions 构建 ~~Perseus~~ JMBQ。这将帮助那些不想在本地机器上设置构建环境的用户。

## 重要说明
- **任何情况下**都不得将 APK 文件上传至此仓库，以避免 DMCA 版权投诉。
- 本仓库设计用于两种场景：国服版本以及当 APKPure 没有最新版本时的其他地区版本。
- 需要具备代码编辑能力
- 我不常使用 GitHub，因此不会提供任何技术支持。
- 本项目使用JMBQ替换了经常卡顿的Perseus

## 设置指南
1. 使用此仓库作为模板创建新的**私有**仓库（[创建指南](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)）
2. 进入新建仓库的 Settings > Actions > General > Workflow permissions > 设置为 Read and Write 权限
3. 自行查找下载链接并替换 `patch_perseus.sh` 第29行的链接（如需其他地区版本，还需修改包名，使用 Ctrl+H 替换即可）

## 构建步骤
1. 进入 Actions -> All workflows -> Perseus Build->Run workflow
2. 选择Select Region下方你想要的版本
3. 点击绿色的Run workflow按钮
4. 等待构建完成

## 如何更改最新下载链接
1. 获取安装包的**直链下载链接**
2. 修改patch_perseus.sh中下列内容中的对应版本链接

```
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
```

