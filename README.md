# Miosip
用 [flutter](https://github.com/flutter/flutter) 框架开发的本地音乐播放器，目前只构建了Android端， 前往下载最新 [release](https://github.com/FarryNorios/Miosip/releases/latest)

## 特性
特别简陋，有很多bug，懒得改，支持 .mp3, .flac, .wav 文件（后面会加的），开始一定要给媒体权限，在设置中添加本地音源。

## 将会更新的内容
读取音频文件详细信息，包括 title, artist 等；排序方式添加；工具箱对音频文件 tags 进行修改；爬取网络中匹配的封面图片，歌曲信息以及歌词等

## 关于Flutter
写UI很方便，效率比写原生安卓高太多，就是嵌套比较烦人，后期维护麻烦。这个 App 中更主要的是 [just_audio](https://pub.dev/packages/just_audio) 和 [audio_service](https://pub.dev/packages/audio_service) 的运用来实现音乐播放，
当然也涉及很多其他方面的内容，如文件系统及个性化等。

## 这个项目以学习交流为主
有空会更新，尽量多写一些注释，有时间还可以写一些对 Flutter 的理解，再写个教程什么的，方便学习交流。当然考虑到知识产权问题，这个 App 不会提供免费的音源。还有这个框架锁60帧一直找不到好方法解决，有点不爽。
