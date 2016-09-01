//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;


-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
    NSDictionary *options = [[NSDictionary alloc] init];
    [self createViewWithOptions:options];
}

- (void)createViewWithOptions:(NSDictionary *)options {

    //This is the Designated Initializer

    // defaults
    float height = ([options objectForKey:@"height"]) ? [[options objectForKey:@"height"] floatValue] : self.webView.bounds.size.height/2;
    float width = ([options objectForKey:@"width"]) ? [[options objectForKey:@"width"] floatValue] : self.webView.bounds.size.width;
    float x = self.webView.bounds.origin.x;
    float y = self.webView.bounds.origin.y;
    BOOL atBottom = ([options objectForKey:@"atBottom"]) ? [[options objectForKey:@"atBottom"] boolValue] : NO;

    if(atBottom) {
        y += self.webView.bounds.size.height - height;
    }

    self.childView = [[UIView alloc] initWithFrame:CGRectMake(x,y,width,height)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(self.childView.bounds.origin.x, self.childView.bounds.origin.x, self.childView.bounds.size.width, self.childView.bounds.size.height)];
    self.mapView.delegate = self;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
	self.mapView.showsUserLocation = YES;
	self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;


    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
	CLLocationDistance diameter = [[options objectForKey:@"diameter"] floatValue];

	MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord,
                                                                                                diameter*(height / self.webView.bounds.size.width),
                                                                                                diameter*(height / self.webView.bounds.size.width))];
    [self.mapView setRegion:region animated:YES];
	[self.childView addSubview:self.mapView];

	[ [ [ self viewController ] view ] addSubview:self.childView];

}

- (void)destroyMap:(CDVInvokedUrlCommand *)command
{
	if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];

		mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
		//[ self.imageButton removeTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
		self.imageButton = nil;

	}
	if(self.childView)
	{
		[ self.childView removeFromSuperview];
		self.childView = nil;
	}
    self.buttonCallback = nil;
}

- (void)clearMapPins:(CDVInvokedUrlCommand *)command
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)addMapPins:(CDVInvokedUrlCommand *)command
{

    NSArray *pins = command.arguments[0];

  for (int y = 0; y < pins.count; y++)
    {
        NSDictionary *pinData = [pins objectAtIndex:y];
		CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
		NSString *title=[[pinData valueForKey:@"title"] description];
		NSString *subTitle=[[pinData valueForKey:@"snippet"] description];
		NSInteger index=[[pinData valueForKey:@"index"] integerValue];
		BOOL selected = [[pinData valueForKey:@"selected"] boolValue];

        NSString *pinColor = nil;
        NSString *imageURL = nil;
        NSString *pinURL = nil;
        NSString *startOpen = nil;

        if([[pinData valueForKey:@"icon"] isKindOfClass:[NSNumber class]])
        {
            pinColor = [[pinData valueForKey:@"icon"] description];
        }
        else if([[pinData valueForKey:@"icon"] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *iconOptions = [pinData valueForKey:@"icon"];
            pinColor = [[iconOptions valueForKey:@"pinColor" ] description];
            imageURL=[[iconOptions valueForKey:@"resource"] description];
            pinURL =[[iconOptions valueForKey:@"customPin"] description];
            startOpen =[[iconOptions valueForKey:@"startOpen"] description];
        }

		CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle imageURL:imageURL];
		annotation.pinColor=pinColor;
		annotation.selected = selected;
		annotation.pinURL = pinURL;
		annotation.startOpen = startOpen;

		[self.mapView addAnnotation:annotation];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
	}

}

-(void)showMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView)
	{
        [self createViewWithOptions:command.arguments[0]];
	}
	self.childView.hidden = NO;
	self.mapView.showsUserLocation = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}
