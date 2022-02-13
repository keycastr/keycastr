//    Copyright (c) 2021 Andrew Kitchen
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without modification,
//    are permitted provided that the following conditions are met:
//
//    *    Redistributions of source code must retain the above copyright notice, this
//         list of conditions and the following disclaimer.
//    *    Redistributions in binary form must reproduce the above copyright notice,
//         this list of conditions and the following disclaimer in the documentation
//         and/or other materials provided with the distribution.
//    *    Neither the name KeyCastr nor the names of its contributors may be used to
//         endorse or promote products derived from this software without specific
//         prior written permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//    IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Foundation/Foundation.h>

@class KCMouseEvent;
@class KCMouseEventVisualizer;

#pragma mark - KCMouseDisplayOptionsProvider

/// Note: this protocol exists and is implemented, but its use is being temporarily short-circuited by the `-isEnabled` flag in order to release an MVP.
@protocol KCMouseDisplayOptionsProvider <NSObject>

@property (nonatomic, strong, readonly) NSArray<NSString *> *mouseDisplayOptionNames;
@property (nonatomic, strong) NSString *currentMouseDisplayOptionName;

@end

#pragma mark - KCMouseEventVisualizerDelegate

@protocol KCMouseEventVisualizerDelegate <NSObject>

- (void)mouseEventVisualizer:(KCMouseEventVisualizer *)visualizer didNoteMouseEvent:(KCMouseEvent *)mouseEvent;

@end

#pragma mark - KCMouseEventVisualizer

@interface KCMouseEventVisualizer : NSObject <KCMouseDisplayOptionsProvider>

/// Note: this property is temporary, to be replaced in an upcoming release by the ability to display mouse clicks with the pointer, wtihin the current visualizer, or both.
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, weak) id<KCMouseEventVisualizerDelegate> delegate;

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent;

@end
