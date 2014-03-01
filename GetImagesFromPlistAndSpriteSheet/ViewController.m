//
//  ViewController.m
//  GetImagesFromPlistAndSpriteSheet
//
//  Created by Timecast on 13. 10. 7..
//  Copyright (c) 2013년 Noritech. All rights reserved.
//

#import "ViewController.h"
#import "UIImage-Extensions.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self GetAllPlists];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)GetAllPlists
{
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlePath error:&error];
    NSLog(@"-----------------------files : %@", files);
    for (NSString* temp in files) {
        NSString* ext = [temp pathExtension];
        if ( [ext isEqualToString:@"plist"] ) {
            NSString* plistPath = [[NSBundle mainBundle] pathForResource:temp ofType:nil];
            NSDictionary* plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            NSDictionary* meta = [plistDict objectForKey:@"metadata"];
            if ( !meta ) continue;
            NSString* pngName = [[meta objectForKey:@"target"] objectForKey:@"coordinatesFileName"];
            NSString* sheetName;
            if (pngName) {
                sheetName = [pngName stringByAppendingPathExtension:@"png"];
            } else {
                sheetName = [meta objectForKey:@"textureFileName"];
            }
            UIImage* sheetImage = [UIImage imageNamed:sheetName];
            NSDictionary* frames = [plistDict objectForKey:@"frames"];
//            NSLog(@"frames : %@", frames);
            for (NSString* keys in frames) {
                NSDictionary* pngDict = [frames objectForKey:keys];
                NSString* textureRectStr = [pngDict objectForKey:@"textureRect"];
                NSArray* rStr = [self strToStrArray:textureRectStr];
                CGRect cropR;
                cropR.origin.x = [[rStr objectAtIndex:0] floatValue];
                cropR.origin.y = [[rStr objectAtIndex:1] floatValue];
                cropR.size.width = [[rStr objectAtIndex:2] floatValue];
                cropR.size.height = [[rStr objectAtIndex:3] floatValue];
//                NSLog(@"cropR : %f %f, %f, %f", cropR.origin.x, cropR.origin.y, cropR.size.width, cropR.size.height);
                
                // image
                UIImage* tmpImage = [self crop:cropR from:sheetImage];
//                NSLog(@"keys : %@", keys);
                BOOL isRotated = [[pngDict objectForKey:@"textureRotated"] boolValue];
                if ( isRotated ) {
                   tmpImage = [tmpImage imageRotatedByDegrees:270.0f];
                }
                
                // return trim
                NSString* spriteSourceSizeStr = [pngDict objectForKey:@"spriteSourceSize"];
                NSArray* sprSourceSize = [self strToStrArray:spriteSourceSizeStr];
                float www = [[sprSourceSize objectAtIndex:0] floatValue];
                float hhh = [[sprSourceSize objectAtIndex:1] floatValue];
                
                NSString* spriteColorRectStr = [pngDict objectForKey:@"spriteColorRect"];
                NSArray* spriteColorRectArray = [self strToStrArray:spriteColorRectStr];
                float srcX = [[spriteColorRectArray objectAtIndex:0] floatValue];
                float srcY = [[spriteColorRectArray objectAtIndex:1] floatValue];
                float srcW = [[spriteColorRectArray objectAtIndex:2] floatValue];
                float srcH = [[spriteColorRectArray objectAtIndex:3] floatValue];
                
                if ( [keys isEqualToString:@"saurianBoss_0184.png"]) {
                    NSLog(@"backsize : %f, %f", www, hhh);
                    NSLog(@"rect : %f, %f, %f, %f", srcX, srcY, srcW, srcH);
                    NSLog(@"tmpImage size : %f, %f,", tmpImage.size.width, tmpImage.size.height);

                }
                UIImage *retSourceImage = [self drawImage:tmpImage backsize:CGSizeMake(www, hhh) rect:CGRectMake(srcX, srcY, srcW, srcH)];
                if ( [keys isEqualToString:@"saurianBoss_0184.png"]) {
                    NSLog(@"retSourceImage size : %f, %f,", retSourceImage.size.width, retSourceImage.size.height);
                    
                }

                NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", keys]];
//                NSLog(@"pngPath : %@", pngPath);
                [UIImagePNGRepresentation(retSourceImage) writeToFile:pngPath atomically:YES];
            }
        }
    }
    NSLog(@"End");

}

- (NSArray*) strToStrArray:(NSString*)str {
    NSMutableString* trimmedTR = [NSMutableString string];
    for ( int ii=0 ; ii<str.length ; ii++ ) {
        unsigned short unichar = [str characterAtIndex:ii];
        if ( unichar == '}' || unichar == '{' || unichar == ' ') {
            continue;
        }
        [trimmedTR appendString:[NSString stringWithFormat:@"%C", unichar]];
    }
    NSArray* rStr = [trimmedTR componentsSeparatedByString:@","];
    return rStr;
}

- (UIImage *)crop:(CGRect)rect from:(UIImage*)srcImage{
    
    rect = CGRectMake(rect.origin.x,
                      rect.origin.y,
                      rect.size.width,
                      rect.size.height);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([srcImage CGImage], rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef
                                          scale:srcImage.scale
                                    orientation:srcImage.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

-(UIImage *)drawImage:(UIImage *)frontImage backsize:(CGSize)backsize rect:(CGRect)rect
{
    UIGraphicsBeginImageContext(backsize);
    [frontImage drawInRect:rect];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}


@end
