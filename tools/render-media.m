#import <UIKit/UIKit.h>
#import "Core/traffic-bubble-view.h"
#import "Core/road-signs.h"
#import "Tweak/traffic-bubble-layout-store.h"

// The page's pictures, drawn by Lề's own code (the bubble view and the road-sign painter), so the site shows
// exactly what the tweak draws. Usage: render-media <out-dir>. See render-media.sh.
static NSDictionary *Group(id value) { return @{@"availability":@"available",@"value":value}; }
static NSDictionary *Sign(NSString *kind, double distance, id value, NSString *symbol) {
    NSMutableDictionary *sign=[@{@"eventID":[NSString stringWithFormat:@"%@-%.0f",kind,distance],@"kind":kind,@"distanceAlongRouteMeters":@(distance),@"signValue":value?:NSNull.null} mutableCopy];
    if(symbol) sign[@"symbol"]=symbol;
    return sign;
}
static void Write(UIImage *image, NSString *path) { [UIImagePNGRepresentation(image) writeToFile:path atomically:YES]; }
static UIColor *RGB(uint32_t hex) { return [UIColor colorWithRed:((hex>>16)&255)/255.0 green:((hex>>8)&255)/255.0 blue:(hex&255)/255.0 alpha:1]; }

// The hero: a night map filling the lower part, its top edge the horizon, the bubble (Lề đứng, the standing
// column) on it in the middle.
static void Hero(NSString *out) {
    const CGSize area={1440,810};const CGFloat horizon=380;
    NSArray *lanes=@[@[@"straight"],@[@"straight"],@[@"straight",@"right"],@[@"right"]];
    NSMutableArray *items=[NSMutableArray array];
    for(NSUInteger i=0;i<lanes.count;i++) [items addObject:@{@"directions":lanes[i],@"recommended":i<3?@YES:@NO}];
    NSArray *road=@[Sign(@"no-passing",0,nil,@"no_passing_in"),Sign(@"camera",81,nil,@"traffic_camera"),Sign(@"speed-limit",146,@60,nil),Sign(@"restriction",420,nil,@"noLeftTurn")];
    NSDictionary *groups=@{@"speed":Group(@{@"currentSpeedMps":@(47/3.6)}),@"limit":Group(@{@"speedLimitKph":@50}),
        @"lanes":Group(@{@"distanceMeters":@252,@"items":items}),@"alerts":Group(road)};
    NSMutableArray *modules=[NSMutableArray array];
    for(NSString *module in CWTrafficBubbleModuleIDs()) [modules addObject:@{@"id":module,@"enabled":@YES}];
    CWTrafficBubbleView *view=[[CWTrafficBubbleView alloc] initWithFrame:CGRectMake(0,0,240,200)];
    view.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    view.layoutConfig=@{@"schemaVersion":@1,@"arrangement":@"side",@"modules":modules,@"background":@"asphalt",@"backgroundOpacity":@.94};
    [view displaySnapshot:@{@"groups":groups} source:@"vietmap-live"];
    CGSize size=view.designSize;view.bounds=CGRectMake(0,0,size.width,size.height);
    [view setNeedsLayout];[view layoutIfNeeded];
    for(UIView *child in view.subviews) { child.layer.contentsScale=2;[child.layer setNeedsDisplay];[child.layer displayIfNeeded]; }
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat preferredFormat];format.scale=2;format.opaque=NO;
    UIImage *image=[[[UIGraphicsImageRenderer alloc] initWithSize:area format:format] imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        CGFloat h=area.height-horizon;
        [RGB(0x1f2836) setFill];UIRectFill(CGRectMake(0,horizon,area.width,h));
        [RGB(0x253041) setFill];
        for(CGFloat x=-20;x<area.width;x+=88) for(CGFloat y=horizon-30;y<area.height;y+=78) UIRectFill(CGRectIntersection(CGRectMake(x+7,y+7,74,64),CGRectMake(0,horizon,area.width,h)));
        [RGB(0x354153) setFill];
        for(CGFloat x=-20;x<area.width;x+=88) UIRectFill(CGRectMake(x-4,horizon,8,h));
        for(CGFloat y=horizon-30;y<area.height;y+=78) if(y-4>=horizon) UIRectFill(CGRectMake(0,y-4,area.width,8));
        UIBezierPath *hwy=[UIBezierPath bezierPath];[hwy moveToPoint:CGPointMake(-20,790)];
        [hwy addCurveToPoint:CGPointMake(1460,470) controlPoint1:CGPointMake(420,720) controlPoint2:CGPointMake(900,430)];
        hwy.lineWidth=13;[RGB(0x5f5948) setStroke];[hwy stroke];
        UIBezierPath *route=[UIBezierPath bezierPath];[route moveToPoint:CGPointMake(608,810)];[route addLineToPoint:CGPointMake(608,604)];
        [route addQuadCurveToPoint:CGPointMake(624,588) controlPoint:CGPointMake(608,588)];[route addLineToPoint:CGPointMake(1460,588)];
        route.lineWidth=9;route.lineJoinStyle=kCGLineJoinRound;[RGB(0x5b9bff) setStroke];[route stroke];
        CGContextRef c=UIGraphicsGetCurrentContext();CGContextSaveGState(c);
        CGContextTranslateCTM(c,round(area.width/2-size.width/2),horizon+12);
        [view.layer renderInContext:c];
        CGContextRestoreGState(c);
    }];
    Write(image,[out stringByAppendingPathComponent:@"hero.png"]);
    printf("hero %.0fx%.0f, bubble %.0fx%.0f at x %.0f\n",area.width*2,area.height*2,size.width,size.height,round(area.width/2-size.width/2));
}


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
    Hero(out);
    // Every sign the search answers with, at 120 pt (240 px).
    NSMutableArray *names=[NSMutableArray array];
    for(NSString *name in CWRoadSignNames()) if(![name isEqual:@"khu_dan_cu"]) [names addObject:name];
    for(int limit=5;limit<=150;limit+=5) [names addObject:[NSString stringWithFormat:@"speed_limit_%d",limit]];
    for(NSString *name in names) Write(SignImage(name,120,nil),[signs stringByAppendingPathComponent:[name stringByAppendingString:@".png"]]);
    printf("signs %lu\n",(unsigned long)names.count);
    // The strip for the headline's moving slot: signs passing by on asphalt, the first three again at the end so
    // the loop joins. 100 pt signs, 40 pt apart, 120 pt tall.
    NSArray *row=@[@"speed_limit_50",@"no_passing_in",@"traffic_camera",@"noLeftTurn",@"residential_area_in",@"speed_limit_80",
        @"straightAndRightTurnOnly",@"railway",@"toll_etc",@"noUTurnLeft",@"camera_ai",@"slow_down",@"tunnel",@"speed_limit_60"];
    NSMutableArray *loop=[row mutableCopy];[loop addObjectsFromArray:[row subarrayWithRange:NSMakeRange(0,4)]];
    CGFloat pitch=140,height=120;
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat preferredFormat];format.scale=2;format.opaque=YES;
    UIImage *strip=[[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(loop.count*pitch,height) format:format] imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        [RGB(0x121315) setFill];UIRectFill(CGRectMake(0,0,loop.count*pitch,height));
        for(NSUInteger i=0;i<loop.count;i++) CWDrawRoadSign(loop[i],CGRectMake(i*pitch+20,10,100,100));
    }];
    Write(strip,[out stringByAppendingPathComponent:@"strip.png"]);
    printf("strip %lu signs, period %.0f pt\n",(unsigned long)loop.count,row.count*pitch);
    return 0;
} }
