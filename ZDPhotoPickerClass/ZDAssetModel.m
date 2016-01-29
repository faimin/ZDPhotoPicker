//
//  ZDAssetModel.m
//  ZDPhotoPicker
//
//  Created by 符现超 on 16/1/27.
//  Copyright © 2016年 Zero.D.Bourne. All rights reserved.
//

#import "ZDAssetModel.h"

@implementation ZDAssetModel

+ (instancetype)modelWithAsset:(id)asset
                          type:(ZDAssetModelMediaType)type
{
    ZDAssetModel *model = [[ZDAssetModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(id)asset
                          type:(ZDAssetModelMediaType)type
                    timeLength:(NSString *)timeLength
{
    ZDAssetModel *model = [[self class] modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    return model;
}

@end



@implementation ZDAlbumModel

@end
