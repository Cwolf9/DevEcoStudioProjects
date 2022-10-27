import MyInputSmall from "../common/components/myInput"
import router from '@ohos.router'
import document from '@ohos.document'
import hilog from '@ohos.hilog'
import fileio from '@ohos.fileio';
import featureAbility from '@ohos.ability.featureAbility';

class file_task {
  filename: string; // a.txt
  filesize: number; // 36.1 MB
  urgency: number; // 1
  startTime: number; // 1.2
  finishTime: number; // 23.4
  throughput: number; // 16.3
}

@Entry
@Component
struct Index {
  @State message: string = "跨设备文件传输"
  private whoami: number = 1 // 0: recv, 1: send
  @State urgency: number = 1 // 1-5, 数字越大紧急程度越高, 默认 3 ?
  @State cross_priority: number = 1
  @State user_test: string = "cwolf922233"
  private tasknumDown: number = 3
  private tasknumUp: number = 3

  private my_reg = /^[A-Za-z0-9]{5,10}$/
  private urgency_reg = /^[1-5]{1,1}$/
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

  private controller: TabsController = new TabsController()
  private fileNameDown: string[] = ["File1Down56.txt", "File2Down.docx", "File3Down.ppt"]
  private urgencyDown: number[] = [1, 2, 3]
  private fileSizeDown: number[] = [13, 24, 38]
  private startTimeDown: number[] = [9.1, 7.2, 8.3]
  private finishTimeDown: number[] = [133.1, 227.2, 87.3]
  @State private throughputDown: number[] = [0, 3.4, 0]

  private fileNameUp: string[] = ["File1UP.txt", "File2UP.docx", "File3UP.ppt"]
  private urgencyUp: number[] = [1, 2, 3]
  private fileSizeUp: number[] = [13, 24, 38]
  private startTimeUp: number[] = [9.1, 7.2, 8.3]
  private finishTimeUp: number[] = [133.1, 227.2, 87.3]
  @State private throughputUp: number[] = [0, 3.4, 0]

  onPageShow() {
    let reg_ret = this.my_reg.test(this.user_test)
    reg_ret = this.urgency_reg.test(this.urgency.toString())
    // @ts-ignore
    console.info(reg_ret + this.urgency.toString())
  }

  build() {
    Flex({direction: FlexDirection.Column}) {
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) { //
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
          Text(this.message)
            .height(60)
            .width("100%")
            .fontSize(30)
            .fontColor("white")
            .backgroundColor("#8A2BE2")
            .padding(8)
            .textAlign(TextAlign.Center)
        }.height(60).width("100%").backgroundColor("#FF00FF")

        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {
          Button('下载列表', { type: ButtonType.Normal, stateEffect: true }).opacity(0.9)
            .borderRadius(8).width(120).fontSize(22)
            .onClick((event: ClickEvent) => {
              console.info('Click Point: 下载列表\n');
              this.controller.changeIndex(0)
              this.throughputDown[0] = 0
              //              this.tasknumDown += 1
              console.info("Click " + this.throughputDown[0] + " " + this.tasknumDown);
            })
          Button('上传列表', { type: ButtonType.Normal, stateEffect: true }).opacity(0.9)
            .borderRadius(8).width(120).fontSize(22)
            .onClick((event: ClickEvent) => {
              console.info('Click Point: 上传列表\n');
              this.controller.changeIndex(1)
              this.throughputUp[0] = 0
              //              this.tasknumUp += 1
              console.info("Click " + this.throughputUp[0] + " " + this.tasknumUp);
            })
          Button('添加文件', { type: ButtonType.Normal, stateEffect: true }).opacity(0.9)
            .borderRadius(8).width(120).fontSize(22).backgroundColor("#FF8C00")
            .onClick(async (event: ClickEvent) => {
              console.info('Click Point: 添加文件\n');


//              let types = ["jpg", "png", "txt"];
//              let uri = "";
//              let type = "jpg"
//              uri = "123.jpg"
//              document.show(uri, type, function(err) {
//                //do something
//                console.info("Click testTag show " + uri + " 0 " + err);
//              });
//              let str = await document.choose(types, function(err, uri) {
//                //do something with uri
//                console.info("Click testTag " + uri + " 0 " + err);
//                console.info("Click testTag " + types.toString());
//                hilog.info(0x0000, 'testTag', 'Click testTag %{public}s', uri);
//              });
//              console.info("Click testTag str " + str);
            })

        }.margin(10).height(40).width("100%")


        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Text("默认紧急程度: " + this.urgency).fontSize(18).margin({ left: 10, right: 10 })
          MyInputSmall({ placeholder: "整数1-5", inputValue: $urgency })
          // 条件渲染
          if (!this.urgency_reg.test(this.urgency.toString())) {
            Text("请输入整数1-5！").fontSize(18).fontColor("#999999").margin({ left: 10, right: 10 })
          }
        }.height(45).width("100%")


