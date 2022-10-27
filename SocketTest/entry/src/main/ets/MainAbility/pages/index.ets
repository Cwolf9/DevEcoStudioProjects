import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import router from '@ohos.router'
import featureAbility from '@ohos.ability.featureAbility'


function sleep (time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}
@Entry
@Component
struct Index {
  @State message: string = 'TCP/UDP Socket'
  @State clickCnt: number = 0
  aboutToAppear() {
    console.log("filedemo Click socket aboutToAppear")
    // 3.2系统加上这句代码就启动不了
//    globalThis.abilityContext.requestPermissionsFromUser(['ohos.permission.DISTRIBUTED_DATASYNC'])
  }
  build() {
    Flex({direction:FlexDirection.Column, justifyContent:FlexAlign.Center, alignItems:ItemAlign.Center}) {
      Flex({direction:FlexDirection.Column, justifyContent:FlexAlign.Center, alignItems:ItemAlign.Center}) {
        Text(this.message + this.clickCnt)
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
        Button("test").onClick(() => {
          console.info('filedemo onClick: ' + "test");
          this.clickCnt += 1
          let context = featureAbility.getContext();
          context.getOrCreateLocalDir().then((data) => {
            console.info("filedemo Click getOrCreateLocalDir=" + data);// /data/storage/el2/base/haps/entry
            // /data/accounts/account_0/appdata/com.example.myapplication/com.example.myapplication/com.example.myapplication.MainAbility
          })
          context.getFilesDir().then((data) => {
            console.info("filedemo Click getFilesDir=" + data);// /data/storage/el2/base/haps/entry/files
          })
          context.getOrCreateDistributedDir().then((data) => {
            console.info("filedemo Click getOrCreateDistributedDir=" + JSON.stringify(data));// /data/storage/el2/distributedfiles
          });



        }).margin(10).fontSize(20)
        Button("udp").onClick(() => {
          router.clear();
          router.replace({ url: "pages/udp", params: { source: 'udp' } })
        }).margin(10).fontSize(20)
        Button("tcp").onClick(() => {
          router.clear();
          router.replace({ url: "pages/tcp", params: { source: 'tcp' } })
        }).margin(10).fontSize(20)

      }.width("100%")
    }
  }
}