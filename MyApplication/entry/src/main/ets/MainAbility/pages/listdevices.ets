// @ts-nocheck
import router from '@ohos.router'
import featureAbility from '@ohos.ability.featureAbility'
import {checkpre, checkmyreg, ab2str, str2ab, sleep, validateIp4, Generater} from "../common/components/utils"
import KvStoreModel from '../model/KvStoreModel'
import RemoteDeviceModel from '../model/RemoteDeviceModel'
// import fileio from '@OHOS.distributedfile.fileio';
// ERROR: Failed :entry:LegacyCompileETS...
// Module not found: Error: Can't resolve '@OHOS.distributedfile.fileio' in

/*
 * todo: not fix
 * ohos3.2-Beta3 系统中运行 FA模型 API8 版应用程序时，在DevEco Studio的HiLog窗口无法显示console.info()输出的log日志，hdc_std shell进去也无法查看到console.info()输出的log日志。
 * HiLog无法显示的异常情况：系统是ohos3.2-Beta3，应用是FA模型 API8
 * 1.编写分布式数据类对象
 * 我们需要创建RemoteDeviceModel类来完成远程设备管理的初始化， RemoteDeviceModel.ts 代码如下：
 * 1.开发板不能常亮 https://blog.51cto.com/harmonyos/5321683
    解决办法1：
    hdc_std.exe工具,
    显示开发板: hdc_std list targets
    让开发板常亮：hdc_std -t id shell power-shell setmode 602
    优点：操作简单，适合入门开发者
    缺点：重启之后，需要重新使用这个命令
    解决办法2：
    修改openharmony的源代码
    services\nativeprofile\power_mode_config.xml value值改成-1,并烧录
    优点：一劳永逸，重启之后，不需要重复设置
    缺点：对新手不友好
 *
 * */

const MY_BUNDLE_NAME: string = "com.example.myapplication"
var DEVICE_LIST_LOCALHOST = { name: '本机', id: 'localhost' };
const CHANGE_POSITION = 'change_position';
let gDialogSelectedIndex = 0
@CustomDialog
struct CustomDialogExample {
  controller: CustomDialogController
  cancel: () => void
  startDisc: (that, dObject) => void
  confirm: (deviceId, deviceName) => void
  startAbility: (deviceId, deviceName, positionList) => void
  deviceList:() => void
  positionList:() => void
  selectedIndex: number = 0
  status: number = 0
  mainThis: object
  // todo: fix 并不能记录上一次所选择的下标
  aboutToAppear() {
    console.log('lihlog_myapplication[listdevices] Dialog aboutToAppear this.selectedIndex: ' + this.selectedIndex)
    this.selectedIndex = gDialogSelectedIndex
    this.status = 1
  }
  onPageShow() {
    console.log('lihlog_myapplication[listdevices] Dialog onPageShow this.selectedIndex: ' + this.selectedIndex)
    this.status = 1
  }
  build() {
    Column() {
      Text('选择设备')
        .fontSize(20)
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
      List() {
        ForEach(this.deviceList, (item, index) => {
          ListItem() {
            Row() {
              Text(item.name)
                .fontSize(20)
                .width('90%')
                .fontColor(Color.Black)
              if (this.deviceList.indexOf(item) == this.selectedIndex) {
                Image($r('app.media.checked'))
                  .width('8%')
                  .objectFit(ImageFit.Contain)
              } else {
                Image($r('app.media.uncheck'))
                  .width('8%')
                  .objectFit(ImageFit.Contain)
              }
            }
            .height(55)
            .onClick(() =>{
              this.selectedIndex = index
              console.log('lihlog_myapplication[listdevices] this.selectedIndex: ' + this.selectedIndex + ", index: " + index)
              this.status = 1
//              this.controller.close();
              this.startAbility(index, item.id, item.name, this.positionList)
            })
          }
        }, item => item.id)
      }.margin(5).border({borderRadius:0})

      Button() {
        Text('发现')
          .fontColor('#0D9FFB')
          .width("80%")
          .height(60)
          .textAlign(TextAlign.Center)
          .fontSize(20)
      }
      .height(80)
      .margin(5)
      .backgroundColor(Color.White)
      .border({radius:10, color:Color.Black, width:1})
      .type(ButtonType.Capsule)
      .onClick(() => {
        this.startDisc(this.mainThis, this)
      })
      Button() {
        Text('取消')
          .fontColor('#0D9FFB')
          .width("80%")
          .height(60)
          .textAlign(TextAlign.Center)
          .fontSize(20)
      }
      .height(80)
      .margin(5)
      .backgroundColor(Color.White)
      .border({radius:10, color:Color.Black, width:1})
      .type(ButtonType.Capsule)
      .onClick(() => {
        console.log('lihlog_myapplication[listdevices] this.selectedIndex: ' + this.selectedIndex)
        this.status = 0
        this.controller.close()
      })
    }
    .backgroundColor(Color.White)
    .border({ color: Color.White, radius: 20 })
    .padding(10)
  }
}

