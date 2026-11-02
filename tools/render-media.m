#import <UIKit/UIKit.h>
#import "Core/road-signs.h"

// The sign search's pictures, drawn by Lề's own road-sign painter, so the page shows exactly what the tweak
// draws. The page's CarPlay pictures are captures from a device, not drawings. Usage: render-media <out-dir>.
static void Write(UIImage *image, NSString *path) { [UIImagePNGRepresentation(image) writeToFile:path atomically:YES]; }

static UIImage *SignImage(NSString *name, CGFloat side, UIColor *ground) {
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat preferredFormat];format.scale=2;format.opaque=ground!=nil;
    return [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side,side) format:format] imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        if(ground) { [ground setFill];UIRectFill(CGRectMake(0,0,side,side)); }
        CWDrawRoadSign(name,CGRectMake(0,0,side,side));
    }];
}

int main(int argc, char **argv) { @autoreleasepool {
    if(argc<2) return 2;
    NSString *out=@(argv[1]),*signs=[out stringByAppendingPathComponent:@"signs"];
    [NSFileManager.defaultManager createDirectoryAtPath:signs withIntermediateDirectories:YES attributes:nil error:nil];
    // Every sign the search answers with, at 120 pt (240 px).
    NSMutableArray *names=[NSMutableArray array];
    for(NSString *name in CWRoadSignNames()) if(![name isEqual:@"khu_dan_cu"]) [names addObject:name];
    for(int limit=5;limit<=150;limit+=5) [names addObject:[NSString stringWithFormat:@"speed_limit_%d",limit]];
    for(NSString *name in names) Write(SignImage(name,120,nil),[signs stringByAppendingPathComponent:[name stringByAppendingString:@".png"]]);
    printf("signs %lu\n",(unsigned long)names.count);
    return 0;
} }
