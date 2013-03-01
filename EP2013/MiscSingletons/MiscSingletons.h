//
//  MiscSingletons.h
//  EP2013
//
//  2012-07-23  composeWaveNameFromBlockNum changed: "andSequenceNum"
//  2012-07-09  dictFromPListFileArray, objectFromDict, floatFromDict: 
//              Newly created to derive parameters from Array of pList-Files (SetupInfo, StimulusSteppers) TM
//  Created by bach on 15.02.12.
//  Copyright 2012 Department of Ophthalmology, University Medical Center Freiburg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MiscSingletons : NSObject


+ (NSString *) path2ApplicationContainer;
+ (NSString *) path2StimuliFolder;
+ (NSString *) path2SetupInfoPList;
+ (NSString *) path2EPFileGivenEPNum: (int) epNum;

+ (NSString *) date2YYYY_MM_DD: (NSDate *) theDate;
+ (NSString *) date2HH_MM_SS: (NSDate *) theDate;

+ (char) blockCharFromNumber: (NSUInteger) blockNumber;
+ (NSUInteger) blockNumberFromChar: (char) blockChar;

+ (NSString *) composeWaveNameFromBlockNum: (NSUInteger) blk andSequenceNum: (NSUInteger) seq andChannel: (NSUInteger) chn;

+ (NSDictionary *) dictFromPListFileArray: (NSMutableArray *) pListFileArray pListFileIndex: (NSUInteger) plindex dictIndex : (NSUInteger) dindex;

+ (NSObject*) objectFromDict: (NSDictionary *) theDict forKey: (NSString *) key;

+ (CGFloat) floatFromDict: (NSDictionary *) theDict forKey: (NSString *) key;


@end
