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
                NSString* textureRect = [pngDict objectForKey:@"textureRect"];
                NSMutableString* trimmedTR = [NSMutableString string];
                for ( int ii=0 ; ii<textureRect.length ; ii++ ) {
                    unsigned short unichar = [textureRect characterAtIndex:ii];
                    if ( unichar == '}' || unichar == '{' || unichar == ' ') {
                        continue;
                    }
                    [trimmedTR appendString:[NSString stringWithFormat:@"%C", unichar]];
                }
                NSArray* rStr = [trimmedTR componentsSeparatedByString:@","];
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

                NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", keys]];
                [UIImagePNGRepresentation(tmpImage) writeToFile:pngPath atomically:YES];
            }
        }
    }
    NSLog(@"End");

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

@end
