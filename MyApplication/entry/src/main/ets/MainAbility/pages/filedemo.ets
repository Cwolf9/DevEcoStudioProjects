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
import webSocket from '@ohos.net.webSocket'
import request from '@ohos.request'
import wifi from '@ohos.wifi'

import KvStoreModel from '../model/KvStoreModel'
import {MyTextMid, MyTextLog} from "../common/components/myInput"
import {checkpre, checkmyreg, ab2str, str2ab, sleep, validateIp4, Generater, readsyncSharedFile, readSharedFile, validateInt} from "../common/components/utils"

// @OHOS.distributedfile.fileio
// 应用沙箱中创建的任何文件都是随应用卸载而删除
// JAVA API 分布式文件服务概述 https://developer.harmonyos.com/cn/docs/documentation/doc-guides/database-dfs-overview-0000000000030154
// JAVA API 分布式文件服务开发指导 https://developer.harmonyos.com/cn/docs/documentation/doc-guides/database-dfs-guidelines-0000000000030159

// 1 快 2 慢
let gSendFileType = 1
let gRemoteIp = "192.168.1.106"
let gLocalIp = "192.168.1.108"
let gDistFn = "mytest/bigfile1.txt"
const generater = new Generater(0)
let udp
let gDistFileDir = "/data/storage/el2/distributedfiles/entry"
// /data/storage/el2/distributedfiles
// /data/storage/el2/distributedfiles/entry

