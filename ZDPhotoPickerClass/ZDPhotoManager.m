//
//  ZDPhotoManager.m
//  ZDPhotoPicker
//
//  Created by 符现超 on 16/1/27.
//  Copyright © 2016年 Zero.D.Bourne. All rights reserved.
//  

#import "ZDPhotoManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "ZDDefines.h"
#import "ZDAssetModel.h"

@interface ZDPhotoManager ()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@end

@implementation ZDPhotoManager


#pragma mark - Public Method

+ (instancetype)manager {
    static ZDPhotoManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ZDPhotoManager alloc] init];
    });
    return manager;
}

- (void)getAllAlbum:(BOOL)allowPickingVideo completionL:(void(^)(ZDAlbumModel *albumModel))completion {
    if (iOS8Later) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
        }
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHFetchResult *assetCollectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in assetCollectionResult) {
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"]) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
                ZDAlbumModel *model = [self modelWithResult:fetchResult name:collection.localizedTitle];
                if (completion && model) {
                    completion(model);
                }
            }
        }
    } else {
        __weak __typeof(&*self)weakSelf = self;
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            __strong __typeof(*&weakSelf)self = weakSelf;
            ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
            [group setAssetsFilter:onlyPhotosFilter];
            
            if ([group numberOfAssets] <= 0) return;
            NSString *propertyName = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([propertyName isEqualToString:@"Camera Roll"] || [propertyName isEqualToString:@"相机胶卷"]) {
                ZDAlbumModel *model = [self modelWithResult:group name:propertyName];
                if (completion && model) {
                    completion(model);
                }
                *stop = YES;
            }
        } failureBlock:^(NSError *error) {
            if (error) {
                NSLog(@"错误信息--->: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)getAllAlbums:(BOOL)allowPickingVideo completionL:(void(^)(NSArray <ZDAlbumModel *> *albumModel))completion {
    NSMutableArray *albumArr = [NSMutableArray array];
    if (iOS8Later) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
        }
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumVideos;
        if (iOS9Later) {
            smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits | PHAssetCollectionSubtypeSmartAlbumVideos;
        }
        PHFetchResult *assetCollectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
        for (PHAssetCollection *collection in assetCollectionResult) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle containsString:@"Deleted"]) continue;
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:0];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        for (PHAssetCollection *collection in albums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle isEqualToString:@"My Photo Stream"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:1];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        if (completion && albumArr.count > 0) {
            completion(albumArr);
        }
    } else {
        __weak __typeof(&*self)weakSelf = self;
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            __strong __typeof(*&weakSelf)self = weakSelf;
            if (!group) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) return;
            
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:1];
            } else {
                [albumArr addObject:[self modelWithResult:group name:name]];
            }
        } failureBlock:^(NSError *error) {
            if (error) {
                NSLog(@"错误信息--->: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(NSArray<ZDAssetModel *> *))completion {
    NSMutableArray *photoArr = [NSMutableArray array];
    if ([result isKindOfClass:NSClassFromString(@"PHFetchResult")]) {
        if (iOS8Later) {
            PHFetchResult *fetchResult = (PHFetchResult *)result;
            __weak __typeof(&*self)weakSelf = self;
            [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                __strong __typeof(*&weakSelf)self = weakSelf;
                PHAsset *asset = (PHAsset *)obj;
                ZDAssetModelMediaType type = ZDAssetModelMediaTypePhoto;
                if (asset.mediaType == PHAssetMediaTypeVideo)      type = ZDAssetModelMediaTypeVideo;
                else if (asset.mediaType == PHAssetMediaTypeAudio) type = ZDAssetModelMediaTypeAudio;
                else if (asset.mediaType == PHAssetMediaTypeImage) {
                    if (iOS9_1Later) {
                        // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = ZDAssetModelMediaTypeLivePhoto;
                    }
                }
                NSString *timeLength = (type == ZDAssetModelMediaTypeVideo) ? [NSString stringWithFormat:@"%0.0f", asset.duration] : @"";
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                [photoArr addObject:[ZDAssetModel modelWithAsset:asset type:type timeLength:timeLength]];
            }];
            if (completion && photoArr) {
                completion(photoArr);
            }
        }
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        if (!allowPickingVideo) {
            [gruop setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        [gruop enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result == nil) {
                if (completion) completion(photoArr);
            }
            ZDAssetModelMediaType type = ZDAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                [photoArr addObject:[ZDAssetModel modelWithAsset:result type:type]];
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = ZDAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f", duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                [photoArr addObject:[ZDAssetModel modelWithAsset:result type:type timeLength:timeLength]];
            } else {
                [photoArr addObject:[ZDAssetModel modelWithAsset:result type:type]];
            }
        }];
    }
}

