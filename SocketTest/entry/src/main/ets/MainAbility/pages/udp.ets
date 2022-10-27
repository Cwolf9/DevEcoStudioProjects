import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import router from '@ohos.router'

function sleep (time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}
function validateIp4(ip: string): boolean {
  return /^((\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))(\.|$)){4}$/.test(ip) ? true : false;
}
let udp
@Entry
@Component
struct Udp {
  @State message: string = 'UDP Socket'
  @State localIp: string = '192.168.1.107'
  @State localPort: number = 30001 // 60999
  aboutToAppear() {
    udp = socket.constructUDPSocketInstance();
    console.log("filedemo Click socket aboutToAppear")
    udp.on('listening', () => {
      console.log("filedemo Click socket on listening")
    });
    // 订阅UDPSocket连接的接收消息事件
    udp.on('message', (value) => {
      console.log("filedemo Click socket on message, message:" + value.message + ", remoteInfo:" + value.remoteInfo);
    });
    /* 调用udp.on('message') 接受不到消息
     * */
    udp.on('close', () => {
      console.log("filedemo Click socket on close")
    });
  }
  build() {
    Flex({direction:FlexDirection.Column, justifyContent:FlexAlign.Center, alignItems:ItemAlign.Center}) {
      Text(this.message)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("本地ip地址:").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.localIp })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.localIp = value
          })
        if(!validateIp4(this.localIp)) {
          Text("非法ip！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
      }.margin(5).width("100%").height(100)

      Flex({direction:FlexDirection.Row, justifyContent:FlexAlign.Center, alignItems:ItemAlign.Center}) {
        Button("test").onClick(() => {
          console.info('filedemo Click: ' + "test");
        }).margin(5)

        Button("wait connect").onClick(() => {
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
          let bindip = this.localIp
          let bindport = this.localPort
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
        }).margin(5)


        Button("recv_msg").onClick(() => {
          console.info('filedemo Click: ' + "recv_msg???");
          let promiseRet
          promiseRet = udp.send()
          promiseRet.then(() => {
            console.log('filedemo Click socket recv_msg send success');
          }).catch(err => {
            console.log('filedemo Click socket recv_msg send fail ' + JSON.stringify(err) + ";" + err);
          });
        }).margin(5)

        Button("send_msg").onClick(() => {
          let sendip = "219.228.60.52" // "219.228.60.52" "219.228.60.115" "192.168.1.102"
          let sendport = 7002
          let promiseRet
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
        }).margin(5)
        Button("close connect").onClick(() => {
          console.info('filedemo Click close: ' + "close");
          sleep(3000).then(()=>{
            let promiseRet
            udp.off('message');
            udp.off('listening');
            udp.off('close');
            // 关闭UDPSocket连接
            promiseRet = udp.close();
            promiseRet.then(() => {
              console.log('filedemo Click socket close success');
              udp = undefined
            }).catch(err => {
              console.log('filedemo Click socket close fail ' + JSON.stringify(err));
            });
          })
        }).margin(5)
        Button("Back").onClick(() => {
          router.replace({ url: 'pages/index' })
        }).margin(5)
      }
      .width('100%')
    }
  }
}