/*
函数使用方法 https://www.cnblogs.com/lone5wolf/p/15834981.html
https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-apis-context-0000001281480530#ZH-CN_TOPIC_0000001281480530__contextgetfilesdir
文档中的写法有问题 getOrCreateDistributedDir
context.getFilesDir((err, data) => {
  if (err['code'] != 0) {
    console.error('lihlog_myapplication[filedemo] Click Operation failed. Cause: ' + JSON.stringify(err) + "; " + JSON.stringify(data));
    return;
  }
  console.info('lihlog_myapplication[filedemo] Click Operation successful. Data:' + JSON.stringify(data));
});
* fileio 接口的限制（可能）：
* 提前在应用沙箱文件夹内创建的文件，无法对其进行任何操作。只要在应用源码内动态创建的文件，才能被该接口索引到并操作。
* 也就是说一定会要先 open 这个文件，且附带创建文件的参数

*/
// 分布式文件服务：在应用沙箱内的分布式路径下像操作本地文件一样操作远端设备的文件，所有组网设备都可以查看相应的修改
function genSharedFile(isDist:number, infileName:string, inputValue:string) : string {
  let path = "/data/storage/el2/base/haps/entry/mytest/bigfile1.txt", retpath, prepath = "/data/storage/el2/base/haps/entry"
  console.info('lihlog_myapplication[filedemo] genSharedFile():')
  // Context模块提供了ability或application的上下文的能力，包括允许访问特定于应用程序的资源、请求和验证权限等
  // 应用沙箱路径(可以不真实存在，但会存在对应的真实路径), 真实路径 /data/app/el2/100/base/com.example.myapplication/haps/entry
  // 应用程序可见范围有限，只能对应用沙箱路径内的文件进行操作。而且人为在应用沙箱真实路径下创建文件好像没用
  // 所有操作必须在应用沙箱路径下
  let context = featureAbility.getContext();
  context.getOrCreateLocalDir().then((data) => {
    console.info("lihlog_myapplication[filedemo] genSharedFile0 getOrCreateLocalDir=" + data);// /data/storage/el2/base/haps/entry
    // /data/accounts/account_0/appdata/com.example.myapplication/com.example.myapplication/com.example.myapplication.MainAbility
  })
  context.getFilesDir().then((data) => {
    console.info("lihlog_myapplication[filedemo] genSharedFile0 getFilesDir=" + data);// /data/storage/el2/base/haps/entry/files
  })
  let dfiles = gDistFileDir
  context.getOrCreateDistributedDir().then((data) => {
    dfiles = data
    console.info("lihlog_myapplication[filedemo] genSharedFile0 getOrCreateDistributedDir=" + JSON.stringify(data) + " " + typeof data);
    // /data/storage/el2/distributedfiles
    // /data/storage/el2/distributedfiles/entry
  });
  if(isDist) {
    prepath = dfiles
  }
  try {
    path = prepath + "/mytest"
    let ret = fileio.mkdirSync(path)
    console.info("lihlog_myapplication[filedemo] genSharedFile mkdir ret: " + ret + ":" + JSON.stringify(ret))
  } catch (err)  {
    console.info("lihlog_myapplication[filedemo] genSharedFile mkdir err: " + err + ":" + JSON.stringify(err) + ";" + typeof err)
    // Error: File exists:{};object
    let reg = /File exists/
    // @ts-ignore
    if(!checkmyreg(reg, err)) {
      console.info("lihlog_myapplication[filedemo] genSharedFile return 1" + JSON.stringify(undefined) + ";" + JSON.stringify(null))
      return "1"
    }
  }
  path = "/data/storage/el2/base/haps/entry/a.txt"
  path = "/data/syslab/files/a.txt"

  retpath = infileName
  path = prepath + "/" + retpath
  console.info("lihlog_myapplication[filedemo] checkpre " + path);
  if(!checkpre(path)) {
    console.info("lihlog_myapplication[filedemo] genSharedFile return 4")
    return "4"
  }
  /*
  打开文件的选项，必须指定如下选项中的一个，默认以只读方式打开：
- 0o0：只读打开。- 0o1：只写打开。- 0o2：读写打开。
同时，也可给定如下选项，以按位或的方式追加，默认不给定任何额外选项：
- 0o100：若文件不存在，则创建文件。使用该选项时必须指定第三个参数 mode。- 0o200：如果追加了0o100选项，且文件已经存在，则出错。
- 0o1000：如果文件存在且以只写或读写的方式打开文件，则将其长度裁剪为零。- 0o2000：以追加方式打开，后续写将追加到文件末尾。
- 0o4000：如果path指向FIFO、块特殊文件或字符特殊文件，则本次打开及后续 IO 进行非阻塞操作。
- 0o200000：如果path不指向目录，则出错。
- 0o400000：如果path指向符号链接，则出错。
- 0o4010000：以同步IO的方式打开文件。
   * */
  //  | 0o4010000
  let fd = fileio.openSync(path, 0o1102, 0o666);
  console.info("lihlog_myapplication[filedemo] genSharedFile openSync " + fd);
  if(fd < 0) {
    console.info("lihlog_myapplication[filedemo] genSharedFile return 3")
    return "3"
  }
  let wtNum = 1
  if(/^\d+$/.test(inputValue)) {
    wtNum = Number(inputValue)
  }
  console.info("lihlog_myapplication[filedemo] genSharedFile " + wtNum + ";" + typeof wtNum)

  let wtsize = 1024 - 1
  //  let wtbuf = generater.RandomString(wtsize, true) + "\n"
  if(wtNum != 128) {
    let wtbuf = generater.RandomStringHeap(wtsize, true) + "\n"
    console.info(`lihlog_myapplication[filedemo] genSharedFile wtlen: ${wtsize}, wtNum: ${wtNum}`)
    for (let i = 0; i < wtNum; ++i) {
      fileio.writeSync(fd, wtbuf);
    }
  }else {
    wtsize = 10240 - 1
    wtNum = Math.floor(wtNum / 10)
    let wtbuf = generater.RandomStringHeap(wtsize, true) + "\n"
    console.info(`lihlog_myapplication[filedemo] genSharedFile wtlen: ${wtsize}, wtNum: ${wtNum}`)
    for (let i = 0; i < wtNum; ++i) {
      fileio.writeSync(fd, wtbuf);
    }
  }
  //  fileio.writeSync(fd, "Hello, World!\n");
  fileio.fdatasyncSync(fd);fileio.fsyncSync(fd);
  // Uint8Array 怎么变成 ArrayBuffer
  let buf = new ArrayBuffer(1024)
  let num = fileio.readSync(fd, buf, {position: 0})
  let result = new Uint8Array(buf.slice(0, num))
  //  let res = new Uint8Array(10240)
  //  res[0] = buf[0], res[1] = buf[1]
  //  console.info("lihlog_myapplication[filedemo] " + String.fromCharCode.apply(null, new Uint8Array(buf[0])) + ';' + res[0] + ';' + res[1] + ';' + String.fromCharCode.apply(null, res))
  console.info("lihlog_myapplication[filedemo] genSharedFile num = " + num)
  console.info("lihlog_myapplication[filedemo] genSharedFile ArrayBuffer = " + buf + ";" + JSON.stringify(buf) + ";" + buf.byteLength + ';' + buf[0] + ';' + buf[1])
  console.info("lihlog_myapplication[filedemo] genSharedFile result = " + result)
  console.info("lihlog_myapplication[filedemo] genSharedFile buf = " + ab2str(buf))
  let stat = fileio.fstatSync(fd)
  console.info("lihlog_myapplication[filedemo] genSharedFile fstatSync:"+ JSON.stringify(stat) + ";" + stat);
  if(stat) {
    console.info("lihlog_myapplication[filedemo] genSharedFile fstatSync dev:%d,ino:%d,mtime:%d,isFile:%d,size:%d", stat.dev, stat.ino, stat.mtime, stat.isFile(), stat.size)
  }
  fileio.closeSync(fd)
  console.info("lihlog_myapplication[filedemo] genSharedFile return: " + retpath);
  return retpath
}
  // 异步方法，最好用同步方法，但同步方法不能有任何 err
  //  fileio.open(path, 0o2102 & 0o2, 0o666).then(function(fd){
  //    console.info("lihlog_myapplication[filedemo] Click open file succeed " + fd);
  //    fileio.close(fd).then(function(){
  //      console.info("lihlog_myapplication[filedemo] Click close file succeed");
  //    }).catch(function(err){
  //      console.info("lihlog_myapplication[filedemo] Click close file failed with error:"+ err);
  //    });
  //  }).catch(function(err){
  //    console.info("lihlog_myapplication[filedemo] Click open file failed with error:"+ err);
  //    // "/data/syslab/files/a.txt" -> Error: No such file or directory
  //  });
  //  let stat = fileio.statSync(path);//调用则软件崩
  //  console.info("lihlog_myapplication[filedemo] Click getFileInfo succeed:"+ JSON.stringify(stat));
  /*
  path = "/data/storage/el2/base/haps/entry"
  fileio.opendir(path).then(function(dir){// use read/readSync/close : files cache
    console.info("lihlog_myapplication[filedemo] Click opendir succeed1:"+ dir + "; " + JSON.stringify(dir))
    if(!dir) {
      console.info("lihlog_myapplication[filedemo] Click opendir null return 2")
      return "2"
    }
    let dirent = dir.readSync()//如果是空的话，同步方法不会返回吗?
    console.log("lihlog_myapplication[filedemo] Click succeed2:"+dirent);
    if (dirent) {
      console.info("lihlog_myapplication[filedemo] Click opendir succeed2:" + dirent.isDirectory() + ";" + dirent.name + ";" + dirent.isFile());
      let path2 = "/data/storage/el2/base/haps/entry/" + dirent.name
      console.info("lihlog_myapplication[filedemo] Click opendir succeed2:" + path2)
    }
    dirent = dir.readSync()
    console.log("lihlog_myapplication[filedemo] Click succeed3:"+dirent);
    if (dirent) {
      console.info("lihlog_myapplication[filedemo] Click opendir succeed3:" + dirent.isDirectory() + ";" + dirent.name + ";" + dirent.isFile());
    }
    dirent = dir.readSync()
    console.log("lihlog_myapplication[filedemo] Click succeed4:"+dirent);
    if (dirent) {
      console.info("lihlog_myapplication[filedemo] Click opendir succeed4:" + dirent.isDirectory() + ";" + dirent.name + ";" + dirent.isFile());
    }
    dirent = dir.readSync()
    console.log("lihlog_myapplication[filedemo] Click succeed5:"+dirent);
    if (dirent) {
      console.info("lihlog_myapplication[filedemo] Click opendir succeed5:" + dirent.isDirectory() + ";" + dirent.name + ";" + dirent.isFile());
    }
    dir.read(function (err, dirent) {
      console.info("lihlog_myapplication[filedemo] Click read err6:"+ JSON.stringify(err) + ";" + err['code'])
      console.log("lihlog_myapplication[filedemo] Click succeed6:"+dirent + ";" + +JSON.stringify(dirent));
      if (dirent) {
        console.log("lihlog_myapplication[filedemo] Click read succeed6:"+ dirent.isDirectory() + ";" + dirent.name + ";" + dirent.isFile());
      }
    });
  }).catch(function(err){
    console.info("lihlog_myapplication[filedemo] Click opendir failed with error:"+ err);
    // "." -> Permission denied
    // "/data/syslab/files/a.txt" -> Error: No such file or directory
    // "/storage/media/100/local/files/files.txt" -> Error: No such file or directory
  });
  */