///  Get asset at index 获得下标为index的单个照片
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(ZDAssetModel *))completion {
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        PHAsset *asset = fetchResult[index];
        
        ZDAssetModelMediaType type = ZDAssetModelMediaTypePhoto;
        if (asset.mediaType == PHAssetMediaTypeVideo)      type = ZDAssetModelMediaTypeVideo;
        else if (asset.mediaType == PHAssetMediaTypeAudio) type = ZDAssetModelMediaTypeAudio;
        else if (asset.mediaType == PHAssetMediaTypeImage) {
            if (iOS9_1Later) {
                // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = ZDAssetModelMediaTypeLivePhoto;
            }
        }
        NSString *timeLength = type == ZDAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
        timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
        ZDAssetModel *model = [ZDAssetModel modelWithAsset:asset type:type timeLength:timeLength];
        if (completion && model) {
            completion(model);
        }
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        if (!allowPickingVideo) {
            [gruop setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [gruop enumerateAssetsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            ZDAssetModel *model;
            ZDAssetModelMediaType type = ZDAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                model = [ZDAssetModel modelWithAsset:result type:type];
                if (completion) completion(model);
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = ZDAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                model = [ZDAssetModel modelWithAsset:result type:type timeLength:timeLength];
            } else {
                model = [ZDAssetModel modelWithAsset:result type:type];
            }
            if (completion && model) {
                completion(model);
            }
        }];
    }
}

/// 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion {
    __block NSInteger dataLength = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        ZDAssetModel *model = photos[i];
        if ([model.asset isKindOfClass:NSClassFromString(@"PHAsset")]) {
            if (iOS8Later) {
                __weak __typeof(&*self)weakSelf = self;
                [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    __strong __typeof(*&weakSelf)self = weakSelf;
                    if (model.type != ZDAssetModelMediaTypeVideo) {
                        dataLength += imageData.length;
                    }
                    if (i >= photos.count - 1) {
                        NSString *bytes = [self getBytesFromDataLength:dataLength];
                        if (completion && bytes) {
                            completion(bytes);
                        }
                    }
                }];
            }
        } else if ([model.asset isKindOfClass:[ALAsset class]]) {
            ALAssetRepresentation *representation = [model.asset defaultRepresentation];
            if (model.type != ZDAssetModelMediaTypeVideo) dataLength += (NSInteger)representation.size;
            if (i >= photos.count - 1) {
                NSString *bytes = [self getBytesFromDataLength:dataLength];
                if (completion && bytes) {
                    completion(bytes);
                }
            }
        }
    }
}

/// Get photo 获得照片本身
- (void)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    [self getPhotoWithAsset:asset
                 photoWidth:[UIScreen mainScreen].bounds.size.width
                 completion:completion];
}

- (void)getPhotoWithAsset:(id)asset
               photoWidth:(CGFloat)photoWidth
               completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat pixelWidth = photoWidth * scale;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(pixelWidth, pixelHeight)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:nil
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined) {
                if (completion) {
                    completion(result, info, [[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                }
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;
        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:1.0 orientation:UIImageOrientationUp];
        if (completion) completion(thumbnailImage,nil,YES);
        
        if (photoWidth == [UIScreen mainScreen].bounds.size.width) {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:1.0 orientation:UIImageOrientationUp];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(fullScrennImage, nil, NO);
                });
            });
        }
    }
}

- (void)getPostImageWithAlbumModel:(ZDAlbumModel *)model completion:(void (^)(UIImage *))completion {
    if (iOS8Later) {
        [[ZDPhotoManager manager] getPhotoWithAsset:[model.result lastObject] photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (completion) {
                completion(photo);
            }
        }];
    } else {
        ALAssetsGroup *gruop = model.result;
        UIImage *postImage = [UIImage imageWithCGImage:gruop.posterImage];
        if (completion) {
            completion(postImage);
        }
    }
}

//获取视频
- (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (completion) completion(playerItem,info);
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (completion && playerItem) completion(playerItem,nil);
    }
}

#pragma mark - Private Method

- (ZDAlbumModel *)modelWithResult:(id)result name:(NSString *)name {
    ZDAlbumModel *model = [[ZDAlbumModel alloc] init];
    model.result = result;
    model.name = [self getNewAlbumName:name];
    if ([result isKindOfClass:NSClassFromString(@"PHFetchResult")]) {
        if (iOS8Later) {
            PHFetchResult *fetchResult = (PHFetchResult *)result;
            model.count = fetchResult.count;
        }
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        model.count = [gruop numberOfAssets];
    }
    return model;
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd", duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd", duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd", min, sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd", min, sec];
        }
    }
    return newTime;
}

- (NSString *)getBytesFromDataLength:(NSUInteger)dataLength {
    NSString *bytes;
    if (dataLength >= (0.1 * (1024 * 1024))) {
        bytes = [NSString stringWithFormat:@"%0.1fM", dataLength / 1024 / 1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK", dataLength / 1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB", dataLength];
    }
    return bytes;
}

- (NSString *)getNewAlbumName:(NSString *)name {
    if (iOS8Later) {
        NSString *newName;
        if ([name containsString:@"Roll"])         newName = @"相机胶卷";
        else if ([name containsString:@"Stream"])  newName = @"我的照片流";
        else if ([name containsString:@"Added"])   newName = @"最近添加";
        else if ([name containsString:@"Selfies"]) newName = @"自拍";
        else if ([name containsString:@"shots"])   newName = @"截屏";
        else if ([name containsString:@"Videos"])  newName = @"视频";
        else newName = name;
        return newName;
    } else {
        return name;
    }
}

#pragma mark - Property

- (ALAssetsLibrary *)assetsLibrary
{
    if (!_assetsLibrary) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetsLibrary;
}

@end





