        //      Flex({direction: FlexDirection.Column, justifyContent:FlexAlign.Start}) {
        //        Text("文件传输列表: ").fontSize(18).margin({ left: 5, right: 10 })
        //      }.height(300).width("100%")
        //      .backgroundColor("#CCCCCC")

        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start }) {
          Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
            TabContent() {
              Flex({direction: FlexDirection.Column, justifyContent: FlexAlign.Start}) {
                Text("下载文件传输列表: ").fontSize(18).margin({ left: 5, top: 5, bottom: 5 }).onClick((event: ClickEvent) => {
                  console.info('Click Point: 下载文字\n');
                  this.throughputDown[0] = 1
                  //              this.tasknumDown += 1
                  console.info("Click " + this.throughputDown[0] + " " + this.tasknumDown);
                })
                List({ space: 4 }) {
                  ListItem() {
                    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.NoWrap }) {
                      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                        Text("文件名：" + this.fileNameDown[0]).fontSize(15).width("100%")
                        Text("文件大小：" + this.fileSizeDown[0] + "MB").fontSize(15).width("45%")
                        Text("紧急程度：" + this.urgencyDown[0]).fontSize(15).width("45%")
                        if (this.throughputDown[0] == 0) {
                          Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                        } else {
                          Text("网络吞吐量：" + this.throughputDown[0] + "MB/s").fontSize(15).width("50%")
                        }
                      }
                      .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                      //                .borderRadius(8)
                      //                .border({width:2, color:"#FFF"})
                      if (this.throughputDown[0] == 0) {
                        LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                        //                  .visibility(Visibility.None)
                        //                  .borderRadius(8)
                      } else {
                        Image($r('app.media.check')).width(40).height(65)
                      }
                    }
                  }

                  ListItem() {
                    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.NoWrap }) {
                      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                        Text("文件名：" + this.fileNameDown[1]).fontSize(15).width("100%")
                        Text("文件大小：" + this.fileSizeDown[1] + "MB").fontSize(15).width("45%")
                        Text("紧急程度：" + this.urgencyDown[1]).fontSize(15).width("45%")
                        if (this.throughputDown[1] == 0) {
                          Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                        } else {
                          Text("网络吞吐量：" + this.throughputDown[1] + "MB/s").fontSize(15).width("50%")
                        }
                      }
                      .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                      //                .borderRadius(8)
                      if (this.throughputDown[1] == 0) {
                        LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                        //                  .visibility(Visibility.None)
                        //                  .borderRadius(8)
                      } else {
                        Image($r('app.media.check')).width(40).height(65)
                      }
                    }
                  }

                  ListItem() {
                    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.NoWrap }) {
                      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                        Text("文件名：" + this.fileNameDown[2]).fontSize(15).width("100%")
                        Text("文件大小：" + this.fileSizeDown[2] + "MB").fontSize(15).width("45%")
                        Text("紧急程度：" + this.urgencyDown[2]).fontSize(15).width("45%")
                        if (this.throughputDown[2] == 0) {
                          Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                        } else {
                          Text("网络吞吐量：" + this.throughputDown[2] + "MB/s").fontSize(15).width("50%")
                        }
                      }
                      .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                      //                .borderRadius(8)
                      if (this.throughputDown[2] == 0) {
                        LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                        //                  .visibility(Visibility.None)
                        //                  .borderRadius(8)
                      } else {
                        Image($r('app.media.check')).width(40).height(65)
                      }
                    }
                  }

                }
                .height(300)
                .width("100%")
                .backgroundColor(0xDCDCDC)
                .padding({ left: 5, right: 5 })
                .listDirection(Axis.Vertical)
              }
            }

            TabContent() {
              Flex({direction: FlexDirection.Column, justifyContent: FlexAlign.Start}) {
                Text("上传文件传输列表: ").fontSize(18).margin({ left: 5, top: 5, bottom: 5 }).onClick((event: ClickEvent) => {
                  console.info('Click Point: 上传文字\n');
                  this.throughputUp[0] = 1
                  //              this.tasknumUp += 1
                  console.info("Click " + this.throughputUp[0] + " " + this.tasknumUp);
                })
                List({ space: 4 }) {
                  ListItem() {
                    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.NoWrap }) {
                      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                        Text("文件名：" + this.fileNameUp[0]).fontSize(15).width("100%")
                        Text("文件大小：" + this.fileSizeUp[0] + "MB").fontSize(15).width("45%")
                        Text("紧急程度：" + this.urgencyUp[0]).fontSize(15).width("45%")
                        if (this.throughputUp[0] == 0) {
                          Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                        } else {
                          Text("网络吞吐量：" + this.throughputUp[0] + "MB/s").fontSize(15).width("50%")
                        }
                      }
                      .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                      //                .borderRadius(8)
                      //                .border({width:2, color:"#FFF"})
                      if (this.throughputUp[0] == 0) {
                        LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                        //                  .visibility(Visibility.None)
                        //                  .borderRadius(8)
                      } else {
                        Image($r('app.media.check')).width(40).height(65)
                      }
                    }
                  }

                  ListItem() {
                    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.NoWrap }) {
                      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                        Text("文件名：" + this.fileNameUp[1]).fontSize(15).width("100%")
                        Text("文件大小：" + this.fileSizeUp[1] + "MB").fontSize(15).width("45%")
                        Text("紧急程度：" + this.urgencyUp[1]).fontSize(15).width("45%")
                        if (this.throughputUp[1] == 0) {
                          Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                        } else {
                          Text("网络吞吐量：" + this.throughputUp[1] + "MB/s").fontSize(15).width("50%")
                        }
                      }
                      .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                      //                .borderRadius(8)
                      if (this.throughputUp[1] == 0) {
                        LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                        //                  .visibility(Visibility.None)
                        //                  .borderRadius(8)
                      } else {
                        Image($r('app.media.check')).width(40).height(65)
                      }
                    }
                  }

                  ListItem() {
                    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.NoWrap }) {
                      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
                        Text("文件名：" + this.fileNameUp[2]).fontSize(15).width("100%")
                        Text("文件大小：" + this.fileSizeUp[2] + "MB").fontSize(15).width("45%")
                        Text("紧急程度：" + this.urgencyUp[2]).fontSize(15).width("45%")
                        if (this.throughputUp[2] == 0) {
                          Text("网络吞吐量：--MB/s").fontSize(15).width("50%")
                        } else {
                          Text("网络吞吐量：" + this.throughputUp[2] + "MB/s").fontSize(15).width("50%")
                        }
                      }
                      .width("100%").height(65).backgroundColor("#CCFFCC").padding(5)
                      //                .borderRadius(8)
                      if (this.throughputUp[2] == 0) {
                        LoadingProgress().color(Color.Blue).width(40).height(65).backgroundColor("#FFF")
                        //                  .visibility(Visibility.None)
                        //                  .borderRadius(8)
                      } else {
                        Image($r('app.media.check')).width(40).height(65)
                      }
                    }
                  }

                }
                .height(300)
                .width("100%")
                .backgroundColor(0xDCDCDC)
                .padding({ left: 5, right: 5 })
                .listDirection(Axis.Vertical)
              }
            }

            TabContent() {
            }
          }
          .width('100%').height(400).backgroundColor(0xDCDCDC)
          .vertical(true).scrollable(true).barMode(BarMode.Fixed)
          .barWidth(0).barHeight(0).animationDuration(100)
          .onChange((index: number) => {
            console.info(index.toString())
          })
        }//包含Tab的Flex
        .height(510).width("100%").backgroundColor(0xDCDCDC)
        .margin({ top: 15 })

      }//所有上部分组件的的Flex
      .width("100%")