function genfileBack() {
  // https://www.runoob.com/js/js-promise.html
  // Promise 构造函数只有一个参数，是一个函数，这个函数在构造之后会直接被异步运行，所以我们称之为起始函数。起始函数包含两个参数 resolve 和 reject
  // resolve 和 reject 都是函数，其中调用 resolve 代表一切正常，reject 是出现异常时所调用的
  // Promise 类有 .then() .catch() 和 .finally() 三个方法，这三个方法的参数都是一个函数，.then() 可以将参数中的函数添加到当前 Promise 的正常执行序列，.catch() 则是设定 Promise 的异常处理序列，.finally() 是在 Promise 执行的最后一定会执行的序列。 .then() 传入的函数会按顺序依次执行，有任何异常都会直接跳到 catch 序列
  // resolve() 的参数即返回值，为 then 的参数，后续 then 的参数为上一个 then 的返回值。
  // 但是，如果 then 中返回的是一个 Promise 对象，那么下一个 then 将相当于对这个返回的 Promise 进行操作
  return new Promise ( (resolve, reject) => {
    try {
      resolve("lihlog_myapplication[filedemo] genfileBack success");    // 成功
    }
    catch(error) {
      reject("lihlog_myapplication[filedemo] genfileBack fail");        // 失败
    }
  });
}
class FileTask {
  constructor(public filename: string, public urgency: number, public fileSize: number, public filedir: string) {
  }
  output() {
    console.info('lihlog_myapplication[filedemo] FileTask output: ' + this.filename + ", " + this.urgency + ", " + this.fileSize + ", " + this.filedir);
  }
  set(filename: string, urgency: number, fileSize: number, filedir: string) {
    this.filename = filename, this.urgency = urgency, this.fileSize = fileSize, this.filedir = filedir
  }
  async sendto(udp:socket.UDPSocket, sendip:string, sendport:number) {
    console.info('lihlog_myapplication[filedemo] FileTask socket sendto: ' + sendip + ", " + sendport);
    // js/ts 回调地狱 https://www.cnblogs.com/wenxuehai/p/10455664.html
    let promiseRet
    let that = this
    //    1B: type, 0
    //  512B: filepath, /data/storage/el2/distributedfiles/entry/mytest/a.txt______
    //    1B: urgency, 1-5, 3
    //    10B: fileSize, 1024000___
    // 1 + 512 + 1 + 10 = 524
    // stpos:0, 1, 513, 514
    let type = 1
    if(type == 0) {
      // todo: not fix 为什么发完一个就卡住了？？？
      // udp.send() 不能加 await 吗？ 19 + 3 + 7
      let datas = [this.filedir + "/" + this.filename, that.urgency.toString(), that.fileSize.toString()], i = 0
      for (; i < datas.length; ++i) {
        // await
        udp.send({
          data: datas[i],
          address: {
            address: sendip,
            port: sendport,
            family: 1
          }
        }).then(async () => {
          console.info("lihlog_myapplication[filedemo] FileTask sendto: " + i)
        }).catch(function(err) {
          console.info("lihlog_myapplication[filedemo] FileTask socket sendto error:"+ err);
        });
        //        await new Promise((res, rej)=>{
        //          try {
        //            res(2);
        //          } catch(error) {
        //            rej(error);
        //          }
        //        }).then(async ()=>{
        //          console.info('lihlog_myapplication[filedemo] FileTask socket sendto ' + i);
        //          return udp.send({
        //            data: datas[i],
        //            address: {
        //              address: sendip,
        //              port: sendport,
        //              family: 1
        //            }
        //          })
        //        }).then(() => {
        //          console.info('lihlog_myapplication[filedemo] FileTask socket sendto ' + i + ': ' + datas[i]);
        //        }).catch(function(err) {
        //          console.info("lihlog_myapplication[filedemo] FileTask socket sendto error:"+ err);
        //        });
      }
      //      await udp.send({
      //        data: that.filename,
      //        address: {
      //          address: sendip,
      //          port: sendport,
      //          family: 1
      //        }
      //      }).then(() => {
      //        console.info('lihlog_myapplication[filedemo] FileTask socket sendto 1: ' + that.filename)
      //        return udp.send({
      //          data: that.urgency.toString(),
      //          address: {
      //            address: sendip,
      //            port: sendport,
      //            family: 1
      //          }
      //        })
      //      }).then(() => {
      //        console.info('lihlog_myapplication[filedemo] FileTask socket sendto 2: ' + that.urgency.toString())
      //        return udp.send({
      //          data: that.fileSize.toString(),
      //          address: {
      //            address: sendip,
      //            port: sendport,
      //            family: 1
      //          }
      //        })
      //      }).then(() => {
      //        console.info('lihlog_myapplication[filedemo] FileTask socket sendto 3: ' + that.fileSize.toString())
      //      }).catch(err => {
      //        console.log('lihlog_myapplication[filedemo] FileTask socket sendto fail ' + JSON.stringify(err) + ";" + err);
      //      })
    }else if(type == 1) {
      let strbuf = "0" + this.filedir + "/" + this.filename
      let uintA = await new Uint8Array(1024)
      for (let i = 0; i < strbuf.length; ++i) {
        uintA[i] = strbuf.charCodeAt(i)
      }
      strbuf = String(this.urgency) + String(this.fileSize)
      for (let i = 0; i < strbuf.length; ++i) {
        uintA[513 + i] = strbuf.charCodeAt(i)
      }
      console.info('lihlog_myapplication[filedemo] buf: ' + ab2str(uintA.buffer))
      await udp.send({
        data: uintA.buffer,
        address: {
          address: sendip,
          port: sendport,
          family: 1
        }
      }).then(() => {
        console.log('lihlog_myapplication[filedemo] FileTask socket sendto success')
      }).catch(err => {
        console.log('lihlog_myapplication[filedemo] FileTask socket sendto fail ' + JSON.stringify(err) + ";" + err);
        /* 调用send返回错误码 88, 11, 9等
         *
         13 EACCES Permission denied -> 为什么??? 找不到地址？
         88 -> 为什么??? socket 无效 没有bind https://blog.csdn.net/qq_29344757/article/details/71616748
         11
         9
         * */
      })
    }
    console.info('lihlog_myapplication[filedemo] FileTask socket sendto end')
  }
  // https://blog.51cto.com/harmonyos/5347451
  async sendfile(udp:socket.UDPSocket, sendip:string, sendport:number) {
    let errcnt = 0
    let that = this
    let path = this.filedir + "/" + this.filename
    console.info('lihlog_myapplication[filedemo] FileTask sendfile: ' + sendip + ", " + sendport + ';' + path);
    //  | 0o4010000
    await fileio.open(path, 0o0).then(async function(fd) {
      console.info("lihlog_myapplication[filedemo] FileTask open file succeed:" + fd)
      let i = 0
      // 1 快 2 慢
      let sendType = gSendFileType
      if(sendType == 1) {
        let buf
        buf = await new ArrayBuffer(1024)
        for (; i < that.fileSize; ++i) {
//          console.info("lihlog_myapplication[filedemo] send Loop 1 " + i)
          let res1
          let num = fileio.readSync(fd, buf)
          if (num != 1024) errcnt += 1
          res1 = ("00000000" + (i * 1024).toString(16)).substr(-8) + String.fromCharCode.apply(null, new Uint8Array(buf))
          // 加不加 await, 加 await 发完一个就卡住了 udp.send ????? 不加 await 就猛发但是看不到异步的发送成功log
          udp.send({
            data: res1,
            address: {
              address: sendip,
              port: sendport,
              family: 1
            }
          }).then(() => {
            console.info("lihlog_myapplication[filedemo] FileTask send " + i)
          }).catch(err => {
            console.log('lihlog_myapplication[filedemo] FileTask send fail ' + JSON.stringify(err) + ";" + err);
          })
          res1 = null
          //          buf = null
        }
      }else if(sendType == 2) {
        let buf
        buf = await new ArrayBuffer(1024)
        for(; i < that.fileSize; ++i) {
          // 加不加 await: 加 await 就是一个一个读，一个一个发送；不加 await 就卡住了也不发送
          await fileio.read(fd, buf).then(async function(readOut) {
            if(readOut.bytesRead != 1024) errcnt += 1
            // 这里加不加都一样
            return await udp.send({
              data: ("00000000"+(i * 1024).toString(16)).substr(-8) + String.fromCharCode.apply(null, new Uint8Array(readOut.buffer)),
              address: {
                address: sendip,
                port: sendport,
                family: 1
              }
            })
          }).then(() => {
            console.info("lihlog_myapplication[filedemo] send " + i)
          }).catch(function(err) {
            console.info("lihlog_myapplication[filedemo] read file data failed with error:"+ err);
          });
//          buf = null
        }
      }

      await fileio.close(fd).then(function() {
        console.info("lihlog_myapplication[filedemo] FileTask errcnt=" + errcnt)
        console.info("lihlog_myapplication[filedemo] FileTask close file succeed")
      }).catch(function(err) {
        console.info("lihlog_myapplication[filedemo] FileTask err errcnt=" + errcnt)
        console.info("lihlog_myapplication[filedemo] FileTask close file failed with error:"+ err)
      });
    }).catch(function(err){
      console.info("lihlog_myapplication[filedemo] FileTask open file error: "+ err);
    });

    console.info("lihlog_myapplication[filedemo] FileTask finale errcnt=" + errcnt)
    return 3
  }
}
function sendfile(inputValue:string) {
}
interface IArrFile{
  filename:string,
  urgency:number,
  fileSize:number
}




