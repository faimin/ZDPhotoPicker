//
//  ZDDefines.h
//  ZDPhotoPicker
//
//  Created by 符现超 on 16/1/27.
//  Copyright © 2016年 Zero.D.Bourne. All rights reserved.
//

#ifndef ZDDefines_h
#define ZDDefines_h

static inline CGFloat SystemVersion() {
    return [UIDevice currentDevice].systemVersion.floatValue;
}

#define iOS7Later   (SystemVersion() >= 7.0)
#define iOS8Later   (SystemVersion() >= 8.0)
#define iOS9Later   (SystemVersion() >= 9.0)
#define iOS9_1Later (SystemVersion() >= 9.1)

#endif /* ZDDefines_h */
