//
//  LocationsViewController.m
//  UCD Map v2
//
//  Created by psytronx on 8/2/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "LocationsViewController.h"
#import "MapViewController.h"
#import "UMPDataSource.h"
#import "UMPCampus.h"
#import "UMPLocation.h"

@interface LocationsViewController ()
@property (nonatomic, strong) NSDictionary *sections;
@property (nonatomic, strong) NSArray *sortedSectionsArray;
@property (nonatomic, strong) NSMutableArray *checkedLocations;
@end

@implementation LocationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Instantiate properties if needed
    self.checkedLocations = [[NSMutableArray alloc] init];
    
    // Register Key Value Observation of mediaItems
    [[UMPDataSource sharedInstance] addObserver:self forKeyPath:@"locations" options:0 context:nil];
    
    // Register cell class for tableView
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    // Set title
    self.title = [UMPDataSource sharedInstance].campus.campusName;
    
    // Load data
    [self refreshSections:self.searchBar.text];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    [[UMPDataSource sharedInstance] removeObserver:self forKeyPath:@"locations"];
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [UMPDataSource sharedInstance] && [keyPath isEqualToString:@"locations"]) {
        NSKeyValueChange kindOfChange = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        
        if (kindOfChange == NSKeyValueChangeSetting) {
            [self refreshSections:self.searchBar.text];
            [self.tableView reloadData];
        } else {
            NSLog(@"Error: kindOfChange invalid. Needs to be equal to NSKeyValueChangeSetting.");
        }
    }
}


#pragma mark - Refresh Data

- (void)refreshSections:(NSString *)searchString
{
    // Get filtered and sorted array of locations
    NSArray *locations = [UMPDataSource sharedInstance].locations;
    if ([searchString length] > 0){
        NSPredicate *sPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat: @"name contains[c] '%@'", searchString]];
        locations = [locations filteredArrayUsingPredicate:sPredicate];
    }
    locations = [locations sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        // Sort by name
        NSString *first = ((UMPLocation*)a).name;
        NSString *second = ((UMPLocation*)b).name;
        return [first compare:second];
    }];
    
    // Refresh sections and sortedSectionsArray
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init]; //Temp container. Will be assigned to self.dictSectionRow
    for (UMPLocation *location in locations){
        NSString *ch = [[NSString alloc] initWithString:[location.name substringToIndex:1]];
        if ([dict objectForKey:ch] == nil){
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            [dict setValue:arr forKey:ch];
        }
        // insert the location into the corresponding section
        [[dict objectForKey:ch] addObject:location];
    }
    self.sections = dict;
    self.sortedSectionsArray = [[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
//    self.sortedSectionsArray = [dict keysSortedByValueUsingComparator:^NSComparisonResult(id a, id b) {
//        return [a compare:b];
//    }];
}

// =========================================================================
#pragma mark - Table View Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    NSUInteger num = [self.sortedSectionsArray count];
    return (num > 0) ? num : 1;

}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.sortedSectionsArray count] == 0){
        return 0;
    }
    
    NSString *sectionName = self.sortedSectionsArray[section];
    NSUInteger numOfRows = [self.sections[sectionName] count];
    
    return numOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Get location
    NSInteger section = [indexPath section];
    NSInteger rowNum = [indexPath row];
    NSString *sectionName = self.sortedSectionsArray[section];
    UMPLocation *location = self.sections[sectionName][rowNum];
    
    // Setup cell
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Setup checkbox
    if ([self.checkedLocations containsObject:location]) {
        cell.imageView.image = [UIImage imageNamed:@"checked.png"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"unchecked.png"];
    }
    CGRect frame = cell.imageView.frame;
    frame.size.width = 20;
    cell.imageView.frame = frame;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleChecking:)];
    [cell.imageView addGestureRecognizer:tap];
    cell.imageView.backgroundColor = [UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:0.0]; // Transparent background
    
    cell.imageView.userInteractionEnabled = YES; //added based on @John 's comment
    //[tap release];
    
    [cell.textLabel setText:location.name];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void) handleChecking:(UITapGestureRecognizer *)tapRecognizer {
    CGPoint tapLocation = [tapRecognizer locationInView:self.tableView];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    
    // Get location
    NSInteger section = [tappedIndexPath section];
    NSInteger rowNum = [tappedIndexPath row];
    NSString *sectionName = self.sortedSectionsArray[section];
    UMPLocation *location = self.sections[sectionName][rowNum];
    
    if ([self.checkedLocations containsObject:location]) {
        [self.checkedLocations removeObject:location];
    }
    else {
        [self.checkedLocations addObject:location];
    }
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:tappedIndexPath] withRowAnimation: UITableViewRowAnimationFade];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.sortedSectionsArray count] == 0) {
        return @"";
    }
    return self.sortedSectionsArray[section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sortedSectionsArray;
}

