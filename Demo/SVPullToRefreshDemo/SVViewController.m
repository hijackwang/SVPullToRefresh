//
//  SVViewController.m
//  SVPullToRefreshDemo
//
//  Created by Sam Vermette on 23.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "SVViewController.h"
#import "SVPullToRefresh.h"

@interface SVViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation SVViewController
@synthesize tableView = tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDataSource];
    
    __weak SVViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf insertRowAtTop];
    }];
        
    // setup infinite scrolling
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf insertRowAtBottom];
    }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self setLastUpdateDate:[self lastUpdateDate]];
}

- (void)setLastUpdateDate:(NSDate *)date
{
    if(date==nil){
        [self.tableView.pullToRefreshView setSubtitle:NSLocalizedString(@"Last update date is NULL", nil) forState:SVPullToRefreshStateAll];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date]
                                                  forKey:@"RefreshDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSTimeInterval timeInterval = ABS([date timeIntervalSinceNow]);
        NSString *str;
        if(timeInterval < 60)
            str = NSLocalizedString(@"Just now", nil);
        else if(timeInterval < 60*60)
            str = [NSString stringWithFormat:NSLocalizedString(@"%.0f minutes ago", nil), timeInterval/60];
        else if(timeInterval < 60*60*24)
            str = [NSString stringWithFormat:NSLocalizedString(@"%.0f hours ago", nil), timeInterval/60*60];
        else
            str = [NSString stringWithFormat:NSLocalizedString(@"%.0f days ago", nil), timeInterval/60*60*24];
        NSString *lastUpdateString = [NSString stringWithFormat:NSLocalizedString(@"Last update date: %@", nil), str];
        [self.tableView.pullToRefreshView setSubtitle:lastUpdateString forState:SVPullToRefreshStateAll];
    }
}


- (NSDate *)lastUpdateDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"RefreshDate"];
}

- (void)viewDidAppear:(BOOL)animated {
    [tableView triggerPullToRefresh];
}

#pragma mark - Actions

- (void)setupDataSource {
    self.dataSource = [NSMutableArray array];
    for(int i=0; i<15; i++)
        [self.dataSource addObject:[NSDate dateWithTimeIntervalSinceNow:-(i*90)]];
}

- (void)insertRowAtTop {
    __weak SVViewController *weakSelf = self;

    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf.tableView beginUpdates];
        [weakSelf.dataSource insertObject:[NSDate date] atIndex:0];
        [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [weakSelf.tableView endUpdates];
        
        [weakSelf.tableView.pullToRefreshView stopAnimating];
        
        [self setLastUpdateDate:[NSDate date]];
    });
}


- (void)insertRowAtBottom {
    __weak SVViewController *weakSelf = self;

    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf.tableView beginUpdates];
        [weakSelf.dataSource addObject:[weakSelf.dataSource.lastObject dateByAddingTimeInterval:-90]];
        [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:weakSelf.dataSource.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [weakSelf.tableView endUpdates];
        
        [weakSelf.tableView.infiniteScrollingView stopAnimating];
    });
}
#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    NSDate *date = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    return cell;
}

@end
