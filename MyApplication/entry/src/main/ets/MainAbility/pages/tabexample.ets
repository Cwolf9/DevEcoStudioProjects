import router from '@ohos.router'
import socket from '@ohos.net.socket';
import {checkpre, checkmyreg, ab2str, str2ab, sleep, validateIp4, Generater} from "../common/components/utils"
import wifi from '@ohos.wifi'

let udp
let startTimes
let endcounts
@Entry
@Component
struct Tabexample {
  @State routerParams: Object = Object({"source":"准备接收文件"})
  private controller: TabsController = new TabsController()
  private fileNameDown: string[] = ["File1Down567555uyuytut.txt", "File2Down.docx", "File3Down.ppt"]
  private urgencyDown: number[] = [1, 2, 3]
  private fileSizeDown: number[] = [13, 24, 38]
  private startTimeDown: number[] = [9.1, 7.2, 8.3]
  private finishTimeDown: number[] = [133.1, 227.2, 87.3]
  private throughputDown: number[] = [0, 3.4, 0]

  @State fileNameUp: string[] = ["File1UP.txt", "File2UP.docx", "File3UP.ppt"]
  @State urgencyUp: number[] = [1, 2, 3]
  @State fileSizeUp: number[] = [13, 24, 38]
  private startTimeUp: number[] = [9.1, 7.2, 8.3]
  private finishTimeUp: number[] = [133.1, 227.2, 87.3]
  @State throughputUp: number[] = [0, 3.4, 0]
  @State input1: string = "219.228.60.89"
  @State input2: string = "0"
  private receiveTimes: number = 0

  private fileNameOth: string[] = ["File1Oth.txt", "File2Oth.docx", "File3Oth.ppt"]
  aboutToAppear() {
    udp = socket.constructUDPSocketInstance();
    console.log("filedemo Click socket aboutToAppear")
    udp.on('listening', () => {
      console.log("filedemo Click socket on listening")
    });
    // 订阅UDPSocket连接的接收消息事件
    udp.on('message', (value) => {
      this.receiveTimes += 1
      console.info("filedemo Click value == " + JSON.stringify(value))
      console.log("filedemo Click socket on message, message:" + value.message + ", remoteInfo:" + value.remoteInfo);
      console.info("filedemo Click buf == " + ab2str(value.message))
      console.info("filedemo Click remoteInfo == " + JSON.stringify(value.remoteInfo))
      switch(this.receiveTimes) {
        case 1:
          startTimes = new Date()
          this.fileNameUp[0] = ab2str(value.message)
          console.info("filedemo recv " + this.receiveTimes + ": " + this.fileNameUp[0])
          break
        case 2:
          this.urgencyUp[0] = Number(ab2str(value.message))
          console.info("filedemo recv " + this.receiveTimes + ": " + this.urgencyUp[0])
          break
        case 3:
          this.fileSizeUp[0] = Number(ab2str(value.message))
          endcounts = this.fileSizeUp[0] + 3
          this.fileSizeUp[0] = this.fileSizeUp[0] / 1000
          console.info("filedemo recv " + this.receiveTimes + ": " + this.fileSizeUp[0])
          break
        default:
          if(this.receiveTimes == endcounts) {
            let endTimes = new Date() // ms
            console.info("filedemo " + startTimes + ";" + endTimes)
            this.throughputUp[0] = this.fileSizeUp[0] / ((Number(endTimes.getTime())-Number(startTimes.getTime()))/1000)
            // @ts-ignore
            this.throughputUp[0] = this.throughputUp[0].toFixed(6)
            this.receiveTimes = 0
          }
        break
      }
    });
    /* 调用udp.on('message') 接受不到消息
     * */
    udp.on('close', () => {
      console.log("filedemo Click socket on close")
    });
  }




