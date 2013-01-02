//
//  ViewController.m
//  mrender
//
//  Created by Dane Springmeyer on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

#pragma mark - View lifecycle


- (void)updateMethod:(NSTimer *)theTimer
{
    try {
        // set up renderable image and map canvas
        mapnik::image_32 im(960,640);
        mapnik::Map m(im.width(),im.height());
        NSString *style_path = [[NSBundle mainBundle]
                                   pathForResource:@"style"
                                   ofType:@"xml"];
        
        NSString *style = [NSString stringWithContentsOfFile:style_path encoding:NSUTF8StringEncoding error:nil];
        style = [style stringByReplacingOccurrencesOfString:@"RESOURCE_PATH" withString:[NSBundle mainBundle].resourcePath];
        mapnik::load_map_string(m, std::string(style.UTF8String));

        m.zoom_all();

        mapnik::agg_renderer<mapnik::image_32> ren(m,im);
        ren.apply();
        
        // convert mapnik image to UIImage - there must be a better way...
        // https://github.com/PaulSolt/UIImage-Conversion/blob/master/ImageHelper.m
        size_t im_size = im.width() * im.height() * 4;
        size_t bitsPerComponent = 8;
        size_t bitsPerPixel = 32;
        size_t bytesPerRow = 4 * im.width();
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, im.raw_data(), im_size, NULL);
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        CGImageRef iref = CGImageCreate(im.width(), im.height(),
                                        bitsPerComponent, bitsPerPixel, bytesPerRow, 
                                        colorSpaceRef, bitmapInfo, provider,
                                        NULL, YES, renderingIntent);
        CGContextRef context = CGBitmapContextCreate(im.raw_data(), im.width(), im.height(), 
                                                     bitsPerComponent, bytesPerRow, colorSpaceRef, bitmapInfo);
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, im.width(), im.height()), iref);
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
		UIImage *image = nil;
		if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
			float scale = [[UIScreen mainScreen] scale];
			image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
		} else {
			image = [UIImage imageWithCGImage:imageRef];
		}
        // cleanup
		CGImageRelease(imageRef);	
		CGContextRelease(context);	
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        CGDataProviderRelease(provider);
        NSLog(@"resultImg width:%f, height:%f",image.size.width,image.size.height);
        
        // push UIImage into view
        UIImageView *imageView = [[UIImageView alloc] initWithImage: image]; 
        [self.view addSubview: imageView]; 
    }
    catch (std::exception const& ex)
    {
        NSLog(@"error: %s",ex.what());    
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateMethod:)
                                   userInfo:nil
                                    repeats:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}


@end