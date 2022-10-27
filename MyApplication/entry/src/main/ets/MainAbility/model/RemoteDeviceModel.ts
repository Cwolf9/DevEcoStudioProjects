/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import deviceManager from '@ohos.distributedHardware.deviceManager';

var SUBSCRIBE_ID = 100;
const MY_BUNDLE_NAME: string = "com.example.myapplication" //  'com.ohos.distributedDrawBoard'

export default class RemoteDeviceModel {
    deviceList: any[] = []
    callback: any
    #deviceManager: any
    discoverList = [];
    authCallback = null;

    constructor() {
    }

    registerDeviceListCallback(callback: any) {
        if (typeof (this.#deviceManager) === 'undefined') {
            console.log('lihlog_myapplication[RemoteDeviceModel] deviceManager.createDeviceManager begin');
            let self = this;
            // @ts-ignore
            deviceManager.createDeviceManager(MY_BUNDLE_NAME, (error, value) => {
                if (error) {
                    console.error('lihlog_myapplication[RemoteDeviceModel] createDeviceManager failed.');
                    return;
                }
                self.#deviceManager = value;
                self.registerDeviceListCallback_(callback);
                console.log('lihlog_myapplication[RemoteDeviceModel] createDeviceManager callback returned, error=' + error + ' value=' + value + ": " + JSON.stringify(value));
            });
            console.log('lihlog_myapplication[RemoteDeviceModel] deviceManager.createDeviceManager end'+ "\n\n");
        } else {
            this.registerDeviceListCallback_(callback);
        }
    }

    registerDeviceListCallback_(callback) {
        console.info('lihlog_myapplication[RemoteDeviceModel] registerDeviceListCallback_');
        this.callback = callback;
        if (this.#deviceManager == undefined) {
            console.error('lihlog_myapplication[RemoteDeviceModel] deviceManager has not initialized');
            this.callback();
            return;
        }

        console.info('lihlog_myapplication[RemoteDeviceModel] getTrustedDeviceListSync begin');
        var list = this.#deviceManager.getTrustedDeviceListSync();
        console.info('lihlog_myapplication[RemoteDeviceModel] getTrustedDeviceListSync end, deviceList='
            + JSON.stringify(list) + ", typeof list: " + typeof list);// deviceList=[], object
        if (typeof (list) != 'undefined' && typeof (list.length) != 'undefined' && list.length != 0) {
            this.deviceList = list;
        }
        this.callback();
        console.info('lihlog_myapplication[RemoteDeviceModel] callback finished');

        if(SUBSCRIBE_ID != 100) {
            this.unregisterDiscCallback()
        }
        let self = this;
        this.#deviceManager.on('deviceStateChange', (data) => {
            console.info('lihlog_myapplication[RemoteDeviceModel] deviceStateChange data=' + JSON.stringify(data));
            switch (data.action) {
                case 0:
                    for (var i = 0; i < self.deviceList.length; i++) {
                        if (self.deviceList[i].deviceId === data.device.deviceId) {
                            console.info('lihlog_myapplication[RemoteDeviceModel] device already in, ignored');
                            return;
                        }
                    }
                    self.deviceList[self.deviceList.length] = data.device;
                    console.info('lihlog_myapplication[RemoteDeviceModel] online, updated device list=' + JSON.stringify(self.deviceList));
                    self.callback();
                    if (self.authCallback != null) {
                        self.authCallback();
                        self.authCallback = null;
                    }
                    break;
                case 2:
                    if (self.deviceList.length > 0) {
                        for (var i = 0; i < self.deviceList.length; i++) {
                            if (self.deviceList[i].deviceId === data.device.deviceId) {
                                self.deviceList[i] = data.device;
                                break;
                            }
                        }
                    }
                    console.info('lihlog_myapplication[RemoteDeviceModel] change, updated device list=' + JSON.stringify(self.deviceList));
                    self.callback();
                    break;
                case 1:
                    if (self.deviceList.length > 0) {
                        var list = [];
                        for (var i = 0; i < self.deviceList.length; i++) {
                            if (self.deviceList[i].deviceId != data.device.deviceId) {
                                list[i] = data.device;
                            }
                        }
                        self.deviceList = list;
                    }
                    console.info('lihlog_myapplication[RemoteDeviceModel] offline, updated device list=' + JSON.stringify(data.device));
                    self.callback();
                    break;
                default:
                    break;
            }
        });
        this.#deviceManager.on('deviceFound', (data) => {
            console.info('lihlog_myapplication[RemoteDeviceModel] deviceFound data=' + JSON.stringify(data));
            console.info('lihlog_myapplication[RemoteDeviceModel] deviceFound self.deviceList=' + JSON.stringify(self.deviceList));
            console.info('lihlog_myapplication[RemoteDeviceModel] deviceFound self.deviceList.length=' + self.deviceList.length);
            for (var i = 0; i < self.discoverList.length; i++) {
                if (self.discoverList[i].deviceId === data.device.deviceId) {
                    console.info('lihlog_myapplication[RemoteDeviceModel] deviceFounded, ignored');
                    return;
                }
            }
            self.discoverList[self.discoverList.length] = data.device;
            // todo: fix 上述回调函数 deviceStateChange() 没有执行
            self.deviceList[self.deviceList.length] = data.device;
            console.info('lihlog_myapplication[RemoteDeviceModel] deviceFound, updated device list=' + JSON.stringify(self.deviceList)+ "\n\n");
            self.callback();
        });
        this.#deviceManager.on('discoverFail', (data) => {
            console.info('lihlog_myapplication[RemoteDeviceModel] discoverFail data=' + JSON.stringify(data));
        });
        this.#deviceManager.on('serviceDie', () => {
            console.error('lihlog_myapplication[RemoteDeviceModel] serviceDie');
        });

        SUBSCRIBE_ID = Math.floor(65536 * Math.random());
        var info = {
            subscribeId: SUBSCRIBE_ID,// 服务订阅ID【0~65535】，对每个发现进程来说应该是唯一的
            mode: 0xAA,//主动模式
            medium: 2,//订阅媒介 2-wifi
            freq: 1,// 订阅频率 高
            isSameAccount: false,// 只能找到帐号相同的设备
            isWakeRemote: true,// 发现休眠设备
            capability: 0
        };
        console.info('lihlog_myapplication[RemoteDeviceModel] startDeviceDiscovery ' + SUBSCRIBE_ID);
        try {
            this.#deviceManager.startDeviceDiscovery(info);
        }catch (err)  {
            console.info("lihlog_myapplication[RemoteDeviceModel] startDeviceDiscovery err: " + err + ":" + JSON.stringify(err) + ";" + typeof err)
        }
    }

    authDevice(deviceId, callback) {
        console.info('lihlog_myapplication[RemoteDeviceModel] authDevice: ' + deviceId);
        if (this.#deviceManager == undefined) {
            console.error('lihlog_myapplication[RemoteDeviceModel] deviceManager has not initialized');
            this.callback();
            return;
        }
        console.info('lihlog_myapplication[RemoteDeviceModel] authDevice: ' + deviceId + ", " + this.discoverList.length + ", " + JSON.stringify(this.discoverList));
        for (var i = 0; i < this.discoverList.length; i++) {
            if (this.discoverList[i].deviceId === deviceId) {
                // 在线设备中存在此设备,创建扩展信息
                console.info('lihlog_myapplication[RemoteDeviceModel] device founded, authDevice begin');
                let extraInfo = {
                    "targetPkgName": MY_BUNDLE_NAME,
                    "appName": 'Music',
                    "appDescription": 'Music player application',
                    "business": '0'
                };
                let authParam = {
                    "authType": 1, // 认证类型，1为pin码
                    "appIcon": '',
                    "appThumbnail": '',
                    "extraInfo": extraInfo // 扩展信息：key-value
                };
                console.info('lihlog_myapplication[RemoteDeviceModel] authenticateDevice ' + JSON.stringify(this.discoverList[i]));
                let self = this;
                this.#deviceManager.authenticateDevice(this.discoverList[i], authParam, (err, data) => {
                    if (err) {
                        console.info('lihlog_myapplication[RemoteDeviceModel] authenticateDevice failed, err=' + JSON.stringify(err));
                        // err={"code":8,"reason":0}
                        // err={"code":1,"reason":2011}
                        self.authCallback = null;
                    } else {
                        console.info('lihlog_myapplication[RemoteDeviceModel] authenticateDevice succeed, data=' + JSON.stringify(data));
                        self.authCallback = callback;
                    }
                });
                console.info('lihlog_myapplication[RemoteDeviceModel] device founded, authDevice end');
                break;
            }
        }
    }
    unregisterDiscCallback() {
        console.info('lihlog_myapplication[RemoteDeviceModel] stopDeviceDiscovery ' + SUBSCRIBE_ID);
        try {
            this.#deviceManager.stopDeviceDiscovery(SUBSCRIBE_ID);
        }catch (err)  {
            console.info("lihlog_myapplication[RemoteDeviceModel] stopDeviceDiscovery err: " + err + ":" + JSON.stringify(err) + ";" + typeof err)
            // Error: Failed to execute the function.:{"code":"11600101"}
        }
    }
    unregisterDeviceListCallback() {
        console.info('lihlog_myapplication[RemoteDeviceModel] stopDeviceDiscovery ' + SUBSCRIBE_ID);
        try {
            this.#deviceManager.stopDeviceDiscovery(SUBSCRIBE_ID);
        }catch (err)  {
            console.info("lihlog_myapplication[RemoteDeviceModel] stopDeviceDiscovery err: " + err + ":" + JSON.stringify(err) + ";" + typeof err)
        }
        this.#deviceManager.off('deviceStateChange');
        this.#deviceManager.off('deviceFound');
        this.#deviceManager.off('discoverFail');
        this.#deviceManager.off('serviceDie');
        this.#deviceManager.off('authResult');
        this.deviceList = [];
        this.discoverList = []
    }
}
/*
 * 分布式数据服务开发指导 https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/database/database-mdds-guidelines.md
 * Stage模型综述 https://docs.openharmony.cn/pages/v3.2Beta/zh-cn/application-dev/ability/stage-brief.md/
 * 华为专家讲解 OpenHarmony 开源鸿蒙硬件资源池化模型 https://baijiahao.baidu.com/s?id=1731361708762713196&wfr=spider&for=pc
 * DeviceManager部件 https://gitee.com/openharmony/distributedhardware_device_manager
 * 设备管理 https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis/js-apis-device-manager.md
 * OpenHarmony分布式 启动远程设备的FA实例 https://ost.51cto.com/posts/11789
 * */