//      .height("95%")
//      .border({ width: 10, color: "#00FFFF" })

      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
        Button("reload").width(80).borderRadius(10).backgroundColor("#00FFFF").fontColor(Color.Black)//00BFFF
        .onClick(() => {
          this.whoami = 1
          this.controller.changeIndex(this.whoami)
          this.tasknumDown = 3
          this.tasknumUp = 3

        })
        Button("tabEx").width(80).borderRadius(10).backgroundColor("#00FFFF").fontColor(Color.Black)//00FFFF
          .onClick(() => {
            router.clear();// push
            router.replace({ url: "pages/tabexample", params: { source: '准备接收文件' } })
          })
        Button("lnn").width(80).borderRadius(10).backgroundColor("#00FFFF").fontColor(Color.Black)//00FFFF
          .onClick(() => {
            router.clear();// push
            router.replace({ url: "pages/listdevices", params: { source: '准备检查设备' } })
          })
        Button("recvfile").width(80).borderRadius(10).backgroundColor("#00FFFF").fontColor(Color.Black)
          .onClick(() => {
            router.clear();
            router.replace({ url: "pages/recvfile", params: { source: '接收文件状态: ' } })
          })
        Button("send file").width(80).borderRadius(10).backgroundColor("#00FFFF").fontColor(Color.Black)
          .onClick(() => {
            router.clear();
            router.replace({ url: "pages/filedemo", params: { source: '准备发送文件' } })
          })
      }.height("5%").margin({ bottom: 10 }).backgroundColor("#FFF")

    }

//    Row() {
//      Column() {
//        Text(this.message)
//          .fontSize(20)
//          .fontWeight(FontWeight.Bold)
//          .width('30%')
//      }
//      .width('100%')
//    }
//    .height('100%')
  }
}