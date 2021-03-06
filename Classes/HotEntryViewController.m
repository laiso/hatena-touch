#import "HotEntryViewController.h"
#import "FeedParser.h"
#import "EntryCell.h"
#import "WebViewController.h"
#import "HatenaTouchAppDelegate.h"
#import "NSString+XMLExtensions.h"
#import "Reachability.h"
#import "Debug.h"

@implementation HotEntryViewController

@synthesize hotEntryView;
@synthesize hotEntries;
@synthesize featuredEntries;
@synthesize selectedRow;

- (void)dealloc {
	LOG_CURRENT_METHOD;
	[selectedRow release];
	[featuredEntries release];
	[hotEntries release];
	[hotEntryView setDelegate:nil];
	[hotEntryView release];
	[super dealloc];
}

- (void)loadHotEntries {
	LOG_CURRENT_METHOD;
	NSString *URL = @"http://b.hatena.ne.jp/hotentry.rss";
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
	[FeedParser parseWithRequest:request callBackObject:self callBack:@selector(addHotEntry:) completeSelector:@selector(finishLoading)];
}

- (void)loadFeaturedEntries {
	LOG_CURRENT_METHOD;
	NSString *URL = @"http://b.hatena.ne.jp/entrylist?sort=hot&threshold=&mode=rss";
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
	[FeedParser parseWithRequest:request callBackObject:self callBack:@selector(addFeaturedEntry:) completeSelector:@selector(finishLoading)];
}

- (void)finishLoading {
	finishCount++;
	if (finishCount == 2) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

- (void)loadEntries {
	LOG(@"Hot Entries: refresh data.");
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[self loadHotEntries];
	[self loadFeaturedEntries];
}

- (void)addHotEntry:(id)entry {
	if (!hotEntries) {
		hotEntries = [[NSMutableArray alloc] initWithCapacity:30];
	}
	[hotEntries addObject:entry];
	[hotEntryView reloadData];
}

- (void)addFeaturedEntry:(id)entry {
	if (!featuredEntries) {
		featuredEntries = [[NSMutableArray alloc] initWithCapacity:30];
	}
	[featuredEntries addObject:entry];
	[hotEntryView reloadData];
}

- (void)refleshIfNeeded {
	if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
		NSBundle *bundle = [NSBundle mainBundle];
		NSDictionary *infoDictionary = [bundle localizedInfoDictionary];
		NSString *appName = [[infoDictionary count] ? infoDictionary : [bundle infoDictionary] objectForKey:@"CFBundleDisplayName"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:appName message:NSLocalizedString(@"NotReachable", nil)
													   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];	
		[alert release];
		return;
	}
	
	if (!hotEntries || !featuredEntries) {
		[hotEntries removeAllObjects];
		[featuredEntries removeAllObjects];
		[self loadEntries];
	}
	[hotEntryView reloadData];
}

- (NSDictionary *)whichEntry:(NSIndexPath *)indexPath {
	NSDictionary *entry = nil;
	if (indexPath.section == 0) {
		entry = [hotEntries objectAtIndex:indexPath.row];
	} else {
		entry = [featuredEntries objectAtIndex:indexPath.row];
	}
	return entry;
}

#pragma mark <UITableViewDataSource> Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [hotEntries count];
	} else {
		return [featuredEntries count];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EntryCell";
	EntryCell *cell = (EntryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[EntryCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 80.0f) reuseIdentifier:CellIdentifier] autorelease];
	}
	
	NSDictionary *entry = [self whichEntry:indexPath];
	
	NSMutableDictionary *listOfRead = [[HatenaTouchAppDelegate sharedHatenaTouchApp] listOfRead];
	cell.hasRead = [listOfRead objectForKey:[entry objectForKey:@"link"]] != nil;

	[cell setTitleText:[NSString decodeXMLCharactersIn:[entry objectForKey:@"title"]]];
	[cell setDescriptionText:[NSString decodeXMLCharactersIn:[entry objectForKey:@"description"]]];
	[cell setNumberText:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return NSLocalizedString(@"RecentEntry", nil);
	} else {
		return NSLocalizedString(@"FeaturedEntry", nil);
	}
}

#pragma mark <UITableViewDelegate> Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	selectedRow = indexPath;
	
	WebViewController *controller = [[HatenaTouchAppDelegate sharedHatenaTouchApp] sharedWebViewController];
	
	NSDictionary *entry = [self whichEntry:indexPath];
	controller.title = [entry objectForKey:@"title"];
	controller.pageURL = [NSString decodeXMLCharactersIn:[entry objectForKey:@"link"]];
	
	NSMutableDictionary *listOfRead = [[HatenaTouchAppDelegate sharedHatenaTouchApp] listOfRead];
	[listOfRead setObject:[entry objectForKey:@"title"] forKey:[entry objectForKey:@"link"]];
	
	[[self navigationController] pushViewController:controller animated:YES];
}

#pragma mark <UIViewController> Methods

- (void)loadView {
	[hotEntryView release];
	hotEntryView = nil;
	hotEntryView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 460.0f)];
	[hotEntryView setRowHeight:80.0f];
	[hotEntryView setDelegate:self];
	[hotEntryView setDataSource:self];
	[self setView:hotEntryView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = NSLocalizedString(@"HotEntry", nil);
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refleshIfNeeded];
}

- (void)didReceiveMemoryWarning {
	LOG_CURRENT_METHOD;
	[super didReceiveMemoryWarning];
}

@end
