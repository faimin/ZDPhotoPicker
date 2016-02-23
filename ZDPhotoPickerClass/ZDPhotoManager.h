//
//  ZDPhotoManager.h
//  ZDPhotoPicker
//
//  Created by 符现超 on 16/1/27.
//  Copyright © 2016年 Zero.D.Bourne. All rights reserved.
//  https://developer.apple.com/library/ios/samplecode/UsingPhotosFramework/Introduction/Intro.html#//apple_ref/doc/uid/TP40014575
/**
 *  PS: 大部分代码来自TZImagePickerController:
 *  https://github.com/banchichen/TZImagePickerController
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class ZDAssetModel, ZDAlbumModel;

@interface ZDPhotoManager : NSObject

+ (instancetype)manager;

/// 获得相册
- (void)getAllAlbum:(BOOL)allowPickingVideo completionL:(void(^)(ZDAlbumModel *albumModel))completion;
- (void)getAllAlbums:(BOOL)allowPickingVideo completionL:(void(^)(NSArray <ZDAlbumModel *> *albumModel))completion;

///获得Asset数组
- (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(NSArray<ZDAssetModel *> *))completion;
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(ZDAssetModel *))completion;

/// 获得照片
- (void)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion;
- (void)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion;
- (void)getPostImageWithAlbumModel:(ZDAlbumModel *)model completion:(void (^)(UIImage *))completion;

/// 获得视频
- (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * playerItem, NSDictionary * info))completion;

/// 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion;

@end
