//
//  ZFAudioFileReader.h
//  AudioFile
//
//  Created by 钟凡 on 2020/10/31.
//  Copyright © 2020 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFAudioFileReader : NSObject

- (void)openFile:(NSString *)filePath format:(AudioStreamBasicDescription *)format;
- (void)readData:(void *)data length:(int)length;
- (void)readBufferList:(AudioBufferList *)bufferList frames:(UInt32)frames;
- (void)closeFile;

@end

NS_ASSUME_NONNULL_END
