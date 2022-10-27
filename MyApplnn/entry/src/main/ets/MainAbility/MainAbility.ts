import hilog from '@ohos.hilog';
import Ability from '@ohos.application.Ability'
import Window from '@ohos.window'
let out
export default class MainAbility extends Ability {
    onCreate(want, launchParam) {
        out = this
        console.info("filedemo onCreate() " + "MainAbility");
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
        hilog.info(0x0000, 'testTag', '%{public}s', 'want param:' + JSON.stringify(want) ?? '');
        hilog.info(0x0000, 'testTag', '%{public}s', 'launchParam:' + JSON.stringify(launchParam) ?? '');
    }

    onDestroy() {
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: Window.WindowStage) {
        console.info("filedemo onWindowStageCreate() " + "MainAbility");
        // Main window is created, set main page for this ability
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/index', (err, data) => {
            if (err.code) {
                hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.ERROR);
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
        var context = this.context
        let array:Array<string> = ["ohos.permission.DISTRIBUTED_DATASYNC"];
        //requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
        context.requestPermissionsFromUser(array).then(function(data) {
            console.log("data type:" + typeof(data));
            console.log("data:" + data);
            console.log("data permissions:" + data.permissions);
            console.log("data result:" + data.authResults);
        }, (err) => {
            console.error('Failed to start ability', err.code);
        });
        console.info("filedemo context.distributedFilesDir " + context.getApplicationContext().distributedFilesDir);
    }

    onWindowStageDestroy() {
        // Main window is destroyed, release UI related resources
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground() {
        console.info("filedemo onForeground() " + "MainAbility");
        // Ability has brought to foreground
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
    }

    onBackground() {
        // Ability has back to background
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
    }
}

import fileio from '@ohos.fileio';



function sleep (time) {
    return new Promise((resolve) => setTimeout(resolve, time));
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

function validateIp4(ip: string): boolean {
    return /^((\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))(\.|$)){4}$/.test(ip) ? true : false;
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
const generater = new Generater(0)

// 分布式文件服务：在应用沙箱内的分布式路径下像操作本地文件一样操作远端设备的文件，所有组网设备都可以查看相应的修改
function genSharedFile(infileName:string, inFileSize:string) : string {
    console.info("filedemo genSharedFile ")
    // /data/storage/el2/distributedfiles
    let dfiles = "/data/storage/el2/distributedfiles"
    try {
        let context = out.context.getApplicationContext();
        console.info("filedemo context " + context.distributedFilesDir);
        dfiles = context.distributedFilesDir
    } catch (err)  {
        console.info("filedemo Click return 1 " + JSON.stringify(err) + "; " + err)
//        return "1"
    }
    let path = dfiles + "/" + infileName
    console.info("filedemo Click path " + path);

    let fd = fileio.openSync(path, 0o2102, 0o666);
    console.info("filedemo Click openSync " + fd);
    if(fd < 0) {
        console.info("filedemo Click return 3")
        return "3"
    }
    let wtNum = 1
    if(/^\d+$/.test(inFileSize)) {
        wtNum = Number(inFileSize)
    }
    console.info("filedemo genBigFile " + wtNum + ";" + typeof wtNum)
    let wtsize = 1024 - 1
    let wtbuf = generater.RandomStringHeap(wtsize, true) + "\n"
    console.info(`filedemo genBigFile wtlen: ${wtsize}, wtNum: ${wtNum}`)
    for (let i = 0; i < wtNum; ++i) {
        fileio.writeSync(fd, wtbuf);
    }
    fileio.fdatasyncSync(fd);fileio.fsyncSync(fd);
    // Uint8Array 怎么变成 ArrayBuffer
    let buf = new ArrayBuffer(1024)
    let num = fileio.readSync(fd, buf, {position: 0})
    let result = new Uint8Array(buf.slice(0, num))
    let retp = ab2str(buf)
    console.info("filedemo genBigFile buf = " + retp)
    let stat = fileio.fstatSync(fd)
    console.info("filedemo genBigFile fstatSync:"+ JSON.stringify(stat) + ";" + stat);
    if(stat) {
        console.info("filedemo genBigFile fstatSync dev:%d,ino:%d,ctime:%d,isFile:%d,size:%d", stat.dev, stat.ino, stat.ctime, stat.isFile(), stat.size)
    }
    fileio.closeSync(fd)
    return retp
}
function genfileBack(inputValue:string) {
    return new Promise ( (resolve, reject) => {
        try {
            resolve("filedemo success");    // 成功
        }
        catch(error) {
            reject("filedemo fail");        // 失败
        }
    });
}
function readSharedFile(infileName:string, inFileSize:string) : string {
    // /data/storage/el2/distributedfiles
    let dfiles = "/data/storage/el2/distributedfiles"
    try {
        let context = out.context.getApplicationContext();
        console.info("filedemo context " + context.distributedFilesDir);
        dfiles = context.distributedFilesDir
    } catch (err)  {
        console.info("filedemo Click return 1 " + JSON.stringify(err) + "; " + err)
        //        return "1"
    }
    let path = dfiles + "/" + infileName
    console.info("filedemo Click path " + path);

    let fd = fileio.openSync(path, 0o2102, 0o666);
    // Uint8Array 怎么变成 ArrayBuffer
    let buf = new ArrayBuffer(Number(inFileSize))
    let num = fileio.readSync(fd, buf, {position: 0})
    let retp = ab2str(buf)
    console.info("filedemo genBigFile buf = " + retp)
    return retp
}

class MyTest {
    constructor(public filename: string, public urgency: number, public fileSize: number) {
    }
    output() {
        console.info('filedemo FileTask: ' + this.filename + ", " + this.urgency + ", " + this.fileSize);
    }
}
export {sleep, ab2str, str2ab, validateIp4}
export {genSharedFile, genfileBack, readSharedFile}
export {MyTest}
/*
hdc_std list targets
hdc_std -t id shell power-shell setmode 602
find . -path ./proc -prune -o -name bigfile1.txt

./storage/media/100/local/data/com.example.myapplnn/bigfile1.txt
./mnt/hmdfs/100/account/device_view/local/data/com.example.myapplnn/bigfile1.txt
./mnt/hmdfs/100/account/merge_view/data/com.example.myapplnn/bigfile1.txt
./data/service/el2/100/hmdfs/account/data/com.example.myapplnn/bigfile1.txt

./storage/media/100/80e416b2925491d85a45ebaa9e255e8533d6fbc551b9802ca56e14e50ae491e3/data/com.example.myapplnn/bigfile1.txt
./mnt/hmdfs/100/account/device_view/80e416b2925491d85a45ebaa9e255e8533d6fbc551b9802ca56e14e50ae491e3/data/com.example.myapplnn/bigfile1.txt
./mnt/hmdfs/100/account/merge_view/data/com.example.myapplnn/bigfile1.txt

*/