/*
 * todo:
 * ts 异步事件通知，ts 计时获取时间， ts 组件自动刷新
 * ts/js ohos应用开发 socket 连接 网络通信
 * */
@Entry
@Component
struct Filedemo {
  @State routerParams: Object = Object({"source":""})
  @State sendFileSize:string = "1024" // KB
  /*
   * 调用时执行
   * 模拟器: 生成文件事件 传输文件时间
   * 1024: 0s
   * 10240: xs
   * 102400: xs
   * 1024000: xs
   * 真机：生成文件事件 传输文件时间
   * 10240: xs xs
   * 102400: 3s 2min
   * 1024000: 33-35s xmin
   * 280MB 5min
   * 估计 15-20min
   *
   * 测试 2022-10-21
   * 102400: 4s 1min14s
   * 1024000: 39s xminxs
   *
   *
   *
   * https://blog.csdn.net/lchydp1979/article/details/125960611
   *
   * find . -path ./proc -prune -o -name bigfile1.txt
   *
   *
   *
   *
sed -i '$d' a.sh
touch a.sh
chmod 777 a.sh
echo #! /bin/bash >> a.sh
echo "CNT=0" >> a.sh
echo "while [ \$CNT -lt 360 ]" >> a.sh
echo "do" >> a.sh
echo "echo 3 > /proc/sys/vm/drop_caches" >> a.sh
echo "free -h" >> a.sh
echo "sleep 5" >> a.sh
echo "done" >> a.sh
cat a.sh
#! /bin/bash
CNT=0
while [ $CNT -lt 360 ]
do
echo 3 > /proc/sys/vm/drop_caches
free -h
sleep 30
done
# sh a.sh
* echo 3 > /proc/sys/vm/drop_caches && free -h
# sed -i 's/echo 3/echo 1/' a.sh
  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
 2372 20010033      0 -20 1.0G 780M  87M S  123  39.7   5:22.08 com.example.myapplication
  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
 2372 20010033      0 -20 1.0G 869M  87M S  121  44.2   6:03.10 com.example.myapplicationq

  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
 3383 20010033      0 -20 719M 346M  85M S  117  17.6   2:03.27 com.example.myapplication
  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
 3383 20010033      0 -20 794M 441M  86M S  120  22.4   2:38.38 com.example.myapplication

 *
 *
 * https://blog.csdn.net/weixin_34927903/article/details/116708841
 * https://www.cnblogs.com/yanghuinnn/p/16011931.html
 *
 * swapoff -a
 *
 * dd if=/dev/zero of=/data/swapfile bs=1M count=1280
 * mkswap /data/swapfile
 * swapon /data/swapfile
 *
 * swappiness的值越大，表示越积极使用swap分区，越小表示越积极使用物理内存。默认值swappiness=60
 * # cat /proc/sys/vm/swappiness
60
* min_free_kbytes控制系统所保留空闲内存的最低限值，相应的vm.min_free_kbytes设置的越大，触发回收内存的阈值也越高
* # cat /proc/sys/vm/min_free_kbytes
10240          51200 102400
 * echo 51200 > /proc/sys/vm/min_free_kbytes
 * echo 102400 > /proc/sys/vm/min_free_kbytes
 * echo 10240 > /proc/sys/vm/min_free_kbytes
 * echo 80 > /proc/sys/vm/swappiness
 * echo 358400 > /proc/sys/vm/min_free_kbytes
 * /etc/fstab /root/swapfile swap swap defaults 0 0
   * */
  private isDistF:number = 1
  private distFd:string = gDistFileDir// /data/storage/el2/base/haps/entry /files  /data/storage/el2/distributedfiles /entry
  @State distFn:string = gDistFn
  // @State private
  @State inputIp:string = gRemoteIp // 219.228.60.115 219.228.60.52
  @State sendPort:number = 30001
  private localIp:string = gLocalIp // 219.228.60.89 192.168.1.108 192.168.1.104 192.168.1.102 192.168.1.104
  private localPort:number = 0 // 30001
  @State logTextStr:string = "日志区：\n"
  @State wtStatus: number = 0
  @State sendStatus: number = 0
  private clickCnt: number = 0
  private filetaskArr: Array<FileTask> = []


//  private filetaskArr: Array<Array<(string | number)>> = new Array<Array<(string | number)>>()
//  private filetaskArr: Array<IArrFile>=[{filename:"",urgency:0,fileSize:0},{filename:"",urgency:0,fileSize:0}]
// {filename:filetask.filename,urgency:filetask.urgency,fileSize:filetask.fileSize}

