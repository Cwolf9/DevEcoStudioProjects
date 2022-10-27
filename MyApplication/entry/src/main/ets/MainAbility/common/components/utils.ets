// @ts-nocheck
import fileio from '@ohos.fileio'


let utilsNum = 0
function checkpre(path) {
  let reg = /^\/data\/storage\/el2\/base\/haps\/entry[a-zA-Z0-9]*/
  let regd = /^\/data\/storage\/el2\/distributedfiles[a-zA-Z0-9]*/
  let regd2 = /^\/data\/storage\/el2\/distributedfiles\/entry[a-zA-Z0-9]*/
  return reg.test(path) || regd.test(path) || regd2.test(path)
}
function checkmyreg(reg:RegExp, path:string) {
  return reg.test(path)
}
function ab2str(buf) {
  return String.fromCharCode.apply(null, new Uint8Array(buf));
}
function str2ab(str) {
  let buf = new ArrayBuffer(str.length); // todo: 2 bytes for each char ? Unicode 16 bits ! https://blog.csdn.net/weixin_42232156/article/details/121808096
  let bufView = new Uint8Array(buf);
  for (let i=0, strLen=str.length; i < strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }
  return buf
}
function sleep (time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}
function validateIp4(ip: string): boolean {
  return /^((\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))(\.|$)){4}$/.test(ip) ? true : false;
}
function validateInt(x: string): boolean {
  return /^\d+$/.test(x) ? true : false;
}

class Generater {
  private count = 0
  constructor(counterStartNumber: number) {
    this.count = counterStartNumber
  }
  // 生成自增整数
  AutoIncreaseInteger() {
    return this.count++
  }
  // 生成随机整数 具有范围约束[min, max)
  // min 最小值
  // max 最大值
  RangeInteger(min: number, max: number) {
    const range = max - min
    const value = Math.floor(Math.random() * range) + min
    return value
  }
  // 生成随机一个指定参数中的字符串
  // ...strings 指定的字符串组
  SpecifiedString(...strings: string[]) {
    const map = new Map(Object.entries(strings))
    return map.get(this.RangeInteger(0, strings.length) + "")
  }
  // 生成指定长度的随机 含[a~z]的字符串
  // length 指定字符串长度
  // toUpper 首字母是否大写
  // 注意：这是栈式内存分配
  RandomString(length: number, firstToUpper?: boolean) {
    let str = ""
    for (let i = 0; i < length; ++i) {
      if (firstToUpper && i == 0) {
        str += String.fromCharCode(this.RangeInteger(97, 123)).toUpperCase() // 首字母大写
      }else {
        str += String.fromCharCode(this.RangeInteger(97, 123))
      }
    }
    return str
  }
  RandomStringHeap(length: number, firstToUpper?: boolean) {
    let bufView = new Uint8Array(length);
    for (let i=0, strLen=length; i < strLen; i++) {
      if (firstToUpper && i == 0) {
        bufView[i] = this.RangeInteger(65, 90 + 1);
      }else {
        bufView[i] = this.RangeInteger(97, 122 + 1);
      }
    }
    return String.fromCharCode.apply(null, bufView);
    return String.fromCharCode.apply(null, new Uint8Array(bufView));
  }
}

function readsyncSharedFile(infilePath:string, inFileSize:number) : string {
  console.info("lihlog_myapplication[utils] readsyncSharedFile filepath " + infilePath);
  let fd = fileio.openSync(infilePath, 0o0);
  console.info("lihlog_myapplication[utils] openSync fd: " + fd)
  if(fd < 0) {
    return "lihlog_myapplication[utils] openSync err: " + fd
  }
  // Uint8Array 怎么变成 ArrayBuffer
  let buf = new ArrayBuffer(inFileSize)
  let num = fileio.readSync(fd, buf, {position: 0})
  let retp = ab2str(buf)
  console.info("lihlog_myapplication[utils] readsyncSharedFile buf = " + retp)
  fileio.closeSync(fd)
  return retp
}


async function readSharedFile(infilePath:string, inFileSize:number) : Promise<string> {
  console.info("lihlog_myapplication[utils] readSharedFile filepath " + infilePath);
  return new Promise ( async (resolve, reject) => {
    try {
      await fileio.open(infilePath, 0o0).then(async function(fd) {
        console.info("lihlog_myapplication[utils] open fd: " + fd)
        // Uint8Array 怎么变成 ArrayBuffer
        let buf = new ArrayBuffer(inFileSize)
        await fileio.read(fd, buf, {position: 0}).then(async function(readOut){
          let retp = await ab2str(readOut.buffer)
          console.info("lihlog_myapplication[utils] read: " + retp + "," + JSON.stringify(readOut))
          await resolve(retp)
        }).catch(async function(err){
          resolve("lihlog_myapplication[utils] read err: " + JSON.stringify(err))
        });
        await fileio.close(fd).then(async function(){
          console.info("lihlog_myapplication[utils] close file succeed");
        }).catch(async function(err){
          console.info("lihlog_myapplication[utils] close file failed with error:"+ err);
        });
        console.info("lihlog_myapplication[utils] readSharedFile test await")
      }).catch(async function(err){
        resolve("lihlog_myapplication[utils] open err: " + JSON.stringify(err))
        // code:13 PermissionError
      });
    }
    catch(error) {
      reject("lihlog_myapplication[filedemo] readSharedFile err:" + JSON.stringify(error))
    }
  })
}


export {checkpre, checkmyreg, ab2str, str2ab, sleep, validateIp4, validateInt, Generater, readsyncSharedFile, readSharedFile}
