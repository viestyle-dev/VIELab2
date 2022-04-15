#import <Foundation/Foundation.h>

@protocol BLEDelegate <NSObject>

-(void)deviceFound:(NSString *)devName MfgID:(NSString *)mfgID DeviceID:(NSString *)deviceID;
-(void)didConnect;
-(void)didDisconnect;

@optional

-(void)eegSampleLeft:(int)left Right:(int)right;
-(void)sensorStatus:(int) status;
-(void)battery:(int) percent;

@end
