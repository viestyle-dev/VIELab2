#import <Foundation/Foundation.h>
#import "AnalyzeDelegate.h"

@interface Analyze : NSObject
{
}

@property (nonatomic, assign) id<AnalyzeDelegate> delegate;

+ (Analyze *) sharedInstance;

- (NSString *)getVersion;

- (int) reset;

- (bool) checkOffheadRight:(int) status;

- (bool) checkOffheadLeft:(int) status;

- (int) updateWithRawDataRight: (double) rawData;

- (int) updateWithRawDataLeft: (double) rawData;

- (void) enableHPFFilter: (double) cutOff;

- (int) doHpfRight: (int) raw;

- (int) doHpfLeft: (int) raw;

- (void) disableHPFFilter;

@end
