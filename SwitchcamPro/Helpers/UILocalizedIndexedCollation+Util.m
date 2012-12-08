//
// Copyright 2012 Emre Berge Ergenekon
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UILocalizedIndexedCollation+Util.h"

@interface UILocalizedIndexedCollation ()

+ (void) makeSureMutableArray:(NSMutableArray *) array hasIndex:(NSInteger) index;
+ (NSMutableArray *) divideObjects:(NSArray *) objects intoSectionsUsingCollationStringSelector:(SEL) selector andCollation:(UILocalizedIndexedCollation *) collation;
+ (void) sortDividedObjects:(NSMutableArray *) dividedObjects usingCollationStringSelector:(SEL) selector andCollation:(UILocalizedIndexedCollation *) currentCollation;

@end

@implementation UILocalizedIndexedCollation (Util)

+ (NSArray *) collateObjects:(NSArray *) objects usingCollationStringSelector:(SEL) selector
{
    UILocalizedIndexedCollation *currentCollation = [UILocalizedIndexedCollation currentCollation];
    NSMutableArray *collatedObjects = [self divideObjects:objects intoSectionsUsingCollationStringSelector:selector andCollation:currentCollation];
    [self sortDividedObjects:collatedObjects usingCollationStringSelector:selector andCollation:currentCollation];
    return collatedObjects;
}

@end