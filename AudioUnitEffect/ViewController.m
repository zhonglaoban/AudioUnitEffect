//
//  ViewController.m
//  AudioUnitEffect
//
//  Created by 钟凡 on 2019/11/20.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZFAudioUnitEffectPlayer.h"
#import "ZFAudioFileReader.h"

@interface ViewController ()<ZFAudioUnitPlayerDataSourse>

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) AudioStreamBasicDescription asbd;
@property (nonatomic, strong) ZFAudioUnitEffectPlayer *audioPlayer;
@property (nonatomic, strong) ZFAudioFileReader *fileReader;

@end


@implementation ViewController
- (IBAction)playAndRecord:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    if (sender.isSelected) {
        [_audioPlayer startPlay];
    }else {
        [_audioPlayer stopPlay];
    }
}
- (IBAction)dryWetMixChanged:(UISlider *)sender {
    _audioPlayer.dryWetMix = sender.value;
    printf("%f \n", sender.value);
}
- (IBAction)gainChanged:(UISlider *)sender {
    _audioPlayer.gain = sender.value;
    printf("%f \n", sender.value);
}
- (IBAction)minDelayTimeChanged:(UISlider *)sender {
    _audioPlayer.minDelayTime = sender.value;
    printf("%f \n", sender.value);
}
- (IBAction)maxDelayTimeChanged:(UISlider *)sender {
    _audioPlayer.maxDelayTime = sender.value;
    printf("%f \n", sender.value);
}
- (IBAction)decayTimeAt0HzChanged:(UISlider *)sender {
    _audioPlayer.decayTimeAt0Hz = sender.value;
    printf("%f \n", sender.value);
}
- (IBAction)decayTimeAtNyquistChanged:(UISlider *)sender {
    _audioPlayer.decayTimeAtNyquist = sender.value;
    printf("%f \n", sender.value);
}
- (IBAction)randomizeReflectionsChanged:(UISlider *)sender {
    _audioPlayer.randomizeReflections = sender.value;
    printf("%f \n", sender.value);
}

-(void)dealloc {
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _queue = dispatch_queue_create("zf.audioGenarator", DISPATCH_QUEUE_SERIAL);
    
    _asbd.mSampleRate = 44100;
    _asbd.mFormatID = kAudioFormatLinearPCM;
    _asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    _asbd.mBytesPerPacket = 4;
    _asbd.mFramesPerPacket = 1;
    _asbd.mBytesPerFrame = 4;
    _asbd.mChannelsPerFrame = 2;
    _asbd.mBitsPerChannel = 32;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    
    _fileReader = [[ZFAudioFileReader alloc] init];
    NSString *source = [[NSBundle mainBundle] pathForResource:@"goodbye" ofType:@"mp3"];
    [_fileReader openFile:source format:&_asbd];
    
    _audioPlayer = [[ZFAudioUnitEffectPlayer alloc] initWithAsbd:&_asbd];
    _audioPlayer.dataSource = self;
}
- (void)readDataToBuffer:(AudioBufferList *)ioData length:(UInt32)inNumberFrames {
    [_fileReader readBufferList:ioData frames:inNumberFrames];
}

@end
