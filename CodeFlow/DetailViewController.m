//
//  DetailViewController.m
//  CodeFlow
//
//  Created by Cory Kilger on 7/17/11.
//  Copyright 2011 Cory Kilger. All rights reserved.
//

#import "DetailViewController.h"
#import "RootViewController.h"
#import "NSData+Gzip.h"
#import "NSData+Base64.h"

@interface DetailViewController ()
@property (nonatomic, retain) UIPopoverController *popoverController;
- (void)configureView;
@end

@implementation DetailViewController

@synthesize toolbar=_toolbar;
@synthesize detailItem=_detailItem;
@synthesize detailDescriptionLabel=_detailDescriptionLabel;
@synthesize popoverController=_myPopoverController;

@synthesize webView;
@synthesize data;

#pragma mark - Managing the detail item

/*
 When setting the detail item, update the view and dismiss the popover controller if it's showing.
 */
- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        [_detailItem release];
        _detailItem = [newDetailItem retain];
        
        // Update the view.
        [self configureView];
    }

    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

	self.detailDescriptionLabel.text = [self.detailItem description];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Split view support

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController: (UIPopoverController *)pc
{
    barButtonItem.title = @"Events";
    NSMutableArray *items = [[self.toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [self.toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [[self.toolbar items] mutableCopy];
    [items removeObjectAtIndex:0];
    [self.toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = nil;
}

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSString * requestBodyString = @"H4sICHlQeU0AA0F2YW50R2FyZGUuZ3YA3ZJJT4NAGIbPzK+YcLYpXW7CJGxiFUul"
									"uOthkCkzFgZKp4ua/vdCTRON2uiJhMub+db3y5OJWFzgnL4DqQNbCHYr6VXSPwZl"
									"7gFOMi44Tokm60vMhYOLiLSMLJvKcE5xTrQwW8MViwTVFEgJi6koHykuYsY1WTlS"
									"ZCAlOCSJpqqBbrg2NDzfsv2yJkPTdt192PkIxyPdHAydqoyApAY+UgMLfTNX22W2"
									"FP9Lk2Fa9olzOjhzz92LoTe69MfB1fXN7d39zwM4fI7IJKbsJZkmKc/yWTEXi+Vq"
									"/fr2b4dH/udt7R0IhJ4qxt0DjL0wYbMFqRX1/obmEO/9QtwiKasN9c68OYz7BxjX"
									"/as/39AY4mADtoCCMYvMBQAA";
	
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://Gideon.local/cgi-bin/graphviz-cgi"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[requestBodyString dataUsingEncoding:NSUTF8StringEncoding]];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

NSString * DocumentsFolder() {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData {
	[self.data appendData:newData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString * string = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
	
	if ([string isEqualToString:@"ERROR"]) {
		[string release];
		[[[[UIAlertView alloc] initWithTitle:@"ERROR" message:@"There was an error generating the flowchart." delegate:nil cancelButtonTitle:@"Bummer." otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	NSData * content = [NSData dataFromBase64String:string];
	content = [content gzipInflate];
	NSString * filePath = [DocumentsFolder() stringByAppendingPathComponent:@"flowchart.pdf"];
	[content writeToFile:filePath atomically:YES];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]]];
	self.webView.alpha = 1.0;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[[[[UIAlertView alloc] initWithTitle:@"Network error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Ah, man." otherButtonTitles:nil] autorelease] show];
}

- (void)viewDidUnload
{
	[super viewDidUnload];

	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.popoverController = nil;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
	[_myPopoverController release];
	[_toolbar release];
	[_detailItem release];
	[_detailDescriptionLabel release];
    [super dealloc];
}

@end
