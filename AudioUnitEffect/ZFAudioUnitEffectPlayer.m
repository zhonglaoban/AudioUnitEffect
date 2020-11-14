//
//  ZFAudioUnitPlayer.m
//  AudioUnitEffect
//
//  Created by 钟凡 on 2020/1/17.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ZFAudioUnitEffectPlayer.h"

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else {
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
        fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    }
}

@interface ZFAudioUnitEffectPlayer()

@property (nonatomic, assign) AudioUnit ioUnit;
@property (nonatomic, assign) AudioUnit reverbUnit;
@property (nonatomic, assign) AudioStreamBasicDescription *asbd;
@property (nonatomic) dispatch_queue_t queue;

@end


@implementation ZFAudioUnitEffectPlayer

- (instancetype)initWithAsbd:(AudioStreamBasicDescription *)asbd {
    self = [super init];
    if (self) {
        _asbd = asbd;
        _queue = dispatch_queue_create("zf.audioPlayer", DISPATCH_QUEUE_SERIAL);

        [self createAudioUnits];
        [self setupAudioUnits];
    }
    return self;
}
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
@end