#pragma mark - Table View Delegate Methods
//
//// For now, just have single select.
//// Code here was originally in tableView:accessoryButtonTappedForRowWithIndexPath:
//// - RH 12/28/2010
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Row pressed");
    
    //Convenience variables
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    
    // Go to map view
    NSString *sectionName = self.sortedSectionsArray[section];
    UMPLocation *location = self.sections[sectionName][row];
    if (location){
        [self performSegueWithIdentifier:@"showmapview" sender:@[location]];
    }
//    // variables for section and row number
//    self.selectedSectionNum = indexPath.section;
//    self.selectedRowNum = indexPath.row;
}
//
//    NSString *rowName = [[NSString alloc] initWithString:[self.locationListViewHelper getRowName:selectedSectionNum atRowIndex:selectedRowNum]];
//    
//    NSLog(@"rowName: %@", rowName);
//    self.selectedBuildingName = rowName;
//    [rowName release];
//    
//    //	[mIndicatorView startAnimating];
//    //	[self.view addSubview:mIndicatorView];
//    
//    // RH 1/1/11 Comment out
//    //	NSMutableArray *locArray = [[[NSMutableArray alloc] init] autorelease];
//    //	[locArray addObject:rowName];
//    
//    NSMutableArray * arrayLocations = [[NSMutableArray alloc] init];
//    [arrayLocations addObject:rowName]; // Build array of locations' name. Well, only one location in this case.
//    NSMutableDictionary *locations = [self.locationListViewHelper getLocations:arrayLocations];
//    [arrayLocations release];
//    
//    //	[self goMap_single:locArray];
//    //	[self goMap_with_indicator:locations];
//    [self goMap_reverse:locations];
//    
//    // take away that blue highlight
//    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
//}
//
// Go to floorplans view.
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //Convenience variables
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    
    // Go to map view
    NSString *sectionName = self.sortedSectionsArray[section];
    UMPLocation *location = self.sections[sectionName][row];
    if (location){
        [self performSegueWithIdentifier:@"showmapview" sender:@[location]];
    }
}


// ===========================================================================================
#pragma mark - UISearchBarDelegate Methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    NSLog(@"about to start editing");
    [self.searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    NSLog(@"about to end editing");
    [self.searchBar setShowsCancelButton:NO animated:YES];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    NSLog(@"searchBarCancelButtonClicked");
    [self.searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked");
    [self.searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Here we will need to do our searches...
    NSLog(@"textDidChange : %@", searchText);
    [self performSelector:@selector(showSearchResult:) withObject:searchText afterDelay:0.0];
    
}

- (void)showSearchResult:(NSString *)searchText
{
    [self refreshSections:searchText];
    [self.tableView reloadData];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showmapview"] && [sender isKindOfClass:[NSArray class]]){
        
        // Get reference to the destination view controller
        MapViewController *mapViewController = [segue destinationViewController];

        // Pass any objects to the view controller here, like...
        mapViewController.locations = sender;
        
    }else if ([[segue identifier] isEqualToString:@"showmapview-selected-locations"]){
        
        // Get reference to the destination view controller
        MapViewController *mapViewController = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        mapViewController.locations = self.checkedLocations;
        
    }else {
        NSLog(@"Error going to map view");
    }
}

@end
