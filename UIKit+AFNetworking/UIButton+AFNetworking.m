// UIButton+AFNetworking.m
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

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"
#import "AFHTTPClient.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import "UIButton+AFNetworking.h"

@implementation UIButton (AFNetworking)

+ (AFHTTPClient *)af_sharedHTTPClient {
    static AFHTTPClient *_af_sharedHTTPClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedHTTPClient = [[AFHTTPClient alloc] initWithSessionConfiguration:nil]; // TODO allow anonymous HTTP clients
        _af_sharedHTTPClient.responseSerializers = @[[AFImageSerializer serializer]];
    });

    return _af_sharedHTTPClient;
}

#pragma mark -

- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
{
    [self setImageForState:state withURL:url placeholderImage:nil];
}

- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(UIImage *)placeholderImage
                 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self setImageAtKeyPath:@"image" forState:state withURLRequest:urlRequest placeholderImage:placeholderImage success:success failure:failure];
}

#pragma mark -

- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
{
    [self setBackgroundImageForState:state withURL:url placeholderImage:nil];
}

- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setBackgroundImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(UIImage *)placeholderImage
                           success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                           failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self setImageAtKeyPath:@"backgroundImage" forState:state withURLRequest:urlRequest placeholderImage:placeholderImage success:success failure:failure];
}

#pragma mark -

- (void)setImageAtKeyPath:(NSString *)keyPath
                 forState:(UIControlState)state
           withURLRequest:(NSURLRequest *)urlRequest
         placeholderImage:(UIImage *)placeholderImage
                  success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                  failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    
    [self setValue:placeholderImage forKeyPath:keyPath];

    [[[self class] af_sharedHTTPClient] runDataTaskWithRequest:urlRequest success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(urlRequest, (NSHTTPURLResponse *)task.response, responseObject);
        } else if (responseObject) {
            [self setValue:responseObject forKeyPath:keyPath];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(urlRequest, (NSHTTPURLResponse *)task.response, error);
        }
    }];
}

- (void)cancelImageDataTasks {
    [[[[self class] af_sharedHTTPClient] tasks] makeObjectsPerformSelector:@selector(cancel)];
}

@end

#endif
