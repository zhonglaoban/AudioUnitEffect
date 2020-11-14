//
//  ZFAudioFileReader.m
//  AudioFile
//
//  Created by 钟凡 on 2020/10/31.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import "ZFAudioFileReader.h"

@interface ZFAudioFileReader()

@property (nonatomic) ExtAudioFileRef fileId;
@property (nonatomic) AudioStreamBasicDescription fileFormat;
@property (nonatomic) AudioStreamBasicDescription *dataFormat;

@end


@implementation ZFAudioFileReader

- (void)openFile:(NSString *)filePath format:(AudioStreamBasicDescription *)format {
    CFURLRef cfurl = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, false);
    
    _dataFormat = format;
    
    // 打开文件
    OSStatus result = ExtAudioFileOpenURL(cfurl, &_fileId);
    printf("ExtAudioFileOpenURL result %d \n", result);
    
    CFRelease(cfurl);
    
    // 读取文件格式
    UInt32 propSize = sizeof(AudioStreamBasicDescription);
    result = ExtAudioFileGetProperty(_fileId, kExtAudioFileProperty_FileDataFormat, &propSize, &_fileFormat);
    printf("get absd: %d \n", result);
    
    // 设置音频数据格式
    propSize = sizeof(AudioStreamBasicDescription);
    result = ExtAudioFileSetProperty(_fileId, kExtAudioFileProperty_ClientDataFormat, propSize, _dataFormat);
    printf("set absd: %d \n", result);
}
- (void)readBufferList:(AudioBufferList *)bufferList frames:(UInt32)frames {
    OSStatus result = ExtAudioFileRead(_fileId, &frames, bufferList);
    if (result != noErr) {
        printf("ExtAudioFileRead %d \n", result);
    }
}
- (void)readData:(void *)data length:(int)length {
    AudioBufferList ioData = {};
    AudioBuffer buffer = {};
    buffer.mData = data;
    buffer.mDataByteSize = length;
    buffer.mNumberChannels = _dataFormat->mChannelsPerFrame;
    
    ioData.mBuffers[0] = buffer;
    ioData.mNumberBuffers = 1;
    
    UInt32 inNumberFrames = length / _dataFormat->mBytesPerFrame;
    
    OSStatus result = ExtAudioFileRead(_fileId, &inNumberFrames, &ioData);
    printf("ExtAudioFileRead %d \n", result);
}
- (void)closeFile {
    ExtAudioFileDispose(_fileId);
}

@end
