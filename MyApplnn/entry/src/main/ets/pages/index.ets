import fileio from '@ohos.fileio';
import AbilityContext from '@ohos.application.Ability'
import {sleep, validateIp4} from "../MainAbility/MainAbility"
import {genSharedFile, genfileBack, readSharedFile} from "../MainAbility/MainAbility"
import {MyTest} from "../MainAbility/MainAbility"

// com.example.myapplnn


@Entry
@Component
struct Index {
  @State message: string = 'Hello World'
  @State inputPageSize:string = "1024"
  @State inputIp:string = "219.228.60.115" // 192.168.1.102 219.228.60.52
  @State distFn:string = "bigfile1.txt" // mytest/bigfile1.txt
  @State logTextStr:string = "日志区：\n"
  aboutToAppear() {
    console.info("filedemo Application aboutToAppear " + "aboutToAppear");
    // 3.2系统加上这句代码就启动不了
//    globalThis.abilityContext.requestPermissionsFromUser(['ohos.permission.DISTRIBUTED_DATASYNC'])
  }
  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start}) {
      Text(this.message)
        .fontSize(50)
        .fontWeight(FontWeight.Bold)

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text("文件大小(KB):").fontSize(15).width(120).margin({left:5})
        TextInput({ text: this.inputPageSize })
          .width(180)
          .height(40)
          .margin({left:5, right:5})
          .fontSize(15)
          .onChange((value: string) => {
            this.inputPageSize = value
          })
        // 条件渲染
        if (!/^\d+$/.test(this.inputPageSize)) {
          Text("非法整数！").width(80).fontSize(10).fontColor("#999999").margin({right:5})
        }
        Button("0").fontSize(15).onClick(() => {
          console.info('filedemo Click filesize')
          if(this.inputPageSize == "1024") {
            this.inputPageSize = "10240"
          }else if(this.inputPageSize == "10240") {
            this.inputPageSize = "102400"
          }else if(this.inputPageSize == "102400") {
            this.inputPageSize = "1024000"
          }else if(this.inputPageSize == "1024000") {
            this.inputPageSize = "1024"
          }else {
            this.inputPageSize = "1024"
          }
        })
        Button("G").fontSize(15).onClick(() => {
          this.inputPageSize = "1048576"
        })
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
      TextInput({ text: this.distFn })
        .width(160)
        .height(40)
        .fontSize(12)
        .onChange((value: string) => {
          this.distFn = value
        })

      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
        Text(this.logTextStr)
          .width(400).height(250).fontSize(15)
          .padding(5).backgroundColor("#CCAAFF")
          .baselineOffset(400)
          .textAlign(TextAlign.Start)
          .textOverflow({overflow: TextOverflow.None})
      }.width(400).height(250).backgroundColor("#F5F5F5").margin({top:20})

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {
        Button("lnn")
          .fontSize(25).margin(10)
          .onClick(()=>{
            console.info("filedemo click " + "lnn")

          })

        Button("genFile")
          .fontSize(25).margin(10)
          .onClick(()=>{
            console.info("filedemo click " + "ck");
            let that = this
            let filehead
            async function sleepToDo() {
              await sleep(1)
              //调用promise 方法 https://ost.51cto.com/posts/2781
              await genfileBack(that.inputPageSize)
                .then(async (res: string) => {
                  console.info(res); // then - 成功后执行
                  filehead = await genSharedFile(that.distFn, that.inputPageSize)
                  console.info("filedemo filehead read: " + filehead)
                  that.logTextStr += filehead.substring(0, 20) + "\n"
                }).catch((err: string) => {
                  console.error(err); // catch - 失败后执行
                });
              console.info("filedemo 写入文件完成")
            }
            sleepToDo()

          })
        Button("clear")
          .fontSize(25).margin(10)
          .onClick(()=>{
            let str = "123哈哈哈"
            this.logTextStr = "日志区：\n"
            let filetask = new MyTest("123", 1, 1)
            filetask.output()

            filetask = null
          })
        Button("distributed").onClick(() => {
          let path = "/data/storage/el2/distributedfiles" + "/" + this.distFn
          this.logTextStr += path + "\n"
          this.logTextStr += readSharedFile(this.distFn, "20") + "\n"
          let that = this
          fileio.stat(path, function (err, stat) { //err: 2 No such file or directory
            that.logTextStr += "stat: " + JSON.stringify(stat) + "; " + stat + "; " + JSON.stringify(err) + "\n"
            console.info("filedemo Button stat:" + JSON.stringify(stat) + ";" + stat + ";" + JSON.stringify(err));
            if (stat) {
              that.logTextStr += `stat: dev:${stat.dev},ino:${stat.ino},mtime:${stat.mtime},isFile:${stat.isFile()},size:${stat.size}` + "\n"
//              console.info("filedemo Button stat dev:%d,ino:%d,mtime:%d,isFile:%d,size:%d", stat.dev, stat.ino, stat.mtime, stat.isFile(), stat.size)
              console.info("filedemo Button stat: dev,ino,mtime,isFile,size", stat.dev, stat.ino, stat.mtime, stat.isFile(), stat.size)
              console.info("filedemo Button filesize:" + stat.size + "B, " + stat.size/1024 + "KB, " + stat.size/1024/1024 + "MB, " + stat.size/51 + "GB")
            }
          });
        })

      }
      .width('100%')
    }
    .height('100%')
  }
}