@Entry
@Component
struct Listdevices {
  @State message: string = 'wait lnn connect ...'
  @State routerParams: Object = Object({"source":"准备检查设备"})
  private lnnTimes: number = 0
  private controller: TabsController = new TabsController()
  private dialogSelectedIndex: number = 0
  private dialogObject:object = undefined
  // 设备列表
  @State deviceList: any[] = []
  // 远程设备类对象
  private remoteDeviceModel: RemoteDeviceModel = new RemoteDeviceModel()
  // BUNDLE_NAME
  private BUNDLE_NAME: string = "com.example.myapplication" // "com.huawei.cookbook"
  // 分布式数据库类对象
  private kvStoreModel: KvStoreModel = new KvStoreModel()
  aboutToAppear() {
    console.log("lihlog_myapplication[listdevices] aboutToAppear")
    // 3.2系统加上这句代码就启动不了 https://docs.openharmony.cn/pages/v3.2Beta/zh-cn/application-dev/ability/context-userguide.md/
    // globalThis.abilityContext.requestPermissionsFromUser(['ohos.permission.DISTRIBUTED_DATASYNC'])
    let array:Array<string> = ['ohos.permission.DISTRIBUTED_DATASYNC'];
    featureAbility.getContext().requestPermissionsFromUser(array, 1, (err, data)=>{
      console.info("lihlog_myapplication[listdevices] ====>requestdata====>" + JSON.stringify(data));
      console.info("lihlog_myapplication[listdevices] ====>requesterrcode====>" + JSON.stringify(err.code));
      // 3.2.8.1 ====>requestdata====>{"requestCode":1,"permissions":["ohos.permission.DISTRIBUTED_DATASYNC"],"authResults":[-1]}
      // ====>requesterrcode====>0
    })
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample({ cancel: this.onCancel, confirm: this.onAccept, deviceList: this.deviceList,positionList: this.positionList,startAbility: this.startAbilityContinuation, selectedIndex:this.dialogSelectedIndex, startDisc:this.startDisc, mainThis:this }),
    cancel: this.existApp,
    autoCancel: true,
    deviceList: this.deviceList,
    positionList: []
  })
  onCancel() {
    console.log('lihlog_myapplication[listdevices] Callback when the first button is clicked')
  }
  onAccept() {
    console.log('lihlog_myapplication[listdevices] Click when confirm')
  }
  existApp() {
    console.log('lihlog_myapplication[listdevices] Click the callback in the blank area')
    // 会因为嵌套死循环导致无法输出
    // I 03900/Ace: SourceCode E 03900/Ace: SourceCode I 02d10/Faultlogger: SourceCode
//    console.info('lihlog_myapplication[listdevices] this: ' + JSON.stringify(this))
    if(this.dialogObject) {
      console.info('lihlog_myapplication[listdevices] dialog status: ' + this.dialogObject.status)
      this.dialogObject.status = 0
    }
    this.dialogController.close()
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start}) {
      Text(this.message)
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {
        Image($r('app.media.ic_hop')).width(100).height(100).margin({right:10})
          .onClick(() =>{
            this.onContinueAbilityClick()
          })
        Button("lnn")
          .fontSize(25)
          .onClick(()=>{
            console.info("lihlog_myapplication[listdevices] click " + "lnn")
            if(this.dialogObject) {
              console.info('lihlog_myapplication[listdevices] dialog status: ' + this.dialogObject.status)
            }
            this.lnnTimes += 1
            this.routerParams['source'] = "准备检查设备: " + this.lnnTimes
          })

        Button("clear")
          .fontSize(25)
          .onClick(()=>{
            console.info("lihlog_myapplication[listdevices] click " + "clear")
            this.routerParams['source'] = "准备检查设备"
            this.lnnTimes = 0
            this.message = 'wait lnn connect ...'
          })
        Button("Back")
          .onClick(() => {
            router.replace({ url: 'pages/index' })// router.back()
          })

      }.width('100%')

      Text(this.routerParams['source']).fontSize(30).fontColor(Color.Blue).margin({ top: 20, bottom: 10 })
    }
  }

  startAbilityContinuation(indexId: number, deviceId: string, deviceName: string,positionList: any[] ) {
    console.log('lihlog_myapplication[listdevices] Click when startAbility: ' + indexId + ', ' + deviceId + ', ' + deviceName + ', ' + positionList)
    this.dialogSelectedIndex = indexId
    gDialogSelectedIndex = indexId
    if(indexId == 0) {
      return;
    }

    let self = this.mainThis;
    console.log('lihlog_myapplication[listdevices] authDevice begin' )
    if (self.remoteDeviceModel.discoverList.length > 0) {
      self.remoteDeviceModel.authDevice(deviceId, () => {
        console.log('lihlog_myapplication[listdevices] authDevice success: ')
        self.message = 'lnn connect success ...'
        if(self.dialogObject) {
          console.info('lihlog_myapplication[listdevices] dialog status: ' + self.dialogObject.status)
          self.dialogObject.status = 0
        }
        self.dialogController.close()
        console.log('lihlog_myapplication[listdevices] authDevice end')
      })
    }else{
      self.message = 'lnn connect success ...'
      if(self.dialogObject) {
        console.info('lihlog_myapplication[listdevices] dialog status: ' + self.dialogObject.status)
        self.dialogObject.status = 0
      }
      self.dialogController.close()
      console.log('lihlog_myapplication[listdevices] authDevice already done')
    }
  }
  onContinueAbilityClick() {
    console.log('lihlog_myapplication[listdevices] onContinueAbilityClick');
//    this.dialogController.open()
    this.startDisc(this, undefined)
    sleep(2).then(()=>{
    })
  }
  startDisc(that, dObject) {
    console.log('lihlog_myapplication[listdevices] startDisc');
    // 会因为嵌套死循环导致无法输出
//    console.log('lihlog_myapplication[listdevices] this: ' + JSON.stringify(this) + ", " + typeof this);

    if(dObject && !that.dialogObject) {
      that.dialogObject = dObject
      console.log('lihlog_myapplication[listdevices] get dialogObject');
    }
    let self = that;
    that.remoteDeviceModel.registerDeviceListCallback(() => {
      console.log('lihlog_myapplication[listdevices] registerDeviceListCallback, callback entered');
      var list = [];
      list[0] = DEVICE_LIST_LOCALHOST
      var deviceList = self.remoteDeviceModel.deviceList;
      console.log('lihlog_myapplication[listdevices] on remote device updated, count=' + deviceList.length);
      for (var i = 0; i < deviceList.length; i++) {
        console.log('lihlog_myapplication[listdevices] filedemo device ' + i + '/' + deviceList.length + ' deviceId='
        + deviceList[i].deviceId + ' deviceName=' + deviceList[i].deviceName + ' deviceType='
        + deviceList[i].deviceType);
        list[i + 1] = {
          name: deviceList[i].deviceName,
          id: deviceList[i].deviceId,
        };
      }
      self.deviceList = list;
      console.info('lihlog_myapplication[listdevices] local device list=' + JSON.stringify(self.deviceList) + "\n\n");

      //      self.dialogController.close() // 3.2.8, 3.1 close会崩溃？
      //      self.dialogController = new CustomDialogController({
      //        builder: CustomDialogExample({ cancel: self.onCancel, confirm: self.onAccept, deviceList: self.deviceList,positionList: self.positionList,startAbility: self.startAbilityContinuation }),
      //        cancel: self.existApp,
      //        autoCancel: true,
      //        deviceList: self.deviceList,
      //        positionList: []
      //      })
      self.dialogController.open()
      // 为啥执行完后 self.remoteDeviceModel.deviceList 的数据被清空了，因为 getTrustedDeviceListSync 为空后的赋值
      // getTrustedDeviceListSync 只会返回信任的设备列表，也就是组网连接过的设备
      console.log('lihlog_myapplication[listdevices] registerDeviceListCallback, callback exiting');
    });

  }
}
/*
 * 烧录ohos3.2-Beta3分支的镜像后，HiLog看不到 console.info 的输出，DevEco软件和hdc_std shell中均看不到，3.1版本正常。
 * netstat -unlp
 * netstat -unlp|grep application
 * ifconfig eth0 up
 * ifconfig eth0 down
 * dhcp_client_service start eth0
 * */
