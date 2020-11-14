//
//  ZFAudioUnitEffectPlayer.h
//  AudioUnitEffect
//
//  Created by 钟凡 on 2020/1/17.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZFAudioUnitPlayerDataSourse <NSObject>

- (void)readDataToBuffer:(AudioBufferList *)ioData length:(UInt32)inNumberFrames;

@end


@interface ZFAudioUnitEffectPlayer : NSObject

@property (nonatomic, weak) id<ZFAudioUnitPlayerDataSourse> dataSource;
// Global, CrossFade, 0->100, 100
@property (nonatomic, assign) Float32 dryWetMix;
// Global, Decibels, -20->20, 0
@property (nonatomic, assign) Float32 gain;
// Global, Secs, 0.0001->1.0, 0.008
@property (nonatomic, assign) Float32 minDelayTime;
// Global, Secs, 0.0001->1.0, 0.050
@property (nonatomic, assign) Float32 maxDelayTime;
// Global, Secs, 0.001->20.0, 1.0
@property (nonatomic, assign) Float32 decayTimeAt0Hz;
// Global, Secs, 0.001->20.0, 0.5
@property (nonatomic, assign) Float32 decayTimeAtNyquist;
// Global, Integer, 1->1000
@property (nonatomic, assign) Float32 randomizeReflections;

- (instancetype)initWithAsbd:(AudioStreamBasicDescription *)asbd;

- (void)startPlay;
- (void)stopPlay;

@end

NS_ASSUME_NONNULL_END
