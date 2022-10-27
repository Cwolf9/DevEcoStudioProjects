import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import router from '@ohos.router'

function sleep (time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}
let tcp
@Entry
@Component
struct Tcp {
  @State message: string = 'TCP Socket'
  @State inputIp:string = "219.228.60.52"
  @State inputPort:string = "7002"
  aboutToAppear() {

  }
  build() {
    Flex({direction:FlexDirection.Column, justifyContent:FlexAlign.Center, alignItems:ItemAlign.Center}) {
      Text(this.message)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)

      Flex({direction:FlexDirection.Row, justifyContent:FlexAlign.Center, alignItems:ItemAlign.Center}) {
        Button("test").onClick(() => {
          console.info('filedemo Click: ' + "test");
        }).margin(10)
        TextInput({ text: this.inputIp })
          .width(200)
          .height(40)
          .margin(5)
          .fontSize(15)
          .onChange((value: string) => {
            this.inputIp = value
          })
        TextInput({ text: this.inputPort })
          .width(200)
          .height(40)
          .margin(5)
          .fontSize(15)
          .onChange((value: string) => {
            this.inputPort = value
          })
        Button("connect").onClick(() => {
          console.info('filedemo Click: ' + "connect");
        }).margin(10)
        Button("send").onClick(() => {
          console.info('filedemo Click: ' + "send");
        }).margin(10)


        Button("bind").onClick(() => {
          console.info('filedemo Click: ' + "bind");
        }).margin(10)

        Button("accept").onClick(() => {
          console.info('filedemo Click: ' + "accept");
        }).margin(10)

        Button("recv_msg").onClick(() => {
          console.info('filedemo Click: ' + "recv_msg???");
        }).margin(10)
        Button("Close").onClick(() => {
          console.info('filedemo Click: ' + "Close");
        }).margin(10)
        Button("Back").onClick(() => {
          router.replace({ url: 'pages/index' })
        }).margin({left: 5})
      }.width("100%")
    }
  }
}