  // class: https://blog.csdn.net/m0_45093055/article/details/125577517
  // array: https://blog.csdn.net/qq_39708228/article/details/116587033
  // array: https://cloud.tencent.com/developer/article/1612654?from=15425

  // promise 中 this 和 that 问题
  aboutToAppear() {
    console.log("lihlog_myapplication[filedemo] aboutToAppear")
    udp = socket.constructUDPSocketInstance();
    let context = featureAbility.getContext();
    let that = this
    if(this.isDistF == 0) {
      context.getOrCreateLocalDir().then(async (data) => {that.distFd = data})
    }else {
      context.getOrCreateDistributedDir().then(async (data) => {that.distFd = data})
    }
    console.log("lihlog_myapplication[filedemo] aboutToAppear distFd: " + this.distFd)
    let array:Array<string> = ['ohos.permission.DISTRIBUTED_DATASYNC'];
    featureAbility.getContext().requestPermissionsFromUser(array, 1, (err, data)=>{
      console.info("lihlog_myapplication[listdevices] ====>requestdata====>" + JSON.stringify(data));
      console.info("lihlog_myapplication[listdevices] ====>requesterrcode====>" + JSON.stringify(err.code));
      // 3.2.8.1 ====>requestdata====>{"requestCode":1,"permissions":["ohos.permission.DISTRIBUTED_DATASYNC"],"authResults":[-1]}
      // ====>requesterrcode====>0
    })
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start}) {

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {
        Button('生成文件').opacity(0.9)
          .borderRadius(8).width(120).height(50).fontSize(18)
          .onClick((event: ClickEvent) => {
            let path, filepath
            let startTimes = new Date() // ms
            this.logTextStr += startTimes.toLocaleString().split(" ")[1] + ": 正在写入文件: \n"
            this.wtStatus = 1
            console.info('lihlog_myapplication[filedemo] Button: 生成文件')
            sleep(10).then(()=>{
              //xxx
            })
            async function sleepToDox() {
              await sleep(10);
              //xxx
            }
            sleepToDox()
            let that = this
            async function sleepToDo() {
              await sleep(1)
              //调用promise 方法 https://ost.51cto.com/posts/2781
              await genfileBack()
                .then(async (res: string) => {
                  console.info(res); // then - 成功后执行
//                  filepath = await genBigFile(that.distFn, that.sendFileSize)
                  filepath = await genSharedFile(that.isDistF, that.distFn, that.sendFileSize)
                  path = that.distFd + "/" + filepath
                  console.info("lihlog_myapplication[filedemo] check path: " + path)
                  await fileio.stat(path, function (err, stat) { //err: 2 No such file or directory
                    console.info("lihlog_myapplication[filedemo] Click stat:" + JSON.stringify(stat) + ";" + stat + ";" + JSON.stringify(err));
                    if (stat) {
                      console.info("lihlog_myapplication[filedemo] Click stat dev:%d,ino:%d,mtime:%d,isFile:%d,size:%d", stat.dev, stat.ino, stat.mtime, stat.isFile(), stat.size)
                      let filetask = new FileTask(filepath, 3, Math.floor(stat.size / 1024), that.distFd)
                      let ftlen = 0
                      if (JSON.stringify(that.filetaskArr) != "[]") {
                        ftlen = JSON.stringify(that.filetaskArr).split('{').length
                      }
                      console.info(`lihlog_myapplication[filedemo] ftlen: ${ftlen}, gen filetask now`)
                      that.filetaskArr.push(filetask)
                      that.filetaskArr[ftlen].output()
                    }
                  });
                }).catch((err: string) => {
                  console.error(err)
                });
              that.wtStatus = 2
              that.sendStatus = 0
              let endTimes = new Date()
              that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 写入文件成功: " + filepath + "\n"
              console.info("lihlog_myapplication[filedemo] 写入文件完成")
            }
            sleepToDo()
          })
        Button('组网互联').opacity(0.9)
          .borderRadius(8).width(120).height(50).fontSize(18)
          .onClick((event: ClickEvent) => {
            console.info('lihlog_myapplication[filedemo] Button: 组网互联')
            // 组网互联
            let startTimes = new Date() // ms
            this.logTextStr += startTimes.toLocaleString().split(" ")[1] + ": 正在组网互联: " + this.inputIp + "...\n"
            if(validateIp4(this.inputIp)) {
              let promiseRet
              let that = this
              async function sleepToDo() {
                await sleep(3)
                console.log('lihlog_myapplication[filedemo] Click socket bind: ' + that.sendStatus)
                if(that.sendStatus != 0) that.sendStatus = 1
                if(that.sendStatus == 0) {
                  promiseRet = udp.bind({ address: that.localIp, family: 1, port: that.localPort });
                  await promiseRet.then(async () => {
                    console.log('lihlog_myapplication[filedemo] Click socket bind success')
                    that.sendStatus = 1
                  }).catch(async err => {
                    console.log('lihlog_myapplication[filedemo] Click socket bind fail ' + JSON.stringify(err))
                    // 13 -> 不能自己指定端口号 ?
                    // 99 -> 没有wifi
                  });
                }
                console.log('lihlog_myapplication[filedemo] 组网互联完毕 success: ' + that.sendStatus)
                let endTimes = new Date()
                // @ts-ignore
                if (that.sendStatus == 1) {
                  that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 组网互联成功...\n"
                } else {
                  that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 组网互联失败...\n"
                }
              }
              sleepToDo()


              // 检查默认数据网络是否被激活
              connection.hasDefaultNet().then(function (has) {// 蓝牙不算默认数据网络
                console.log("lihlog_myapplication[filedemo] Click hasDefaultNet has: " + has)
              })
              // 获取全部激活的数据网络列表 netId:100 101 102 103 都没有作用
              connection.getAllNets().then(function (nets) {
                console.log("lihlog_myapplication[filedemo] Click getAllNets nets: " + JSON.stringify(nets))
              });
              // 获取默认激活的数据网络 104 105 ... (第一次连接是104，断开重连就是105？)
              connection.getDefaultNet().then(function (netHandle) {
                console.log("lihlog_myapplication[filedemo] Click getDefaultNet netHandle: " + JSON.stringify(netHandle))
                if(netHandle['netId'] != 0) {
                  // 网络的连接信息
                  connection.getConnectionProperties(netHandle).then(function (info) {
                    console.log("lihlog_myapplication[filedemo] Click getConnectionProperties netHandle: " + JSON.stringify(info))
                  })
                  // 网络的能力信息
                  connection.getNetCapabilities(netHandle).then(function (info) {
                    console.log("lihlog_myapplication[filedemo] Click getNetCapabilities netHandle: " + JSON.stringify(info))
                  })
                  // 使用对应网络解析主机名以获取所有IP地址
//                  let host = "www.baidu.com";
//                  netHandle.getAddressesByName(host).then(function (addresses) {
//                    console.log("lihlog_myapplication[filedemo] Click netHandle getAddressesByName: " + JSON.stringify(addresses))
//                  }).catch(err => {
//                    console.log('lihlog_myapplication[filedemo] getAddressesByName fail:' + JSON.stringify(err));
//                  });
                }
//                // 报告网络状态已连接 啥意思?
//                connection.reportNetConnected(netHandle).then(function () {
//                  console.log("lihlog_myapplication[filedemo] Click reportNetConnected: " + "report success")
//                });
//                // 报告网络状态已断开 啥意思?
//                connection.reportNetDisconnected(netHandle).then(function () {
//                  console.log("lihlog_myapplication[filedemo] Click reportNetDisconnected: " + "report success")
//                });
              })
//              let host = "www.baidu.com";
//              connection.getAddressesByName(host).then(function (addresses) {
//                console.log("lihlog_myapplication[filedemo] Click connection getAddressesByName: " + JSON.stringify(addresses))
//              }).catch(err => {
//                console.log('lihlog_myapplication[filedemo] getAddressesByName fail:' + JSON.stringify(err));
//              });

              // 关注默认网络, 返回网络连接的句柄
              let netConnection = connection.createNetConnection(undefined, 1000)
              // 关注蜂窝网络
              let netConnectionCellular = connection.createNetConnection({
                netCapabilities: {
                  // @ts-ignore
                  bearerTypes: [NetBearType.BEARER_CELLULAR]
                }
              }, 1000)
              console.log("lihlog_myapplication[filedemo] Click createNetConnection: " + netConnection +";"+ JSON.stringify(netConnection) + ";" + JSON.stringify(netConnectionCellular))
            }
          })
        Button('启动传输').opacity(0.9)
          .borderRadius(8).width(120).height(50).fontSize(18).backgroundColor("#FF8C00")
          .onClick(async (event: ClickEvent) => {
            console.info('lihlog_myapplication[filedemo] Button: 启动传输开始 ' + new Date().toLocaleString());
            let startTimes = new Date() // ms
            this.logTextStr += startTimes.toLocaleString().split(" ")[1] + ": 正在启动传输...\n"
            if(this.sendStatus >= 1) {
              this.sendStatus = 2
              console.info('lihlog_myapplication[filedemo] start send udp socket: ' + udp + ", " + JSON.stringify(udp));
              if (!udp) {
                console.info('lihlog_myapplication[filedemo] socket udp: ' + "recreate");
                udp = socket.constructUDPSocketInstance();
              }
              let that = this
              let sIp = that.inputIp
              let sPort = that.sendPort
              async function sleepToDo() {
                await sleep(1)
                if (JSON.stringify(that.filetaskArr) != "[]") {
                  let ftlen = JSON.stringify(that.filetaskArr).split('{').length - 1
                  console.info('lihlog_myapplication[filedemo] filetaskArr len: ' + ftlen)
                  let filetask = that.filetaskArr[ftlen - 1]
                  await filetask.sendto(udp, that.inputIp, that.sendPort)
                  that.sendStatus = await filetask.sendfile(udp,that.inputIp, that.sendPort)
                }
                let endTimes = new Date()
                if (that.sendStatus == 3) {
                  that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 启动传输完成...\n"
                } else {
                  that.logTextStr += endTimes.toLocaleString().split(" ")[1] + ": 启动传输失败...\n"
                }
                console.info('lihlog_myapplication[filedemo] Button: 启动传输结束 ' + endTimes.toLocaleString());
              }
              sleepToDo()
            }else {
              console.info('lihlog_myapplication[filedemo] 启动传输失败 请先组网');
            }
//            let types = [];//"jpg", "png", "txt"
//            let str1 = document.choose(types);
//            console.info("Click testTag str1 " + JSON.stringify(str1));
//
//            let uri = "";
//            let str2 = document.choose(function(err, uri) {
//              console.info("Click testTag uri2 " + JSON.stringify(uri));
//            });
//            console.info("Click testTag str2 " + JSON.stringify(str2));
//
//            let str3 = document.choose(types, function (err, uri) {
//              //do something with uri
//              console.info("Click testTag uri3" + uri + " 0 " + err);
//            });
//            console.info("Click testTag str3 " + JSON.stringify(str3));
//
//            types = ["jpg", "png", "txt"];
//            str1 = document.choose(types);
//            console.info("Click testTag str1 " + JSON.stringify(str1));
          })

      }.margin({ top: 10, bottom: 10 }).height(80).width("100%")












      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("文件大小(KB):").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.sendFileSize })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.sendFileSize = value
          })
        // 条件渲染
        if (!/^\d+$/.test(this.sendFileSize)) {
          Text("非法整数！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
        Button("0").fontSize(15).onClick(() => {
          console.info('lihlog_myapplication[filedemo] Click filesize')
          if(this.sendFileSize == "1024") {
            this.sendFileSize = "10240"
          }else if(this.sendFileSize == "10240") {
            this.sendFileSize = "102400"
          }else if(this.sendFileSize == "102400") {
            this.sendFileSize = "1024000"
          }else if(this.sendFileSize == "1024000") {
            this.sendFileSize = "1024"
          }else {
            this.sendFileSize = "1024"
          }
        })
        Button("G").fontSize(15).onClick(() => {this.sendFileSize = "1048576"})
        Button("3").fontSize(15).onClick(() => {this.sendFileSize = "3"})
      }.margin(5).width("100%").height(100)
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
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("对端ip地址:").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.inputIp })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.inputIp = value
          })
          if(!validateIp4(this.inputIp)) {
            Text("非法ip！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
          }
      }.margin(5).width("100%").height(100)
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("对端port端口:").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.sendPort.toString() })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.sendPort = Number(value)
          })
        if(!validateInt(this.sendPort.toString())) {
          Text("非法port！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
      }.margin(5).width("100%").height(100)

      if(this.wtStatus == 0) {
        MyTextMid({textString:"等待写入文件并传输给对端设备"})
      }else if(this.wtStatus == 1) {
        MyTextMid({textString:"正在写入文件，确保ip地址合法"})
      }else if(this.wtStatus != 0 && !validateIp4(this.inputIp)) {
        MyTextMid({textString:"请输入合法ip地址"})
      }else if(this.wtStatus == 2 && this.sendStatus == 0) {
        MyTextMid({textString:"写入文件完成，正在等待组网互联和发送"})
      }else if(this.wtStatus == 2 && this.sendStatus == 1) {
        MyTextMid({textString:"写入文件完成，组网互联成功正在等待发送"})
      }else if(this.wtStatus == 2 && this.sendStatus == 2) {
        MyTextMid({textString:"写入文件完成，正在发送文件中"})
      }else if(this.wtStatus == 2 && this.sendStatus == 3) {
        MyTextMid({textString:"写入文件完成，成功发送文件"})
      }

      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        MyTextLog({textString:this.logTextStr})
      }.width(400).height(300).backgroundColor("#F5F5F5").margin({top:20})

















      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
          Button("socket").onClick(() => {
            //            let sendipinfo = wifi.getIpInfo()
            //            if(sendipinfo) {
            //              console.log('lihlog_myapplication[filedemo] Click socket bind: ' + JSON.stringify(sendipinfo.ipAddress))
            //            }
            let promiseRet
            console.info('lihlog_myapplication[filedemo] onClick udp socket: ' + udp);
            if(!udp) {
              console.info('lihlog_myapplication[filedemo] Click socket: ' + "udp recreate");
              udp = socket.constructUDPSocketInstance();
            }
            let ftlen
            if(JSON.stringify(this.filetaskArr) != "[]") {
              ftlen = JSON.stringify(this.filetaskArr).split('{').length - 1
              console.info('lihlog_myapplication[filedemo] filetask len: ' + ftlen)
              let filetask = this.filetaskArr[ftlen - 1]
              filetask.sendto(udp, this.inputIp, this.sendPort)
            }
          })

          Button("http").onClick(() => {
            console.info('lihlog_myapplication[filedemo] http onClick: ')
            // 每一个httpRequest对应一个http请求任务，不可复用
            let httpRequest = http.createHttp();
            // 用于订阅http响应头，此接口会比request请求先返回。可以根据业务需要订阅此消息
            // 从API 8开始，使用on('headersReceive', Callback)替代on('headerReceive', AsyncCallback)。 8+
            httpRequest.on('headersReceive', (header) => {
              console.info('lihlog_myapplication[filedemo] Click header: ' + JSON.stringify(header));
            });
            httpRequest.request(
              // 填写http请求的url地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
              "https://www.baidu.com/s?wd=发送get请求",
              {
                method: http.RequestMethod.GET, // 可选，默认为http.RequestMethod.GET
                // 开发者根据自身业务需要添加header字段
                header: {
                  'Connection': 'keep-alive',
                  // 'Content-Type': '',//get 不需要
                  "origin": "https://www.baidu.com/",
                  "referer": "https://www.baidu.com/s?ie=utf-8&tn=baidu&wd=http",
                  "user-agent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
                },
                // 当使用POST请求时此字段用于传递内容
                //                extraData: {
                //                  "data": "data to send",
                //                },
                connectTimeout: 6000, // 可选，默认为60s
                readTimeout: 6000, // 可选，默认为60s
              }, (err, data) => {
              if (!err) {
                // data.result为http响应内容，可根据业务需要进行解析
                console.info('lihlog_myapplication[filedemo] Click Result:' + data.result);// string | Object | ArrayBuffer
                console.info('lihlog_myapplication[filedemo] Click Result type:' + typeof data.result);
                if(typeof data.result == "string") {
                  // @ts-ignore
                  console.info('lihlog_myapplication[filedemo] Click Result len check:' + data.result.length);
                }
                // @ts-ignore
                console.info('lihlog_myapplication[filedemo] Click Result len:' + data.result.length);
                console.info('lihlog_myapplication[filedemo] Click code:' + data.responseCode);
                // data.header为http响应头，可根据业务需要进行解析
                console.info('lihlog_myapplication[filedemo] Click header:' + JSON.stringify(data.header));
                console.info('lihlog_myapplication[filedemo] Click cookies:' + data.cookies); // 8+
              } else {
                console.info('lihlog_myapplication[filedemo] Click error:' + JSON.stringify(err));
                // 6 无法解析主机 -> 没权限
              }
              // 当该请求使用完毕时，调用destroy方法主动销毁。
              httpRequest.destroy();
            }
            );

          })

          Button("websocket").onClick(() => {
            console.info('lihlog_myapplication[filedemo] websocket onClick: ')
            let that = this

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
            this.wtStatus = 0
            this.sendStatus = 0
          })
          Button("close conn").onClick(() => {
            if(udp) {
              sleep(2000).then(() => {
                console.info('lihlog_myapplication[filedemo] Click close: ' + "close");
                if(udp) {
                  let promiseRet
                  // 关闭UDPSocket连接
                  promiseRet = udp.close();
                  promiseRet.then(() => {
                    console.log('lihlog_myapplication[filedemo] Click socket close success');
                    udp = undefined
                  }).catch(err => {
                    console.log('lihlog_myapplication[filedemo] Click socket close fail ' + JSON.stringify(err));
                  });
                }
              })
            }
          })
          Button("Back").onClick(() => {
            router.replace({ url: 'pages/index' })// router.back()
          })
        }.height(45).width("100%").margin({bottom:15})

        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {

          Button("dist").onClick(() => {
            let path = gDistFileDir + "/" + this.distFn
            this.logTextStr += path + "\n"
            let that = this
            fileio.stat(path, function (err, stat) { //err: 2 No such file or directory
              that.logTextStr += "stat: " + JSON.stringify(stat) + "; " + stat + "; " + JSON.stringify(err) + "\n"
              console.info("lihlog_myapplication[filedemo] Button stat:" + JSON.stringify(stat) + ";" + stat + ";" + JSON.stringify(err));
              if (stat) {
                that.logTextStr += `stat: dev:${stat.dev},ino:${stat.ino},mtime:${stat.mtime},isFile:${stat.isFile()},size:${stat.size}\n`
                console.info("lihlog_myapplication[filedemo] Button stat dev:%d,ino:%d,mtime:%d,isFile:%d,size:%d", stat.dev, stat.ino, stat.mtime, stat.isFile(), stat.size)
                let filetask = new FileTask(that.distFn, 3, Math.floor(stat.size / 1024), that.distFd)
                let ftlen = 0
                if (JSON.stringify(that.filetaskArr) != "[]") {
                  ftlen = JSON.stringify(that.filetaskArr).split('{').length
                }
                console.info(`lihlog_myapplication[filedemo] ftlen: ${ftlen}, gen filetask now`)
                if(that.filetaskArr.length == 0) {
                  that.filetaskArr.push(filetask)
                  that.filetaskArr[ftlen].output()
                }else {

                }
                console.info("lihlog_myapplication[filedemo] that.filetaskArr.length: " + that.filetaskArr.length)
              }
            });
          })
          Button("readD").onClick(() => {
            let path = gDistFileDir + "/" + this.distFn
            this.logTextStr += path + "\n"
            let that = this
            readSharedFile(path, 20).then((retbuf)=>{
              that.logTextStr += "read ret:" + retbuf + "\n"
            }).catch(function(err){
              that.logTextStr += "read ret:" + err + "\n"
            });
          })
          Button("readSD").onClick(() => {
            let path = gDistFileDir + "/" + this.distFn
            this.logTextStr += path + "\n"
            let retbuf = readsyncSharedFile(path, 20)
            this.logTextStr += "read ret:" + retbuf + "\n"
          })
          Button("sH").onClick(() => {
            console.info('lihlog_myapplication[filedemo] Button: sH ' + new Date().toLocaleString());
            console.info('lihlog_myapplication[filedemo] start send udp socket: ' + udp + ", " + JSON.stringify(udp));
            if (!udp) {
              console.info('lihlog_myapplication[filedemo] socket udp: ' + "recreate");
              udp = socket.constructUDPSocketInstance();
            }
            let that = this
            let sIp = that.inputIp
            let sPort = that.sendPort
            async function sleepToDo() {
              await sleep(1)
              if (JSON.stringify(that.filetaskArr) != "[]") {
                let ftlen = JSON.stringify(that.filetaskArr).split('{').length - 1
                console.info('lihlog_myapplication[filedemo] filetaskArr len: ' + ftlen)
                let filetask = that.filetaskArr[ftlen - 1]
                await filetask.sendto(udp, that.inputIp, that.sendPort)
              }
              console.info('lihlog_myapplication[filedemo] Button: sH ' + new Date().toLocaleString());
            }
            sleepToDo()
          })
          Button("sD").onClick(() => {
            console.info('lihlog_myapplication[filedemo] Button: sD ' + new Date().toLocaleString());
            console.info('lihlog_myapplication[filedemo] start send udp socket: ' + udp + ", " + JSON.stringify(udp));
            if (!udp) {
              console.info('lihlog_myapplication[filedemo] socket udp: ' + "recreate");
              udp = socket.constructUDPSocketInstance();
            }
            let that = this
            let sIp = that.inputIp
            let sPort = that.sendPort
            async function sleepToDo() {
              await sleep(1)
              if (JSON.stringify(that.filetaskArr) != "[]") {
                let ftlen = JSON.stringify(that.filetaskArr).split('{').length - 1
                console.info('lihlog_myapplication[filedemo] filetaskArr len: ' + ftlen)
                let filetask = that.filetaskArr[ftlen - 1]
                that.sendStatus = await filetask.sendfile(udp,that.inputIp, that.sendPort)
              }
              console.info('lihlog_myapplication[filedemo] Button: sD ' + new Date().toLocaleString());
            }
            sleepToDo()
          })
          TextInput({ text: this.distFn })
            .width(160)
            .height(40)
            .fontSize(12)
            .onChange((value: string) => {
              this.distFn = value
            })
        }.margin({bottom: 0})

        Text(this.routerParams['source'] + " " + this.clickCnt)
          .fontSize(30).fontColor(Color.Blue).height(80).width("100%").textAlign(TextAlign.Center)
      }.padding({bottom: 50})

    }

  }
}
/*
 * ts 格式化日期输出 https://www.cnblogs.com/adswads/p/5473904.html
 * 用ts封装时间、日期格式化工具，格式化时间戳 https://blog.csdn.net/m0_50406470/article/details/122147483
 *
 * */