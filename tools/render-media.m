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


// A gallery tile: the bubble in the top-right corner of a CarPlay map, 4:5, all at one scale.
static void DrawMap(CGSize area, BOOL day) {
    [RGB(day?0xeef0f3:0x1f2836) setFill];UIRectFill(CGRectMake(0,0,area.width,area.height));
    [RGB(day?0xe4e7eb:0x253041) setFill];
    for(CGFloat x=-20;x<area.width;x+=88) for(CGFloat y=-30;y<area.height;y+=78) UIRectFill(CGRectMake(x+7,y+7,74,64));
    [RGB(day?0xffffff:0x354153) setFill];
    for(CGFloat x=-20;x<area.width;x+=88) UIRectFill(CGRectMake(x-4,0,8,area.height));
    for(CGFloat y=-30;y<area.height;y+=78) UIRectFill(CGRectMake(0,y-4,area.width,8));
    UIBezierPath *hwy=[UIBezierPath bezierPath];[hwy moveToPoint:CGPointMake(-20,area.height*.8)];
    [hwy addCurveToPoint:CGPointMake(area.width+20,area.height*.42) controlPoint1:CGPointMake(area.width*.3,area.height*.72) controlPoint2:CGPointMake(area.width*.62,area.height*.4)];
    hwy.lineWidth=13;[RGB(day?0xffd773:0x5f5948) setStroke];[hwy stroke];
    UIBezierPath *route=[UIBezierPath bezierPath];[route moveToPoint:CGPointMake(area.width*.42,area.height)];
    [route addLineToPoint:CGPointMake(area.width*.42,area.height*.62)];[route addLineToPoint:CGPointMake(area.width+20,area.height*.62)];
    route.lineWidth=9;route.lineJoinStyle=kCGLineJoinRound;[RGB(day?0x1a73e8:0x5b9bff) setStroke];[route stroke];
}
static NSDictionary *Drive(double kph, double limit) {
    NSArray *lanes=@[@[@"straight"],@[@"straight"],@[@"straight",@"right"],@[@"right"]];
    NSMutableArray *items=[NSMutableArray array];
    for(NSUInteger i=0;i<lanes.count;i++) [items addObject:@{@"directions":lanes[i],@"recommended":i<3?@YES:@NO}];
    NSArray *road=@[Sign(@"no-passing",0,nil,@"no_passing_in"),Sign(@"camera",81,nil,@"traffic_camera"),Sign(@"speed-limit",146,@60,nil),Sign(@"restriction",420,nil,@"noLeftTurn")];
    return @{@"speed":Group(@{@"currentSpeedMps":@(kph/3.6)}),@"limit":Group(@{@"speedLimitKph":@(limit)}),
        @"lanes":Group(@{@"distanceMeters":@252,@"items":items}),@"alerts":Group(road)};
}
static UIImage *TileImage(NSString *arrangement, NSString *material, BOOL day, NSDictionary *groups);
static void Tile(NSString *out, NSString *name, NSString *arrangement, NSString *material, BOOL day, NSDictionary *groups) {
    Write(TileImage(arrangement,material,day,groups),[out stringByAppendingFormat:@"/tile-%@.png",name]);
    printf("tile %s\n",name.UTF8String);
}
// The Góc tile as frames of a drive: 30 km/h up to 62 and back on a 50 road, so the speed goes from paint
// to amber near the limit and to red with its excess. 15 frames a second, 8 seconds.
static void SpeedFrames(NSString *out) {
    NSString *frames=[out stringByAppendingPathComponent:@"frames"];
    [NSFileManager.defaultManager createDirectoryAtPath:frames withIntermediateDirectories:YES attributes:nil error:nil];
    for(int i=0;i<120;i++) {
        double t=i/15.0,kph;
        if(t<1) kph=30; else if(t<4) kph=30+32*(1-cos(M_PI*(t-1)/3))/2; else if(t<5.5) kph=62; else kph=62-32*(1-cos(M_PI*(t-5.5)/2.5))/2;
        Write(TileImage(@"corner",@"asphalt",NO,Drive(round(kph),50)),[frames stringByAppendingFormat:@"/%03d.png",i]);
    }
    printf("speed frames 120\n");
}
static UIImage *TileImage(NSString *arrangement, NSString *material, BOOL day, NSDictionary *groups) {
    NSMutableArray *modules=[NSMutableArray array];
    for(NSString *module in CWTrafficBubbleModuleIDs()) [modules addObject:@{@"id":module,@"enabled":@YES}];
    CWTrafficBubbleView *view=[[CWTrafficBubbleView alloc] initWithFrame:CGRectMake(0,0,240,200)];
    view.overrideUserInterfaceStyle=day?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark;
    view.layoutConfig=@{@"schemaVersion":@1,@"arrangement":arrangement,@"modules":modules,@"background":material,@"backgroundOpacity":@.94};
    [view displaySnapshot:@{@"groups":groups} source:@"vietmap-live"];
    CGSize size=view.designSize;view.bounds=CGRectMake(0,0,size.width,size.height);
    [view setNeedsLayout];[view layoutIfNeeded];
    for(UIView *child in view.subviews) { child.layer.contentsScale=2;[child.layer setNeedsDisplay];[child.layer displayIfNeeded]; }
    // Framed close round the bubble, 4:5, so each layout reads at the tile's size; 2 px a point.
    CGFloat width=MAX(size.width+72,460);const CGSize area={width,round(width*1.25)};
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat preferredFormat];format.scale=2;format.opaque=YES;
    return [[[UIGraphicsImageRenderer alloc] initWithSize:area format:format] imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        DrawMap(area,day);
        CGContextRef c=UIGraphicsGetCurrentContext();CGContextSaveGState(c);
        CGContextTranslateCTM(c,area.width-size.width,0);[view.layer renderInContext:c];CGContextRestoreGState(c);
    }];
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
    // The gallery: the four arrangements at night on Nhựa, then four materials by day.
    Tile(out,@"goc",@"corner",@"asphalt",NO,Drive(47,50));
    Tile(out,@"gon",@"compact",@"asphalt",NO,Drive(47,50));
    Tile(out,@"le-dung",@"side",@"asphalt",NO,Drive(32,50));
    Tile(out,@"le-ngang",@"strip",@"asphalt",NO,Drive(32,50));
    Tile(out,@"son",@"corner",@"paint",YES,Drive(32,50));
    Tile(out,@"kinh",@"corner",@"glass",YES,Drive(47,50));
    Tile(out,@"suong",@"corner",@"haze",YES,Drive(32,50));
    Tile(out,@"tran",@"corner",@"bare",YES,Drive(58,50));
    SpeedFrames(out);
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
