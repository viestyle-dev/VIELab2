#import <Foundation/Foundation.h>

@protocol AnalyzeDelegate <NSObject>

@optional

-(void)eSenseRightSQ:(int)poorSignal;
-(void)eSenseLeftSQ:(int)poorSignal;
-(void)FrequencyRight:(double*)index PowerSpectrum:(double*)power;
-(void)FrequencyLeft:(double*)index PowerSpectrum:(double*)power;

@end
