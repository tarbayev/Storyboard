#import "MyObjCClass.h"

@implementation MyObjCClass

- (NSString *)description
{
    return [[super description] stringByAppendingString:@"\nIt works!"];
}

@end
