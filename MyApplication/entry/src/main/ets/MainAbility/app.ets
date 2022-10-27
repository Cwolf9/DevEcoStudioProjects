import hilog from '@ohos.hilog';

const TAG = '[TuEr Tools]';
export default {
  onCreate() {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Application onCreate');
    let tag = 'testTag';
    console.info("Application onCreate " + tag);
//    hilog.info(0x0000, 'MY_TAG', `${TAG} %{tag}s `, 'Application onCreate');
  },
  onDestroy() {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Application onDestroy');
  },
}
/*
6个基于eTS实现的Sample https://baijiahao.baidu.com/s?id=1738043904205972524
《OpenHarmony开源鸿蒙学习入门》-- 系统相机应用源码解析（一） https://blog.csdn.net/superherowupan/article/details/125677062
(项目架构图)

应用开发学习
OpenHarmony之 网络管理 Socket 模块的使用 https://blog.51cto.com/harmonyos/5347451
OpenHarmony网络应用开发 https://blog.csdn.net/qq_21484461/article/details/122782709
天给大家说一下OpenHarmony应用开发常见的几种权限 https://blog.51cto.com/jianguo/5570649
OpenHarmony——文件管理系列（2）  https://blog.51cto.com/harmonyos/5082378
OpenHarmony - WLAN 接口组件功能 https://www.51cto.com/article/716618.html

2.1 eTS物种起源 https://www.bilibili.com/read/cv16630876
编程中的概念理解-回调和eTS开发语言 https://blog.csdn.net/superherowupan/article/details/124655457
【HTML】ts/typescript/倒计时/计时器/图片切换/音乐播放/button的运用/setInterval(）函数/clearInterval(） https://blog.csdn.net/qq_62967648/article/details/123957783
使用TS实现一个可以处理事件的倒计时 http://www.icodebang.com/article/226154
TS 定时器的使用 https://blog.csdn.net/qq_40864647/article/details/125636777
TypeScript 类https://www.runoob.com/typescript/ts-class.html


OpenHarmony源码分析之分布式软总线：trans_service模块(5)/TCP会话管理 https://blog.csdn.net/weixin_46669761/article/details/125022876





*/