  build() {
    Column() {
      Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
        TabContent() {
          Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
            Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
              Text("文件名：" + this.fileNameUp[0]).fontSize(15).width("100%")
              Text("文件大小：" + this.fileSizeUp[0] + "MB").fontSize(15).width("45%")
              Text("紧急程度：" + this.urgencyUp[0]).fontSize(15).width("45%")
              if(this.throughputUp[0] == 0) {
                Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
              }else {
                Text("网络吞吐量：" + this.throughputUp[0] + "MB/s").fontSize(15).width("50%")
              }
            }
            .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
          }
        }
        TabContent() {
          List({ space: 4 }) {
            ListItem() {
              Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
                Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
                  Text("文件名：" + this.fileNameDown[0]).fontSize(15).width("100%")
                  Text("文件大小：" + this.fileSizeDown[0] + "MB").fontSize(15).width("45%")
                  Text("紧急程度：" + this.urgencyDown[0]).fontSize(15).width("45%")
                  if(this.throughputDown[0] == 0) {
                    Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                  }else {
                    Text("网络吞吐量：" + this.throughputDown[0] + "MB/s").fontSize(15).width("50%")
                  }
                }
                .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
//                .borderRadius(8)
//                .border({width:2, color:"#FFF"})
                if(this.throughputDown[0] == 0) {
                  LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                  //                  .visibility(Visibility.None)
                  //                  .borderRadius(8)
                }else {
                  Image($r('app.media.check')).width(40).height(65)
                }
              }
            }
            ListItem() {
              Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
                Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
                  Text("文件名：" + this.fileNameDown[1]).fontSize(15).width("100%")
                  Text("文件大小：" + this.fileSizeDown[1] + "MB").fontSize(15).width("45%")
                  Text("紧急程度：" + this.urgencyDown[1]).fontSize(15).width("45%")
                  if(this.throughputDown[1] == 0) {
                    Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                  }else {
                    Text("网络吞吐量：" + this.throughputDown[1] + "MB/s").fontSize(15).width("50%")
                  }
                }
                .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                //                .borderRadius(8)
                if(this.throughputDown[1] == 0) {
                  LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                  //                  .visibility(Visibility.None)
                  //                  .borderRadius(8)
                }else {
                  Image($r('app.media.check')).width(40).height(65)
                }
              }
            }
            ListItem() {
              Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
                Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
                  Text("文件名：" + this.fileNameDown[2]).fontSize(15).width("100%")
                  Text("文件大小：" + this.fileSizeDown[2] + "MB").fontSize(15).width("45%")
                  Text("紧急程度：" + this.urgencyDown[2]).fontSize(15).width("45%")
                  if(this.throughputDown[2] == 0) {
                    Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                  }else {
                    Text("网络吞吐量：" + this.throughputDown[2] + "MB/s").fontSize(15).width("50%")
                  }
                }
                .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                //                .borderRadius(8)
                if(this.throughputDown[2] == 0) {
                  LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                  //                  .visibility(Visibility.None)
                  //                  .borderRadius(8)
                }else {
                  Image($r('app.media.check')).width(40).height(65)
                }
              }
            }

          }.height(300).width("100%").backgroundColor(0xDCDCDC)
          .padding({ left:5, right:5 }).listDirection(Axis.Vertical)
        }
        TabContent() {
          List({ space: 4 }) {
            ListItem() {
              Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
                Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
                  Text("文件名：" + this.fileNameUp[0]).fontSize(15).width("100%")
                  Text("文件大小：" + this.fileSizeUp[0] + "MB").fontSize(15).width("45%")
                  Text("紧急程度：" + this.urgencyUp[0]).fontSize(15).width("45%")
                  if(this.throughputUp[0] == 0) {
                    Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                  }else {
                    Text("网络吞吐量：" + this.throughputUp[0] + "MB/s").fontSize(15).width("50%")
                  }
                }
                .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                //                .borderRadius(8)
                //                .border({width:2, color:"#FFF"})
                if(this.throughputUp[0] == 0) {
                  LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                  //                  .visibility(Visibility.None)
                  //                  .borderRadius(8)
                }else {
                  Image($r('app.media.check')).width(40).height(65)
                }
              }
            }
            ListItem() {
              Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
                Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
                  Text("文件名：" + this.fileNameUp[1]).fontSize(15).width("100%")
                  Text("文件大小：" + this.fileSizeUp[1] + "MB").fontSize(15).width("45%")
                  Text("紧急程度：" + this.urgencyUp[1]).fontSize(15).width("45%")
                  if(this.throughputUp[1] == 0) {
                    Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                  }else {
                    Text("网络吞吐量：" + this.throughputUp[1] + "MB/s").fontSize(15).width("50%")
                  }
                }
                .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                //                .borderRadius(8)
                if(this.throughputUp[1] == 0) {
                  LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                  //                  .visibility(Visibility.None)
                  //                  .borderRadius(8)
                }else {
                  Image($r('app.media.check')).width(40).height(65)
                }
              }
            }
            ListItem() {
              Flex({direction: FlexDirection.Row, wrap: FlexWrap.NoWrap}) {
                Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}){
                  Text("文件名：" + this.fileNameUp[2]).fontSize(15).width("100%")
                  Text("文件大小：" + this.fileSizeUp[2] + "MB").fontSize(15).width("45%")
                  Text("紧急程度：" + this.urgencyUp[2]).fontSize(15).width("45%")
                  if(this.throughputUp[2] == 0) {
                    Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                  }else {
                    Text("网络吞吐量：" + this.throughputUp[2] + "MB/s").fontSize(15).width("50%")
                  }
                }
                .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                //                .borderRadius(8)
                if(this.throughputUp[2] == 0) {
                  LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                  //                  .visibility(Visibility.None)
                  //                  .borderRadius(8)
                }else {
                  Image($r('app.media.check')).width(40).height(65)
                }
              }
            }

          }.height(300).width("100%").backgroundColor(0xDCDCDC)
          .padding({ left:5, right:5 }).listDirection(Axis.Vertical)
        }
      }
      .width('100%').height(400).backgroundColor(0xF5F5F5)
      .vertical(true).scrollable(true).barMode(BarMode.Fixed)
      .barWidth(0).barHeight(0).animationDuration(100)
      .onChange((index: number) => {
        console.info(index.toString())
      })
