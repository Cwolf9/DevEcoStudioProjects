import hilog from '@ohos.hilog';
import testNapi from 'libentry.so'
import featureAbility from '@ohos.ability.featureAbility'
import rdb from '@ohos.data.rdb';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
            hilog.info(0x0000, 'testTag', 'Test NAPI 2 + 3 = %{public}d', testNapi.add(2, 3));
          })
        Button("ck")
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {

          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
