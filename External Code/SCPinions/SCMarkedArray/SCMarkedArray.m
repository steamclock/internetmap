//
//  SCMarkedArray.m
//
// -- Software License --
//
// Copyright (C) 2013, Steam Clock Software, Ltd.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// ----------------------

#import "SCMarkedArray.h"

@interface SCArrayMarker : NSObject {
    @public
    int _behaviour;
    NSMutableIndexSet* _indices;
}
@end

@implementation SCArrayMarker

-(id)init {
    if ((self = [super init])) {
        _indices = [NSMutableIndexSet new];
    }
    
    return self;    
}

@end

@interface SCMarkedArray () {
    __strong NSMutableArray* _backingStore;
    __strong NSMutableArray* _markers;
}

@end

@implementation SCMarkedArray

#pragma mark Lifetime
- (id) init {
    if ((self = [super init])) {
        _backingStore = [NSMutableArray new];
        _markers = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark NSArray implimentation

-(NSUInteger)count {
    return [_backingStore count];
}

-(id)objectAtIndex:(NSUInteger)index {
    return [_backingStore objectAtIndex:index];
}

#pragma mark NSMutableArray implimentation

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index {
    [_backingStore insertObject:anObject atIndex:index];
    [self insertedIndex:index];
}

-(void)removeObjectAtIndex:(NSUInteger)index {
    [_backingStore removeObjectAtIndex:index];
    [self removedIndex:index];
}

-(void)addObject:(id)anObject {
    [_backingStore addObject:anObject];
    // Note: no marker update, adding to end can never move amarker
}

-(void)removeLastObject {
    [_backingStore removeLastObject];
    [self removedIndex:[self count]];
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    [_backingStore replaceObjectAtIndex:index withObject:anObject];
    // Note: no marker update
}

#pragma mark SCMarkedArray interface

-(SCMarkedArrayMarker)createMarkerWithBehaviour:(int)behaviourMask {
    NSAssert(!(behaviourMask & kSCMarkedArrayShiftDownWhenDeleted) || !(behaviourMask & kSCMarkedArrayShiftUpWhenDeleted), @"NSMarkedArray Can't have both shift up and shift down enabled");
    NSAssert((behaviourMask & kSCMarkedArraySingleMarker) || (behaviourMask & kSCMarkedArrayClamp) || !(behaviourMask & kSCMarkedArrayShiftDownWhenDeleted), @"NSMarkedArray Can't have multiple marker and shift down enabled while clamping, behaviour on deleting index 0 would be undefined");
    
    SCArrayMarker* marker = [SCArrayMarker new];
    marker->_behaviour = behaviourMask;
    [_markers addObject:marker];
    return [_markers count] - 1;
}

-(SCMarkedArrayMarker)createMarkerAtIndex:(NSUInteger)index behaviour:(int)behaviourMask {
    NSAssert(!(behaviourMask & kSCMarkedArrayShiftDownWhenDeleted) || !(behaviourMask & kSCMarkedArrayShiftUpWhenDeleted), @"NSMarkedArray Can't have both shift up and shift down enabled");
    NSAssert((behaviourMask & kSCMarkedArraySingleMarker) || (behaviourMask & kSCMarkedArrayClamp) || !(behaviourMask & kSCMarkedArrayShiftDownWhenDeleted), @"NSMarkedArray Can't have multiple marker and shift down enabled while clamping, behaviour on deleting index 0 would be undefined");
    
    SCArrayMarker* marker = [SCArrayMarker new];
    marker->_behaviour = behaviourMask;
    
    if(index != NSNotFound) {
        [marker->_indices addIndex:index];
    }
    
    [_markers addObject:marker];
    return [_markers count] - 1;
}

-(void)setMarker:(SCMarkedArrayMarker)marker atIndex:(NSUInteger)index {
    if(marker >= [_markers count]) {
        return;
    }
    
    SCArrayMarker* markerObject = [_markers objectAtIndex:marker];
    
    if(markerObject->_behaviour & kSCMarkedArraySingleMarker) {
        [markerObject->_indices removeAllIndexes];
    }
    
    if(index == NSNotFound) {
        return;
    }
    
    [markerObject->_indices addIndex:index];
}

-(void)clearMarker:(SCMarkedArrayMarker)marker atIndex:(NSUInteger)index {
    if(marker >= [_markers count]) {
        return;
    }
    
    SCArrayMarker* markerObject = [_markers objectAtIndex:marker];
    [markerObject->_indices removeIndex:index];
}

-(void)clearMarker:(SCMarkedArrayMarker)marker {
    if(marker >= [_markers count]) {
        return;
    }
    
    SCArrayMarker* markerObject = [_markers objectAtIndex:marker];
    [markerObject->_indices removeAllIndexes];
}

-(NSUInteger)getMarkerIndex:(SCMarkedArrayMarker)marker {
    if(marker >= [_markers count]) {
        return NSNotFound;
    }
    
    SCArrayMarker* markerObject = [_markers objectAtIndex:marker];
    return [markerObject->_indices firstIndex];
}

-(NSIndexSet*)getMarkerIndexSet:(SCMarkedArrayMarker)marker {
    if(marker >= [_markers count]) {
        return nil;
    }
    
    SCArrayMarker* markerObject = [_markers objectAtIndex:marker];
    return markerObject->_indices;
}

#pragma mark SCMarkedArray helpers

-(void)insertedIndex:(NSUInteger)index {
    if(index == NSNotFound) {
        return;
    }
    
    for(SCArrayMarker* marker in _markers) {
        [marker->_indices shiftIndexesStartingAtIndex:index by:1];
    }
}

-(void)removedIndex:(NSUInteger)index {
    if(index == NSNotFound) {
        return;
    }
    
    for(SCArrayMarker* marker in _markers) {
        NSMutableIndexSet* indices = marker->_indices;
        int behaviour = marker->_behaviour;
        
        BOOL removedWasMarked = [indices containsIndex:index];
        
        // This implicitly removes 'index' from the set
        [indices shiftIndexesStartingAtIndex:index + 1 by:-1];
        
        if(removedWasMarked) {
            NSUInteger count = [_backingStore count];
            if(behaviour & kSCMarkedArrayShiftDownWhenDeleted) {
                if ((behaviour & kSCMarkedArrayClamp) && (index == 0) && (count != 0)) {
                    [indices addIndex:0];
                }
                else {
                    // If index == 0 in this case, it would go to -1, which we represent with
                    // NSNotFound, so we just don't add that index again. Not safe for multiple
                    // indecies, but there is an assert when setting the bhaviour that should
                    // disallow that
                    if(index != 0) {
                        [indices addIndex:index-1];
                    }
                }
            } else if (behaviour & kSCMarkedArrayShiftUpWhenDeleted) {
                if ((behaviour & kSCMarkedArrayClamp) && (index == count) && (count != 0)) {
                    [indices addIndex:count-1];
                }
                else {
                    [indices addIndex:index];
                }
            }
        }
    }    
}
@end
