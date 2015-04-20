//
//  EXPMatchers+FBSnapshotTestExtensions.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/14/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "EXPMatchers+FBSnapshotTestExtensions.h"
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "SLKUIConstants.h"

static NSFileManager *_fileManager = nil;

NSString *_densitySuffix() {
    
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale > 2.0) {
        return @"@3x";
    }
    else if (scale == 2.0) {
        return @"@2x";
    }
    return @"";
}

NSString *_deviceSuffix() {
    
    NSMutableArray *strings = [NSMutableArray new];
    
    if (SLK_IS_IPHONE4) {
        [strings addObject:@"iphone4"];
    }
    else if (SLK_IS_IPHONE5) {
        [strings addObject:@"iphone5"];
    }
    else if (SLK_IS_IPHONE6) {
        [strings addObject:@"iphone6"];
    }
    else if (SLK_IS_IPHONE6PLUS) {
        [strings addObject:@"iphone6plus"];
    }
    else if (SLK_IS_IPAD) {
        [strings addObject:@"ipad"];
    }
    
    if (SLK_IS_LANDSCAPE) {
        [strings addObject:@"lanscape"];
    }
    else {
        [strings addObject:@"portrait"];
    }
    
    [strings addObject:[NSString stringWithFormat:@"ios%@", [UIDevice currentDevice].systemVersion]];
    
    NSMutableString *suffix = [[strings componentsJoinedByString:@" "] mutableCopy];
    [suffix insertString:@" " atIndex:0];
    
    return suffix;
}

NSString *_specName(NSString *name) {
    
    NSMutableString *specName = [NSMutableString stringWithString:name];
    [specName appendString:_deviceSuffix()];
    
    return [specName lowercaseString];
}

NSString *_imagePathForTestSpec(NSString *test, NSString *spec) {
    
    NSMutableArray *pathComponents = [[test componentsSeparatedByString:@"/"] mutableCopy];
    
    NSString *folderName = [NSString stringWithFormat:@"%@Spec", [[pathComponents lastObject] stringByDeletingPathExtension]];
    
    [pathComponents removeObjectsInRange:NSMakeRange([pathComponents count]-2, 2)];
    [pathComponents addObject:@"ReferenceImages"];
    
    NSString *path = [pathComponents componentsJoinedByString:@"/"];
    NSString *specName = [_specName(spec) stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    return [NSString stringWithFormat:@"%@/%@/%@%@.png", path, folderName, specName, _densitySuffix()];
}

void _itTestsOrRecords(id self, int lineNumber, const char *fileName, BOOL asynch, BOOL record, NSString *spec, id (^block)()) {

    void (^snapshot)(id, NSString *) = ^void(id sut, NSString *specName) {
        
        EXPExpect *expectation = _EXP_expect(self, lineNumber, fileName, ^id{ return EXPObjectify((sut)); });
        
        if (record) {
            if (asynch) expectation.will.recordSnapshotNamed(specName);
            else expectation.to.recordSnapshotNamed(specName);
        }
        else {
            if (asynch) expectation.will.haveValidSnapshotNamed(specName);
            else expectation.to.haveValidSnapshotNamed(specName);
        }
    };
    
    NSString *specName = _specName(spec);
    
    it(specName, ^{
        id sut = block();
        snapshot(sut, [specName stringByReplacingOccurrencesOfString:@" " withString:@"_"]);
    });
}

void _itTests(id self, int lineNumber, const char *fileName, BOOL asynch, NSString *spec, id (^block)()) {
    
    if (!_fileManager) {
        _fileManager = [[NSFileManager alloc] init];
    }

    NSString *imagePath = _imagePathForTestSpec([NSString stringWithUTF8String:fileName], spec);
    
    BOOL record = ![_fileManager fileExistsAtPath:imagePath];
    
    _itTestsOrRecords(self, lineNumber, fileName, asynch, record, spec, block);
}