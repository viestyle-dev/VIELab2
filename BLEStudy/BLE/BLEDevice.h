//
//  BLEDevice.h
//  BLEStudy
//
//  Created by mio kato on 2022/03/06.
//
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEDelegate.h"

@interface BLEDevice : NSObject  <BLEDelegate>
{
}

@property (nonatomic, assign) id<BLEDelegate> delegate;

+ (BLEDevice *)sharedInstance;
-(NSString *) getVersion;
-(void)scanDevice;
-(void)stopScanDevice;
-(void)connectDevice:(NSString *)deviceID;
-(void)disconnectDevice;

-(void)start;
-(void)stop;

@end
