//
//  TestModel.m
//  CBModelTests
//
//  Created by Captain Black on 2023/7/14.
//  Copyright (c) 2023 Captain Black. All rights reserved.
//

#import "TestModel.h"

@implementation TestModel

@dynamic intValue;
@dynamic ldValue;
@dynamic floatValue;
@dynamic doubleValue;
@dynamic boolValue;
@dynamic charValue;
@dynamic shortValue;
@dynamic longValue;
@dynamic unsignedIntValue;
@dynamic unsignedLongLongValue;

@dynamic strongString;
@dynamic cpString;
@dynamic weakObject;

@dynamic atomicIntValue;
@dynamic atomicString;

@dynamic arrayValue;
@dynamic dictValue;

@dynamic pointValue;
@dynamic sizeValue;
@dynamic rectValue;
@dynamic edgeInsetsValue;
@dynamic rangeValue;
@dynamic transformValue;
@dynamic transform3DValue;
@dynamic customStructValue;
@dynamic bigStructValue;
@dynamic unionValue;

@dynamic atomicPointValue;
@dynamic atomicRectValue;
@dynamic atomicTransform3DValue;

@dynamic current;
@dynamic specialName;

@dynamic readonlyIntValue;
@dynamic readonlyString;
@dynamic readonlyPointValue;

@end

@implementation ResolveRaceModel

@dynamic propA;
@dynamic propB;
@dynamic propC;
@dynamic propD;
@dynamic propE;
@dynamic strF;
@dynamic strG;
@dynamic strH;

@end

@implementation ResolveRaceModel2

@dynamic propA;
@dynamic propB;
@dynamic propC;
@dynamic propD;
@dynamic strE;
@dynamic strF;

@end

@implementation ClassPropModel

@dynamic sharedName;
@dynamic sharedCopy;
@dynamic sharedCount;
@dynamic sharedWeak;
@dynamic sharedReadonly;

@end
