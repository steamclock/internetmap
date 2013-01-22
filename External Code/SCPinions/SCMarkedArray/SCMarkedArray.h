//
//  SCMarkedArray.h
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

// A subclass of NSMutable array that maintains a set of indices into the array that are updated when the array
// is changed, to simplify tracking positions in arrays that are being modified

#import <Foundation/Foundation.h>

typedef NSInteger SCMarkedArrayMarker;

// Behaviour bitmask controls some aspects of marker behaviour, NOTE: not all combinations are valid
// You can't have both shift up and shift down, and you can't have shift down without clamping except in
// single marker mode (due to markers at -1 being represented as NSNotFound, which doesn't work in
// multiple index mode)

typedef enum {
    // Only zero or one markers are allowed, setMarker implicitly removes any previous value
    // (default is to allow multiple markers of same type)
    kSCMarkedArraySingleMarker = 0x1,
    
    // When element with marker on it is deleted marker moves to previous element (i.e. the index is decrimented). Default is to remove marker. If
    // in single marker mode, and unclamped an index of 0 will become NSNotFound if shifted down.
    kSCMarkedArrayShiftDownWhenDeleted = 0x2,
    
    // When element with marker on it is deleted marker moves to next item (i.e. the index stays the same, so it now points to what was the next element.
    kSCMarkedArrayShiftUpWhenDeleted = 0x4,
    
    // Marker is constrained to valid array value (default is to let shift down or shift up potentially move the
    // marker off array). Note, clamping will be violated for empty array (all active markers will
    // be NSNotFound, though that isn't in array)
    kSCMarkedArrayClamp = 0x8
    
} SCMarkedArrayBehaviour;

@interface SCMarkedArray : NSMutableArray

// Create a new empty marker
-(SCMarkedArrayMarker)createMarkerWithBehaviour:(int)behaviourMask;

// Create a new marker at an initial index
-(SCMarkedArrayMarker)createMarkerAtIndex:(NSUInteger)index behaviour:(int)behaviourMask;

// Add an index for the marker
-(void)setMarker:(SCMarkedArrayMarker)marker atIndex:(NSUInteger)index;

// Remove a marker on a given index
-(void)clearMarker:(SCMarkedArrayMarker)marker atIndex:(NSUInteger)index;

// Clear all of a specified type of marker
-(void)clearMarker:(SCMarkedArrayMarker)marker;

// Get the position of a specified marker, If marker has multiple indexes the first will be returned, if no marker
// NSNotFound will be returned
-(NSUInteger)getMarkerIndex:(SCMarkedArrayMarker)marker;

// Get all indices for a specified marker
-(NSIndexSet*)getMarkerIndexSet:(SCMarkedArrayMarker)marker;

@end