//      Button('Tab1', { type: ButtonType.Normal, stateEffect: true }).opacity(0.9)
//        .borderRadius(8).width(160).fontSize(28).backgroundColor("#FF8C00").margin(5)
//        .onClick((event: ClickEvent) => {
//          console.info('Click Point: Tab1\n');
//          this.controller.changeIndex(0)
//        })
//      Button('Tab2', { type: ButtonType.Normal, stateEffect: true }).opacity(0.9)
//        .borderRadius(8).width(160).fontSize(28).backgroundColor("#FF8C00").margin(5)
//        .onClick((event: ClickEvent) => {
//          console.info('Click Point: Tab2\n');
//          this.controller.changeIndex(1)
//        })
//      Button('Tab3', { type: ButtonType.Normal, stateEffect: true }).opacity(0.9)
//        .borderRadius(8).width(160).fontSize(28).backgroundColor("#FF8C00").margin(5)
//        .onClick((event: ClickEvent) => {
//          console.info('Click Point: Tab3\n');
//          this.controller.changeIndex(2)
//        })












      Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center, wrap: FlexWrap.Wrap}) {
        TextInput({ text: this.input1 })
          .width(200)
          .height(40)
          .margin(5)
          .fontSize(15)
          .onChange((value: string) => {
            this.input1 = value
          })
        TextInput({ text: this.input2 })
          .width(200)
          .height(40)
          .margin(5)
          .fontSize(15)
          .onChange((value: string) => {
            this.input2 = value
          })
      }.width("100%")

      Flex({direction: FlexDirection.Row, wrap: FlexWrap.Wrap}) {
        Button("wait connect").onClick(() => {
          let iport = 1
          if(/^\d+$/.test(this.input2)) {
            iport = Number(this.input2)
          }
          console.info("filedemo Click " + iport + ";" + typeof iport)

          this.routerParams = router.getParams();
          console.info('filedemo Click socket: ' + "udp");
          if(!udp) {
            console.info('filedemo Click socket: ' + "udp recreate");
            udp = socket.constructUDPSocketInstance();
          }
          let promiseRet
          //          let bindipinfo = wifi.getIpInfo()
          //          if(bindipinfo) {
          //            console.log('filedemo Click socket bind: ' + JSON.stringify(bindipinfo.ipAddress))
          //          }
          let bindip = this.input1 // 219.228.60.15" // "192.168.1.102"
          let bindport = iport // 32768 60999 37521
          console.info('filedemo Click socket bind: ' + bindip + ", " + bindport);
          promiseRet = udp.bind({address: bindip, port: bindport, family: 1});
          promiseRet.then((data) => {
            console.log('filedemo Click socket bind success: ' + JSON.stringify(data));
          }).catch(err => {
            console.log('filedemo Click socket bind fail ' + JSON.stringify(err));
            // 13 -> 不能自己指定端口号 ?
            // 那我怎么指导你bind了哪个端口
            // 99 -> 地址分配错误
          });
          console.log("filedemo Click socket end")
        }).margin(10)

        Button("send msg").onClick(() => {
          console.info('filedemo Click: ' + "recv_msg???");
          let promiseRet
          let sendip = "219.228.60.52" // "219.228.60.52" "219.228.60.115" "192.168.1.102"
          let sendport = 7002
          console.info('filedemo Click socket send: ' + sendip + ", " + sendport);
          promiseRet = udp.send({
            data:'Hello, server!',
            address: {
              address:sendip,
              port:sendport,
              family:1
            }
          });
          promiseRet.then(() => {
            console.log('filedemo Click socket send success');
          }).catch(err => {
            console.log('filedemo Click socket send fail ' + JSON.stringify(err) + ";" + err);
            // 13 EACCES Permission denied -> 为什么??? 找不到地址？
            // 88 -> 为什么???
            // 11
            // 9
            /* 调用udp.send返回错误码 88, 11, 9等
             * */
          });
        }).margin(10)

        Button("close").margin(10).onClick(() => {
          this.fileNameUp[0]="hello.txt"
          this.receiveTimes = 0
          if(udp) {
            sleep(300).then(() => {
              console.info('filedemo Click close: ' + "close");
              let promiseRet
              // 关闭UDPSocket连接
              promiseRet = udp.close();
              promiseRet.then(() => {
                console.log('filedemo Click socket close success');
                udp.off('message');
                udp.off('listening');
                udp.off('close');
                udp = undefined
              }).catch(err => {
                console.log('filedemo Click socket close fail ' + JSON.stringify(err));
              });
            })
          }
        })

        Button("getip").onClick(() => {
          console.log('lihlog_myapplication[filedemo] wifi: ' + JSON.stringify(wifi))
          let sendipinfo = wifi.getIpInfo()
          console.log('lihlog_myapplication[filedemo] sendipinfo: ' + JSON.stringify(sendipinfo))
          if(sendipinfo) {
            console.log('lihlog_myapplication[filedemo] sendipinfo.ipAddress: ' + JSON.stringify(sendipinfo.ipAddress))
          }
        })

        Button("Back").onClick(() => {
          router.replace({ url: 'pages/index' })// router.back()
          //            let sendipinfo = wifi.getIpInfo()
          //            if(sendipinfo) {
          //              console.log('lihlog_myapplication[filedemo] Click socket bind: ' + JSON.stringify(sendipinfo.ipAddress))
          //            }
        }).margin(10)
      }.width("100%")

      Text(this.routerParams['source']).fontSize(30).fontColor(Color.Blue).margin({ top: 20, bottom: 10 })
    }.width('100%').height(800).margin({ top: 5 })
  }
}
/*
 * netstat -unlp
 * netstat -unlp|grep application
 * ifconfig eth0 up
 * ifconfig eth0 down
 * dhcp_client_service start eth0
 * */
