//  Copyright (c) 2026 Andrew Kitchen
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  *    Redistributions of source code must retain the above copyright notice, this
//      list of conditions and the following disclaimer.
//  *    Redistributions in binary form must reproduce the above copyright notice,
//      this list of conditions and the following disclaimer in the documentation
//      and/or other materials provided with the distribution.
//  *    Neither the name KeyCastr nor the names of its contributors may be used to
//      endorse or promote products derived from this software without specific
//      prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "KCFontPopUpButton.h"

// Point size used to draw each family's name in its own typeface. Matches the
// system menu font so the specimen lines up with the rest of the pane.
static const CGFloat kKCFontMenuItemSize = 13.0;

@implementation KCFontPopUpButton {
    BOOL _menuBuilt;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    // -awakeFromNib is not guaranteed to be called only once for a given object,
    // and rebuilding would drop the user's selection on the floor.
    if (_menuBuilt) {
        return;
    }
    _menuBuilt = YES;

    [self buildMenu];
    [self selectStoredFamily];

    [self setTarget:self];
    [self setAction:@selector(fontFamilySelected:)];
}

- (void)buildMenu
{
    NSFontManager *fontManager = [NSFontManager sharedFontManager];

    [self removeAllItems];

    NSMenuItem *systemItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"System Font", nil)
                                                        action:NULL
                                                 keyEquivalent:@""];
    // The empty string, not nil: -stringForKey: gives back nil for a key that was
    // never written, and both need to mean "use the system font".
    [systemItem setRepresentedObject:@""];
    [[self menu] addItem:systemItem];
    [[self menu] addItem:[NSMenuItem separatorItem]];

    NSArray<NSString *> *families = [[fontManager availableFontFamilies]
        sortedArrayUsingSelector:@selector(localizedStandardCompare:)];

    for (NSString *family in families) {
        NSString *displayName = [fontManager localizedNameForFamily:family face:nil] ?: family;
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:displayName
                                                      action:NULL
                                               keyEquivalent:@""];
        [item setRepresentedObject:family];

        // Draw each family's name in that family, so the list reads as a specimen
        // sheet. Families that refuse to produce a face at this size (symbol and
        // bitmap-only fonts, mostly) keep the plain menu font.
        NSFont *sample = [fontManager fontWithFamily:family traits:0 weight:5 size:kKCFontMenuItemSize];
        if (sample != nil) {
            [item setAttributedTitle:[[NSAttributedString alloc] initWithString:displayName
                                                                    attributes:@{ NSFontAttributeName: sample }]];
        }

        [[self menu] addItem:item];
    }
}

- (void)selectStoredFamily
{
    NSString *storedFamily = [[NSUserDefaults standardUserDefaults] stringForKey:_fontFamilyDefaultsKey];
    if (storedFamily == nil) {
        storedFamily = @"";
    }

    NSInteger index = [self indexOfItemWithRepresentedObject:storedFamily];
    // A family can be uninstalled between launches. Leave the stored value alone —
    // the visualizers fall back to the system font on their own, and reinstalling
    // the font brings the old selection back.
    [self selectItemAtIndex:(index == -1 ? 0 : index)];
}

- (void)fontFamilySelected:(id)sender
{
    NSString *family = [[self selectedItem] representedObject] ?: @"";
    [[NSUserDefaults standardUserDefaults] setObject:family forKey:_fontFamilyDefaultsKey];
}

@end
