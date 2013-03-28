//
//  MTFormat.h
//  cTiVo
//
//  Created by Scott Buchanan on 1/12/13.
//  Copyright (c) 2013 Scott Buchanan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTFormat : NSObject <NSCopying> {
	NSArray *keys;
}

@property (nonatomic, retain) NSString	*formatDescription,
										*filenameExtension,
										*encoderUsed,
										*name,
                                        *encoderVideoOptions,
                                        *encoderAudioOptions,
                                        *encoderOtherOptions,
                                        *encoderEarlyVideoOptions,
                                        *encoderEarlyAudioOptions,
                                        *encoderEarlyOtherOptions,
                                        *encoderLateVideoOptions,
                                        *encoderLateAudioOptions,
                                        *encoderLateOtherOptions,
										*inputFileFlag,
										*outputFileFlag,
										*edlFlag,
										*comSkipOptions,
										*captionOptions,
										*regExProgress;

@property (nonatomic, retain) NSNumber	*comSkip,
										*iTunes,
										*mustDownloadFirst,
                                        *isHidden,
										*isFactoryFormat;

@property (nonatomic, retain) NSAttributedString *attributedFormatDescription;

@property (nonatomic, readonly) BOOL canAddToiTunes, canSimulEncode, isAvailable, canSkip, canAtomicParsley;
@property (nonatomic, readonly) NSString * pathForExecutable;

@property (nonatomic, retain) NSString * formerName;//only used to update existing format objects when name is edited.

+(MTFormat *)formatWithDictionary:(NSDictionary *)format;

-(NSDictionary *)toDictionary;
-(BOOL)isSame:(MTFormat *)testFormat;

-(NSAttributedString *) attributedFormatStringForFont:(NSFont *) font;
-(void)checkAndUpdateFormatName:(NSArray *)formatList;


@end