// Add a Close Button
- (void)addCloseButton:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
    {
        return;
    }
    NSLog(@"CLOSE BUTTON");
    NSArray *btn = command.arguments[0];

    for (int y = 0; y < btn.count; y++)
    {
        NSDictionary *btnData = [btn objectAtIndex:y];
        float PosX = [[btnData objectForKey:@"PosX"] floatValue];
        float PosY = [[btnData objectForKey:@"PosY"] floatValue];

        CGRect  viewRect = CGRectMake(PosX, PosY, 40, 40);
        UIButton* closeBtn = [[UIButton alloc] initWithFrame:viewRect];

        //closeBtn.backgroundColor = [UIColor colorWithRed:(0.0 / 255.0) green:(126.0 / 255.0) blue:(180.0 / 255.0) alpha: 1];
        //closeBtn.layer.cornerRadius = 20;
        //closeBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha: 1].CGColor;
        //closeBtn.layer.borderWidth = 3.0f;
        closeBtn.tag = 222;
        [closeBtn setBackgroundImage:[UIImage imageNamed:@"btnclose.png"] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(checkButtonTapped2:) forControlEvents:UIControlEventTouchUpInside];
        [self.mapView addSubview:closeBtn];

    }

}

- (void)hideMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
	{
		return;
	}
	// disable location services, if we no longer need it.
	self.mapView.showsUserLocation = NO;
	self.childView.hidden = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)changeMapType:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
	{
		return;
	}

    int mapType = ([command.arguments[0] objectForKey:@"mapType"]) ? [[command.arguments[0] objectForKey:@"mapType"] intValue] : 0;

    switch (mapType) {
        case 4:
            [self.mapView setMapType:MKMapTypeHybrid];
            break;
        case 2:
            [self.mapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [self.mapView setMapType:MKMapTypeStandard];
            break;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

//Might need this later?
/*- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;

    [self.mapView setRegion:mapRegion animated: YES];
}


- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated
{
    NSLog(@"region did change animated");
    float currentLat = theMapView.region.center.latitude;
    float currentLon = theMapView.region.center.longitude;
    float latitudeDelta = theMapView.region.span.latitudeDelta;
    float longitudeDelta = theMapView.region.span.longitudeDelta;

    NSString* jsString = nil;
    jsString = [[NSString alloc] initWithFormat:@"geo.onMapMove(\'%f','%f','%f','%f\');", currentLat,currentLon,latitudeDelta,longitudeDelta];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    [jsString autorelease];
}
 */
 /**
 * Set annotations and mapview settings
 */

- (void)setViewWithOptions:(NSDictionary *)options {

    // defaults
    CGFloat height = 480.0f;
    CGFloat offsetTop = 0.0f;

    if ([options objectForKey:@"height"])
    {
        height=[[options objectForKey:@"height"] floatValue];
    }
    if ([options objectForKey:@"offsetTop"])
    {
        offsetTop=[[options objectForKey:@"offsetTop"] floatValue];
    }
    if ([options objectForKey:@"buttonCallback"])
    {
        self.buttonCallback=[[options objectForKey:@"buttonCallback"] description];
    }

    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
    CLLocationDistance diameter = [[options objectForKey:@"diameter"] floatValue];

    CGRect webViewBounds = self.webView.bounds;

    CGRect mapBoundsChildView;
    CGRect mapBoundsMapView;
    mapBoundsChildView = CGRectMake(
                                    webViewBounds.origin.x,
                                    webViewBounds.origin.y + (offsetTop),
                                    webViewBounds.size.width,
                                    webViewBounds.origin.y + height
                                    );
    mapBoundsMapView = CGRectMake(
                                  webViewBounds.origin.x,
                                  webViewBounds.origin.y,
                                  webViewBounds.size.width,
                                  webViewBounds.origin.y + height
                                  );

    //[self setFrame:mapBounds];
    [self.childView setFrame:mapBoundsChildView];
    [self.mapView setFrame:mapBoundsMapView];

    MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord,
                                                                                                diameter*(height / webViewBounds.size.width),
                                                                                                diameter*(height / webViewBounds.size.width))];
    [self.mapView setRegion:region animated:YES];

    CGRect frame = CGRectMake(285.0,12.0,  29.0, 29.0);

    [ self.imageButton setImage:[UIImage imageNamed:@"www/map-close-button.png"] forState:UIControlStateNormal];
    [ self.imageButton setFrame:frame];
    [ self.imageButton addTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setMapData:(CDVInvokedUrlCommand *)command
{
    [self setViewWithOptions:command.arguments[0]];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}
/***** end custom JRO ***/
- (void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    CGRect visibleRect = [mapView annotationVisibleRect];
    float delay = 0.00;
    for (MKAnnotationView *view in views) {
       // Don't pin drop if annotation is user location
        if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        // Check if current annotation is inside visible map rect, else go to next one
        MKMapPoint point =  MKMapPointForCoordinate(view.annotation.coordinate);
        if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
            continue;
        }
       CGRect endFrame = view.frame;

       CGRect startFrame = endFrame; startFrame.origin.y = visibleRect.origin.y - startFrame.size.height;
       view.frame = startFrame;
       delay = delay + 0.05;
       [UIView beginAnimations:@"drop" context:NULL];
       [UIView setAnimationDelay:delay];
       [UIView setAnimationDuration:0.45];
       [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

	view.frame = endFrame;
       [UIView commitAnimations];
    }
}

- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation {

  if ([annotation class] != CDVAnnotation.class) {
    return nil;
  }

	CDVAnnotation *phAnnotation=(CDVAnnotation *) annotation;
	NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];

	MKAnnotationView *annView = (MKAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];

	if (annView!=nil) return annView;

	annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];

	//annView.animatesDrop=YES;
	annView.canShowCallout = NO;
	/*	if ([phAnnotation.pinColor isEqualToString:@"120"])
		annView.pinColor = MKPinAnnotationColorGreen;
	else if ([phAnnotation.pinColor isEqualToString:@"270"])
		annView.pinColor = MKPinAnnotationColorPurple;
	else
		annView.pinColor = MKPinAnnotationColorRed;
	*/

	AsyncImageView* asyncImage = [[AsyncImageView alloc] initWithFrame:CGRectMake(0,0, 50, 32)];
	asyncImage.tag = 999;
	if (phAnnotation.imageURL)
	{
		NSURL *url = [[NSURL alloc] initWithString:phAnnotation.imageURL];
		[asyncImage loadImageFromURL:url];
	}
	else
	{
		[asyncImage loadDefaultImage];
	}

	annView.leftCalloutAccessoryView = asyncImage;


	if (self.buttonCallback && phAnnotation.index!=-1)
	{

		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		myDetailButton.tag=phAnnotation.index;
		annView.rightCalloutAccessoryView = myDetailButton;
		[ myDetailButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

	}

	//annView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:phAnnotation.pinURL]]];
	if ([phAnnotation.pinURL isEqualToString:@"eat"]){
		annView.image = [UIImage imageNamed:@"food.png" inBundle:nil compatibleWithTraitCollection:nil];
	}else if([phAnnotation.pinURL isEqualToString:@"venue"]){
		annView.image = [UIImage imageNamed:@"venue.png" inBundle:nil compatibleWithTraitCollection:nil];
	}

	if ([phAnnotation.startOpen isEqualToString:@"yes"]){
        annView.canShowCallout = YES;
		[self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
	}


	return annView;
}
//second part JRO
//when a pin is selected or deselected, do something
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSString *latitude = [[NSString alloc] initWithFormat:@"%f",view.annotation.coordinate.latitude];
    NSString *longitude = [[NSString alloc] initWithFormat:@"%f",view.annotation.coordinate.longitude];





    //NSLog(@"Selected: %@%@%@",[view.annotation subtitle], latitude, longitude);
if ([view.annotation isKindOfClass:[CDVAnnotation class]]) {
    //CDVAnnotation *Annot=(CDVAnnotation *)view.annotation;
    //Annot.image = [UIImage imageNamed:@"default.png" inBundle:nil compatibleWithTraitCollection:nil];
    //NSString *elid = [[NSString alloc] initWithFormat:@"%d",view.annotation.index];
    // grow
     CGAffineTransform transform = CGAffineTransformMakeScale(1.2, 1.2);
     CGAffineTransform inverseTransform = CGAffineTransformInvert(transform);
    [UIView transitionWithView:view
                  duration:0.2f
                   options:UIViewAnimationOptionTransitionCrossDissolve
                animations:^{
                    if(view.image == [UIImage imageNamed:@"food.png"]){
                        view.image = [UIImage imageNamed:@"foodsel.png"];
                    }else if(view.image == [UIImage imageNamed:@"venue.png"]){
                        view.image = [UIImage imageNamed:@"venuesel.png"];
                    }
                    view.transform = transform;
                } completion:^(BOOL finished) {
                    //  Do whatever when the animation is finished
                    [UIView animateWithDuration:0.4f
                      delay:0.0f
                      usingSpringWithDamping:0.40f
                      initialSpringVelocity:0.2f
                      options: UIViewAnimationOptionCurveEaseOut
                      animations:^{
                            [view setTransform:CGAffineTransformIdentity];
                        } completion:nil];
                }];

        NSString *annotationTapFunctionString = [NSString stringWithFormat:@"%s%@%s%@%s%@%s", "annotationTap('", [view.annotation subtitle], "','", latitude, "','", longitude, "')"];
        [self.webView stringByEvaluatingJavaScriptFromString:annotationTapFunctionString];

       /*UIView * myImgView = [self createMyImgView];
       [view addSubview:myImgView];*/



    }
}
// add subview image on select
- (UIView *) createMyImgView {

    UIView * myView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIImageView * myImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [myImage setImage:[UIImage imageNamed:@"icon.png"]];
    [myView addSubview:myImage];

    UIButton * thisButton = [[UIButton alloc] initWithFrame:CGRectMake(50,50, 50, 10)];
    [thisButton.titleLabel setText:@"My Button"];
    [thisButton addTarget:self action:@selector(checkButtonTapped2:) forControlEvents:UIControlEventTouchUpInside];
    [myView addSubview:thisButton];

    // etc.

    return myView;

}

// ends add subview img on select

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[CDVAnnotation class]]) {
        [UIView transitionWithView:view
                  duration:0.2f
                   options:UIViewAnimationOptionTransitionCrossDissolve
                animations:^{
                    if(view.image == [UIImage imageNamed:@"foodsel.png"]){
                        view.image = [UIImage imageNamed:@"food.png"];
                    }else if(view.image == [UIImage imageNamed:@"venuesel.png"]){
                        view.image = [UIImage imageNamed:@"venue.png"];
                    }
                } completion:nil];




        //NSLog(@"De-Selected: %@",[view.annotation title]);
    NSString *annotationDeselectFunctionString = [NSString stringWithFormat:@"%s%@%s", "annotationDeselect('", [view.annotation subtitle], "')"];
    [self.webView stringByEvaluatingJavaScriptFromString:annotationDeselectFunctionString];
    UIView *viewToRemove = [self.mapView viewWithTag:222];
    [viewToRemove removeFromSuperview];
    /*for (UIView *subview in view.subviews ){
        [subview removeFromSuperview];
    }*/
    }
}

- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated
{
    NSLog(@"region did change animated");
    float currentLat = theMapView.region.center.latitude;
    float currentLon = theMapView.region.center.longitude;
    float latitudeDelta = theMapView.region.span.latitudeDelta;
    float longitudeDelta = theMapView.region.span.longitudeDelta;

    NSString* jsString = nil;
    jsString = [[NSString alloc] initWithFormat:@"geo.onMapMove(\'%f','%f','%f','%f\');", currentLat,currentLon,latitudeDelta,longitudeDelta];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    //[jsString autorelease];
}
//ends secod part JRO
-(void)openAnnotation:(id <MKAnnotation>) annotation
{
	[ self.mapView selectAnnotation:annotation animated:YES];

}

- (void) checkButtonTapped:(id)button
{
	UIButton *tmpButton = button;
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
	[self.webView stringByEvaluatingJavaScriptFromString:jsString];

}
- (void) checkButtonTapped2:(id)button
{
    UIButton *tmpButton = button;
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    for (CDVAnnotation *annotationView in selectedAnnotations) {
        [self.mapView deselectAnnotation:annotationView animated:YES];
    }
    NSString* jsString = [NSString stringWithFormat:@"btap(\"%s\");","uclicked"];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];

}


- (void)dealloc
{
    if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];
        self.mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
        self.imageButton = nil;
	}
	if(childView)
	{
		[ self.childView removeFromSuperview];
        self.childView = nil;
	}
    self.buttonCallback = nil;
}

@end
