//
//  ZDAssetModel.h
//  ZDPhotoPicker
//
//  Created by 符现超 on 16/1/27.
//  Copyright © 2016年 Zero.D.Bourne. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ZDAssetModelMediaType) {
    ZDAssetModelMediaTypePhoto = 0,
    ZDAssetModelMediaTypeLivePhoto,
    ZDAssetModelMediaTypeVideo,
    ZDAssetModelMediaTypeAudio
};

@interface ZDAssetModel : NSObject

@property (nonatomic, strong) id asset;             ///< PHAsset or ALAsset
@property (nonatomic, assign) BOOL isSelected;      ///< The select status of a photo, default is No
@property (nonatomic, assign) ZDAssetModelMediaType type;
@property (nonatomic, copy  ) NSString *timeLength;

+ (instancetype)modelWithAsset:(id)asset
                          type:(ZDAssetModelMediaType)type;
+ (instancetype)modelWithAsset:(id)asset
                          type:(ZDAssetModelMediaType)type
                    timeLength:(NSString *)timeLength;

@end


@interface ZDAlbumModel : NSObject

@property (nonatomic, copy  ) NSString *name;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) id result;

@end