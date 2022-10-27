import hilog from '@ohos.hilog'
import router from '@ohos.router'
import document from '@ohos.document'
import statfs from '@ohos.statfs'
import fileio from '@ohos.fileio'
import featureAbility from '@ohos.ability.featureAbility'
import connection from '@ohos.net.connection'
import NetBearType from '@ohos.net.connection'
import http from '@ohos.net.http'
import socket from '@ohos.net.socket'

import KvStoreModel from '../model/KvStoreModel'
import {MyTextMid, MyTextLog} from "../common/components/myInput"
import {checkpre, checkmyreg, ab2str, str2ab, sleep, validateIp4, validateInt, Generater, readsyncSharedFile, readSharedFile} from "../common/components/utils"






let gRemoteIp = "192.168.1.106"
let gLocalIp = "192.168.1.108"
const generater = new Generater(0)
let udp
let gDistFileDir = "/data/storage/el2/distributedfiles/entry"

class FileTask {
  constructor(public filename: string, public urgency: number, public fileSize: number, public filedir: string) {
  }

  output() {
    console.info('lihlog_myapplication[filedemo] FileTask output: ' + this.filename + ", " + this.urgency + ", " + this.fileSize + ", " + this.filedir);
  }

  set(filename: string, urgency: number, fileSize: number, filedir: string) {
    this.filename = filename, this.urgency = urgency, this.fileSize = fileSize, this.filedir = filedir
  }
}

/*
 * todo:
 * ts 异步事件通知，ts 计时获取时间， ts 组件自动刷新
 * ts/js ohos应用开发 socket 连接 网络通信
 * */
