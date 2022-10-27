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

import distributedData from '@ohos.data.distributedData';

const STORE_ID = 'DrawBoard_kvstore';
const MY_BUNDLE_NAME: string = "com.example.myapplication" //  'com.ohos.distributedDrawBoard'

export default class KvStoreModel {
    kvManager: any;
    kvStore: any;

    constructor() {
    }

    createKvStore(callback: any) {
        if (typeof (this.kvStore) === 'undefined') {
            var config = {
                bundleName: MY_BUNDLE_NAME,
                userInfo: {
                    userId: '0',
                    userType: 0
                }
            };
            let self = this;
            console.info('lihlog_myapplication[KvStoreModel] createKVManager begin');
            distributedData.createKVManager(config).then((manager) => {
                console.info('lihlog_myapplication[KvStoreModel] createKVManager success, kvManager=' + JSON.stringify(manager));
                self.kvManager = manager;
                let options = {
                    createIfMissing: true,
                    encrypt: false,
                    backup: false,
                    autoSync: true,
                    kvStoreType: 0,
                    schema: '',
                    securityLevel: 1,
                };
                console.info('lihlog_myapplication[KvStoreModel] kvManager.getKVStore begin');
                self.kvManager.getKVStore(STORE_ID, options).then((store) => {
                    console.info('lihlog_myapplication[KvStoreModel] getKVStore success, kvStore=' + store);
                    self.kvStore = store;
                    try {
                        self.kvStore.enableSync(true).then((err) => {
                            console.log('enableSync success');
                        }).catch((err) => {
                            console.log('enableSync fail ' + JSON.stringify(err));
                        });
                    }catch(e) {
                        console.log('EnableSync e ' + e);
                    }
                    callback();
                });
                console.info('lihlog_myapplication[KvStoreModel] kvManager.getKVStore end');
            });
            console.info('lihlog_myapplication[KvStoreModel] createKVManager end');
        } else {
            console.info('lihlog_myapplication[KvStoreModel] KVManager is exist');
            callback();
        }
    }

    broadcastMessage(msg: any) {
        console.info('lihlog_myapplication[KvStoreModel] broadcastMessage ' + msg);
        var num = Math.random();
        let self = this;
        this.createKvStore(() => {
            self.put(msg, num);
        });
    }

    put(key: any, value: any) {
        if (typeof (this.kvStore) === 'undefined') {
            return;
        }
        console.info('lihlog_myapplication[KvStoreModel] kvStore.put ' + key + '=' + value);
        this.kvStore.put(key, value).then((data: any) => {
            this.kvStore.get(key).then((data:any) => {
                console.info('lihlog_myapplication[KvStoreModel] kvStore.get ' + key + '=' + JSON.stringify(data));
            });
            console.info('lihlog_myapplication[KvStoreModel] kvStore.put ' + key + ' finished, data=' + JSON.stringify(data));
        }).catch((err: JSON) => {
            console.error('lihlog_myapplication[KvStoreModel] kvStore.put ' + key + ' failed, ' + JSON.stringify(err));
        });
    }

    get(key: any,callback: any) {
        this.createKvStore(() => {
            this.kvStore.get(key, function (err: any ,data: any) {
                console.log("get success data: " + data);
                callback(data);
            });
        })
    }

    setOnMessageReceivedListener(callback: any) {
        console.info('lihlog_myapplication[KvStoreModel] setOnMessageReceivedListener ');
        let self = this;
        this.createKvStore(() => {
            console.info('lihlog_myapplication[KvStoreModel] kvStore.on(dataChange) begin');
            self.kvStore.on('dataChange', 2, (data: any) => {
                console.info('lihlog_myapplication[KvStoreModel] dataChange, ' + JSON.stringify(data));
                console.info('lihlog_myapplication[KvStoreModel] dataChange, insert ' + data.insertEntries.length + ' udpate '
                + data.updateEntries.length);
                if (data.insertEntries.length < 1 && data.updateEntries.length < 1) {
                    return;
                }

                callback(data);
            });
            console.info('lihlog_myapplication[KvStoreModel] kvStore.on(dataChange) end');
        });
    }
    setDataChangeListener(callback) {
        console.info('lihlog_myapplication[KvStoreModel] setDataChangeListener come in');
        let self = this;
        this.createKvStore(() => {
            console.info('lihlog_myapplication[KvStoreModel] setDataChangeListener createKvStore');
            self.kvStore.on('dataChange',2, (data: any) => {
                console.info('lihlog_myapplication[KvStoreModel] setDataChangeListener kvStore.on');
                if (data.updateEntries.length > 0) {
                    console.info('lihlog_myapplication[KvStoreModel] setDataChangeListener callback');
                    callback(data);
                }
            });
        });
    }
}