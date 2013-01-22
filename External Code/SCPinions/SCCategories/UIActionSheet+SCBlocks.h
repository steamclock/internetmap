//
//  UIActionSheet+SCBlocks.h
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

#import <Foundation/Foundation.h>

@interface UIActionSheet (SCBlocks)

// Quick creation of action sheets using blocks, inspired by UIActionSheet+MKBlockAdditons
//
// This method expects a list of pairs of button titles and blocks to be run, so that it's not dependent on a 
// block / selector callback that needs to know button ordering, for example :
//
// UIActionSheet* my sheet [UIActionSheet actionSheetWithTitle:@"Foo" dismis:^{ [self someCleanup]; } buttonsAndActions:[NSArray arrayWithObjects:
//    @"Option 1", ^{ [self doOption1] }, 
//    @"Option 2", ^{ [self doOption2] }, 
//    @"Option 3", ^{ [self doOption3] }, 
//    nil]
// ]
//
// If you want to have an optional button, set the title to [NSNull null] if the condition isn't met and that title and block 
// will be ignored but later buttons will added (if you set a title to nil, it terminates the list)
 
+(UIActionSheet*) actionSheetWithTitle:(NSString*)title 
                               dismiss:(void(^)())dismiss // called after any dismissal
                     buttonsAndActions:(NSObject*) buttonsAndActions, ...; // array of button name / block pairs 

@end
