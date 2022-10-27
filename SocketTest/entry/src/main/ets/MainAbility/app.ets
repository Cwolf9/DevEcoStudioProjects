import hilog from '@ohos.hilog';

export default {
  onCreate() {
    console.info("Application onCreate " + "default");
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Application onCreate');
  },
  onDestroy() {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Application onDestroy');
  },
}