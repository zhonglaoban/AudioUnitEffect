## 如何为Audio Unit 设置特效
设置音频特效使用的是AudioEffectUnit，我们这里实现的是`Reverb`（混响）特效。生活中表现的场景就是在不同的空间下有不同的音效。

本篇文章分为以下4个部分：
1. 使用`ExtAudioFile`从文件中读取音频数据。
2. 将数据传递给`AudioEffectUnit `处理。
3. 使用`AudioOutputUnit `进行播放。
4. 设置`reverbUnit `的属性。

## 使用`ExtAudioFile`读取文件
`ExtAudioFile`可以按照我们设置的数据格式读取文件，很方便，具体参照这篇文章。
[ExtAudioFile如何使用](https://www.jianshu.com/p/03491bf9bd0b)

## `AudioEffectUnit `处理数据
数据流向图
![effect.png](https://upload-images.jianshu.io/upload_images/3277096-a9d74af858f42b8e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 创建`AudioUnit`
混响效果在iOS上是`kAudioUnitSubType_Reverb2`，在mac上是`kAudioUnitSubType_MatrixReverb`
```objc
- (void)createAudioUnits {
    AudioComponentDescription ioDesc = {0};
    ioDesc.componentType = kAudioUnitType_Output;
    ioDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    ioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponentDescription reverbDesc = {0};
    reverbDesc.componentType = kAudioUnitType_Effect;
    reverbDesc.componentSubType = kAudioUnitSubType_Reverb2;
    reverbDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    OSStatus status;
    AudioComponent outputComp = AudioComponentFindNext(NULL, &ioDesc);
    if (outputComp == NULL) {
        printf("can't get AudioComponent");
    }
    status = AudioComponentInstanceNew(outputComp, &_ioUnit);
    CheckError(status, "creat output unit");
    
    AudioComponent reverbComp = AudioComponentFindNext(NULL, &reverbDesc);
    if (reverbComp == NULL) {
        printf("can't get AudioComponent");
    }
    status = AudioComponentInstanceNew(reverbComp, &_reverbUnit);
    CheckError(status, "creat reverb unit");
}
```
### 设置`AudioUnit`属性
将`AudioOutputUnit`的输入和`AudioEffectUnit`输出连接起来。`AudioEffectUnit`的输入就是它的`callback`。
```objc
- (void)setupAudioUnits {
    OSStatus status;
    
    // Set the callback method
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = InputRenderCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(_reverbUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    CheckError(status, "set callback");
    
    //make connection
    AudioUnitConnection connection;
    connection.sourceAudioUnit    = _reverbUnit;
    connection.sourceOutputNumber = 0;
    connection.destInputNumber    = 0;

    status = AudioUnitSetProperty(_ioUnit,                             // connection destination
                                  kAudioUnitProperty_MakeConnection,   // property key
                                  kAudioUnitScope_Input,               // destination scope
                                  0,                           // destination element
                                  &connection,                 // connection definition
                                  sizeof(connection));
    CheckError(status, "make connection");
}
```
### 在`AudioUnit`回调中填充数据
```objc
static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
    ZFAudioUnitEffectPlayer *player = (__bridge ZFAudioUnitEffectPlayer *)inRefCon;

    [player.dataSource readDataToBuffer:ioData length:inNumberFrames];
    
    return noErr;
}
```

## 使用`AudioOutputUnit `进行播放
播放和暂停。
```objc
- (void)startPlay {
    dispatch_async(_queue, ^{
        OSStatus status;
        status = AudioUnitInitialize(self.reverbUnit);
        CheckError(status, "initialize reverb unit");
        status = AudioUnitInitialize(self.ioUnit);
        CheckError(status, "initialize output unit");
        status = AudioOutputUnitStart(self.ioUnit);
        CheckError(status, "start output unit");
    });
}
- (void)stopPlay {
    dispatch_async(_queue, ^{
        OSStatus status;
        status = AudioOutputUnitStop(self.ioUnit);
        CheckError(status, "stop output unit");
        status = AudioUnitUninitialize(self.ioUnit);
        CheckError(status, "uninitialize output unit");
        status = AudioUnitUninitialize(self.reverbUnit);
        CheckError(status, "uninitialize reverb unit");
    });
}
```
## 设置`reverbUnit`的属性
`reverbUnit`有7个属性可以设置，都在这里了。不太懂音律，大家可以运行demo自己尝试一下不同的效果。
```objc
- (void)setDryWetMix:(Float32)dryWetMix {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, dryWetMix, 0);
}
- (void)setGain:(Float32)gain {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_Gain, kAudioUnitScope_Global, 0, gain, 0);
}
- (void)setMinDelayTime:(Float32)minDelayTime {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_MinDelayTime, kAudioUnitScope_Global, 0, minDelayTime, 0);
}
- (void)setMaxDelayTime:(Float32)maxDelayTime {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_MaxDelayTime, kAudioUnitScope_Global, 0, maxDelayTime, 0);
}
- (void)setDecayTimeAt0Hz:(Float32)decayTimeAt0Hz {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, decayTimeAt0Hz, 0);
}
- (void)setDecayTimeAtNyquist:(Float32)decayTimeAtNyquist {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_DecayTimeAtNyquist, kAudioUnitScope_Global, 0, decayTimeAtNyquist, 0);
}
- (void)setRandomizeReflections:(Float32)randomizeReflections {
    AudioUnitSetParameter(_reverbUnit, kReverb2Param_RandomizeReflections, kAudioUnitScope_Global, 0, randomizeReflections, 0);
}
```
[Github地址](https://github.com/zhonglaoban/AudioUnitEffect)
