// Component 装饰器
@Component
struct MyInputSmall {// 组件
  @Link inputValue:string
  @Prop placeholder:string
  build() {
    TextInput({placeholder:this.placeholder, text:this.inputValue})
      .onChange((value:string)=>{
        this.inputValue = value
      })
      .width(100)
      .height(40)
      .margin(5)
      .fontSize(15)
  }
}

@Component
struct MyInputMid {// 组件
  @Link inputValue:string
  @Prop placeholder:string
  build() {
    TextInput({placeholder:this.placeholder, text:this.inputValue})
      .onChange((value:string)=>{
        this.inputValue = value
      })
      .width(200)
      .height(40)
      .margin(5)
      .fontSize(15)
  }
}

@Component
struct MyTextMid {// 组件
  @Prop textString:string
  build() {
    Text(this.textString)
      .width(300)
      .height(60)
      .margin({top:20})
      .fontSize(15)
      .padding(5)
      .textAlign(TextAlign.Center)
      .border({color:"#FF0000", width:2})
  }
}

@Component
struct MyTextLog {// 组件
  @Prop textString:string
  build() {
    Text(this.textString)
      .width(400).height(250).fontSize(15)
      .padding(5).backgroundColor("#CCAAFF")
      .baselineOffset(400)
      .textAlign(TextAlign.Start)
      .textOverflow({overflow: TextOverflow.None})
  }
}

export default MyInputSmall;
export {MyInputMid, MyTextMid, MyTextLog}


/*
TS在JS基础上扩展了什么
类
接口
模块
lambda函数
...

ES6在ES5的基础上新增了哪些功能呢?
let命令，声明变量
const命令，声明只读常量
class命令，类的概念
import命令，声明命令
...

* let让JS真正拥有了块级作用域，虽然增加了很多约束，但都是为了代码更规范更安全。
* https://blog.csdn.net/weixin_42653522/article/details/103790735

 * */