@Entry
@Component
struct Recvfile {
  @State routerParams: Object = Object({"source":'接收文件状态: '})
  private clickCnt: number = 0
  private isDistF:number = 1
  private distFd:string = gDistFileDir// /data/storage/el2/base/haps/entry /files  /data/storage/el2/distributedfiles /entry
  @State distFn:string = "mytest/bigfile1.txt"
  private localIp:string = gLocalIp // 219.228.60.89 192.168.1.108 192.168.1.104 192.168.1.102
  private localPort:string = "30001" // 30001 49991
  private remoteIp:string = gRemoteIp
  private remotePort:string = "30001"
  @State logTextStr:string = "日志区：\n"
  @State recvStatus: number = 0
  private recvGranularity:string = "1024" // Byte
  private reqCnt: number = 0
  private headLen: number = 3
  private dataLen: number = 0 // KB fileSize
  private headCnt: number = 0
  private dataCnt: number = 0
  private filename: string = ""
  private urgency: number = 0
  private filedir: string = ""
  private filetaskArr: Array<FileTask> = []
  private kvStoreModel: KvStoreModel = new KvStoreModel()
  // promise 中 this 和 that 问题
  aboutToAppear() {
    let that = this
    udp = socket.constructUDPSocketInstance();
    console.log("lihlog_myapplication[filedemo] aboutToAppear")
    udp.on('listening', () => {
      console.log("lihlog_myapplication[filedemo] socket on listening")
    });
    // 订阅UDPSocket连接的接收消息事件
    udp.on('message', (value) => {
      console.log("lihlog_myapplication[filedemo] socket on message, message:" + value.message + ", remoteInfo:" + value.remoteInfo);
      that.reqCnt += 1
      if(that.reqCnt <= that.headLen) {
        that.headCnt += value.message.byteLength
        let buf:string = ab2str(value.message)
        console.log("lihlog_myapplication[filedemo] recv head: " + buf)
        if(that.reqCnt == 1) {
          let pos = buf.lastIndexOf('/mytest')
          that.filename = buf.substr(pos + 1)
          that.filedir = buf.substr(0, pos)
        }else if(that.reqCnt == 2) {
          that.urgency = Number(buf)
        }else if(that.reqCnt == that.headLen) {
          that.dataLen = Number(buf)
          that.logTextStr += "recv begin: " + that.filename + " " + that.urgency + " " + that.dataLen + " " + that.filedir
        }
      }else if(that.reqCnt <= that.headLen + that.dataLen) {
        that.dataCnt += value.message.byteLength
        let buf = ab2str(value.message.slice(0, 10))
        console.log("lihlog_myapplication[filedemo] recv data: " + buf)
        if(that.reqCnt == that.headLen + that.dataLen) {
          console.log('lihlog_myapplication[filedemo] req over! dataCnt:%d, headCnt:%d, dataLen:%d, reqCnt:%d', that.dataCnt, that.headCnt, that.dataLen, that.reqCnt)
          that.logTextStr += "recv end: " + that.dataCnt + " " + that.headCnt + " " + that.reqCnt
        }
      }

    });
    /* 调用udp.on('message') 接受不到消息
     * */
    udp.on('close', () => {
      console.log("lihlog_myapplication[filedemo] socket on close")
    });
    that.kvStoreModel.setDataChangeListener(async (data) => {
      console.log('lihlog_myapplication[filedemo] setDataChangeListener come in')
      that.filetaskArr = [];
      await data.updateEntries.forEach(async (num) => {
        const list = JSON.parse(num.value.value);
        console.log('lihlog_myapplication[filedemo] setDataChangeListener list=' + JSON.stringify(list))
        if(list.length === 0) {
          console.log('lihlog_myapplication[filedemo] setDataChangeListener list.length === 0')
        } else{
          await list.forEach(async (num) => {
            that.filetaskArr.push(num);
          })
          console.log('lihlog_myapplication[filedemo] setDataChangeListener filetaskArr=' + JSON.stringify(that.filetaskArr))
        }
      })
      await that.filetaskArr.forEach(async (idx) => {
        console.log('lihlog_myapplication[filedemo] Listener over filetask=' + JSON.stringify(idx))
      })
      that.logTextStr +=  "filetaskArr updated: " + that.filetaskArr.length + "\n"
    })

    let context = featureAbility.getContext();
    if(this.isDistF == 0) {
      context.getOrCreateLocalDir().then(async (data) => {that.distFd = data})
    }else {
      context.getOrCreateDistributedDir().then(async (data) => {that.distFd = data})
    }
    console.log("lihlog_myapplication[filedemo] aboutToAppear distFd: " + this.distFd)
//    let bindipinfo = wifi.getIpInfo()
//    if(bindipinfo) {
//      console.log('filedemo Click socket bind: ' + JSON.stringify(bindipinfo.ipAddress))
//    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start}) {
      Text(this.routerParams['source'] + " " + this.recvStatus + ", clk: " + this.clickCnt)
        .fontSize(30).fontColor(Color.Blue).height(80).width("100%").textAlign(TextAlign.Center)

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {

        Button('启动监听').opacity(0.9)
          .borderRadius(8).width(120).height(50).fontSize(18)
          .onClick((event: ClickEvent) => {
            console.info('lihlog_myapplication[filedemo] Button: 启动监听: ' + validateIp4(this.localIp) + " " + validateInt(this.localPort))
            if(validateIp4(this.localIp) && validateInt(this.localPort)) {
              let startTimes = new Date() // ms
              this.logTextStr += startTimes.toLocaleString().split(" ")[1] + ": 正在启动监听: " + this.localIp + " " + this.localPort + "...\n"
              let promiseRet
              let that = this
              async function sleepToDo() {
                await sleep(3)
                console.log('lihlog_myapplication[filedemo] socket bind, recvStatus: ' + that.recvStatus)
                if (that.recvStatus != 0) that.recvStatus = 1
                if (that.recvStatus == 0) {
                  if(!udp) {
                    console.info('lihlog_myapplication[filedemo] udp socket: ' + "recreate");
                    udp = socket.constructUDPSocketInstance();
                  }
                  promiseRet = udp.bind({ address: that.localIp, family: 1, port: Number(that.localPort) });
                  await promiseRet.then(async () => {
                    console.log('lihlog_myapplication[filedemo] socket bind success')
                    that.recvStatus = 1
                  }).catch(async err => {
                    console.log('lihlog_myapplication[filedemo] socket bind fail ' + JSON.stringify(err))
                    // 13 -> 不能自己指定端口号 ?
                    // 99 -> 没有wifi 地址分配错误
                  });
                }
                console.log('lihlog_myapplication[filedemo] 启动监听完毕 success: ' + that.recvStatus)
                let endTimes = new Date()
                // @ts-ignore
                if (that.recvStatus == 1) {
                  that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 启动监听成功...\n"
                } else {
                  that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 启动监听失败...\n"
                }
              }
              sleepToDo()
            }
          })
        Button('记录传输结果').opacity(0.9)
          .borderRadius(8).width(120).height(50).fontSize(18).backgroundColor("#FF8C00")
          .onClick((event: ClickEvent) => {
            console.info('lihlog_myapplication[filedemo] Button 记录传输结果: ' + new Date().toLocaleString());
            this.recvStatus = 0
            let filetask = new FileTask(this.filename, this.urgency, this.dataLen, this.filedir)
            this.filetaskArr.push(filetask)
            this.filetaskArr[this.filetaskArr.length - 1].output()
            this.kvStoreModel.put('add_filetask', JSON.stringify(this.filetaskArr));
          })
      }.margin({ top: 10, bottom: 10 }).height(80).width("100%")

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("本地监听ip地址:").fontSize(15).width(120).margin({left:5})
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

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("本地监听port端口号:").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.localPort })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.localPort = value
          })
        if(!validateInt(this.localPort)) {
          Text("非法port！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
      }.margin(5).width("100%").height(100)

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("对端ip地址:").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.remoteIp })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.remoteIp = value
          })
        if(!validateIp4(this.remoteIp)) {
          Text("非法ip！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
      }.margin(5).width("100%").height(100)
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("对端port端口:").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.remotePort })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.remotePort = value
          })
        if(!validateInt(this.remotePort)) {
          Text("非法port！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
      }.margin(5).width("100%").height(100)

      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        MyTextLog({textString:this.logTextStr})
      }.width(400).height(250).backgroundColor("#F5F5F5").margin({top:20})











      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
          Button("try recv").onClick(() => {
            console.info('lihlog_myapplication[filedemo]: ' + "try send to recv msg?" + this.remoteIp + " " + this.remotePort);
            let promiseRet
            promiseRet = udp.send({
              data:"0",
              address: {
                address:this.remoteIp,
                port:Number(this.remotePort),
                family:1
              }
            })
            promiseRet.then(() => {
              console.log('lihlog_myapplication[filedemo] socket recv_msg send success');
            }).catch(err => {
              console.log('lihlog_myapplication[filedemo] socket recv_msg send fail ' + JSON.stringify(err) + ";" + err);
              // -1 Operation notpermitted https://blog.csdn.net/IrisZang/article/details/125223292
              // 13 EACCES Permission denied -> 为什么??? 找不到地址？
              // 88 -> 为什么???
              // 11
              // 9
              /* 调用udp.send返回错误码 88, 11, 9等
               * */
            });
          })
          Button('clear') {
            Row() {
              Image($r('app.media.check')).width(20).height(20).margin({ left: 12 })
              Text('to0').fontSize(15).fontColor(0xffffff).margin({ left: 5, right: 12 })
            }.alignItems(VerticalAlign.Center)
          }
          .borderRadius(8).backgroundColor(0x317aff).height(40)
          .onClick(() => {
            this.routerParams = router.getParams();
            console.info('lihlog_myapplication[filedemo] clear onClick: ')
            this.clickCnt += 1
            this.logTextStr = "日志区：\n"
            this.recvStatus = 0
          })
          Button("Back").onClick(() => {
            router.replace({ url: 'pages/index' })// router.back()
          })
        }.height(45).width("100%").margin({bottom:15})

        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
          Button("close conn").onClick(() => {
            if(udp) {
              sleep(2000).then(() => {
                console.info('lihlog_myapplication[filedemo] Button close: ' + "close");
                if(udp) {
                  let promiseRet
                  udp.off('message');
                  udp.off('listening');
                  udp.off('close');
                  // 关闭UDPSocket连接
                  promiseRet = udp.close();
                  promiseRet.then(() => {
                    console.log('lihlog_myapplication[filedemo] socket close success');
                    udp = undefined
                  }).catch(err => {
                    console.log('lihlog_myapplication[filedemo] socket close fail ' + JSON.stringify(err));
                  });
                }
              })
            }
          })
        }.margin({bottom: 30})

      }.padding({bottom: 50})

    }

  }

}