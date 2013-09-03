// UIProgressView+AFNetworking.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UIProgressView+AFNetworking.h"

#import "AFURLConnectionOperation.h"

#import <objc/runtime.h>

static void * AFTaskStateChangedContext = &AFTaskStateChangedContext;
static void * AFTaskCountOfBytesChangedContext = &AFTaskCountOfBytesChangedContext;

@interface AFURLConnectionOperation (_UIProgressView)
@property (readwrite, nonatomic, copy) void (^uploadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
@property (readwrite, nonatomic, copy) void (^downloadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
@end

@implementation AFURLConnectionOperation (_UIProgressView)
@dynamic uploadProgress;
@dynamic downloadProgress;
@end

#pragma mark -

@interface UIProgressView (_AFNetworking) <NSURLSessionDownloadDelegate>
- (void)_af_observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context;
@end

@implementation UIProgressView (AFNetworking)

+ (void)load {
    Class class = [UIProgressView class];
    Method originalMethod = class_getInstanceMethod(class, @selector(observeValueForKeyPath:ofObject:change:context:));
    Method replacementMethod = class_getInstanceMethod(class, @selector(_af_observeValueForKeyPath:ofObject:change:context:));
    method_exchangeImplementations(originalMethod, replacementMethod);
}

- (void)setProgressWithUploadProgressOfTask:(NSURLSessionUploadTask *)task
                                   animated:(BOOL)animated
{
    [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:AFTaskStateChangedContext];
    [task addObserver:self forKeyPath:@"countOfBytesSent" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:AFTaskCountOfBytesChangedContext];
}

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task
                                     animated:(BOOL)animated
{
    [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:AFTaskStateChangedContext];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:AFTaskCountOfBytesChangedContext];
}

#pragma mark -

- (void)setProgressWithUploadProgressOfOperation:(AFURLConnectionOperation *)operation
                                        animated:(BOOL)animated
{
    __weak __typeof(self)weakSelf = self;
    void (^original)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected) = [operation.uploadProgress copy];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (original) {
            original(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }

        if (totalBytesExpectedToWrite > 0) {
            [weakSelf setProgress:(totalBytesWritten / (totalBytesExpectedToWrite * 1.0f)) animated:animated];
        }
    }];
}

- (void)setProgressWithDownloadProgressOfOperation:(AFURLConnectionOperation *)operation
                                          animated:(BOOL)animated
{
    __weak __typeof(self)weakSelf = self;
    void (^original)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected) = [operation.uploadProgress copy];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (original) {
            original(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        }
        
        if (totalBytesExpectedToRead > 0) {
            [weakSelf setProgress:(totalBytesRead / (totalBytesExpectedToRead  * 1.0f)) animated:animated];
        }
    }];
}

#pragma mark - NSKeyValueObserving

- (void)_af_observeValueForKeyPath:(NSString *)keyPath
                          ofObject:(id)object
                            change:(NSDictionary *)change
                           context:(void *)context
{
    [self _af_observeValueForKeyPath:keyPath ofObject:object change:change context:context];

    if ([object isKindOfClass:[NSURLSessionTask class]] && (context == AFTaskStateChangedContext || context == AFTaskCountOfBytesChangedContext)) {
        if ([keyPath isEqualToString:@"countOfBytesSent"]) {
            if ([object countOfBytesExpectedToSend] > 0) {
                self.progress = [object countOfBytesSent] / ([object countOfBytesExpectedToSend] * 1.0f);
            }
        } else if ([keyPath isEqualToString:@"countOfBytesReceived"]) {
            if ([object countOfBytesExpectedToReceive] > 0) {
                self.progress = [object countOfBytesReceived] / ([object countOfBytesExpectedToReceive] * 1.0f);
            }
        } else if ([keyPath isEqualToString:@"state"]) {
            if ([object state] == NSURLSessionTaskStateCompleted) {
                [object removeObserver:self];
            }
        }
    }
}

@end
