//
//  LocationsViewController.m
//  UCD Map v2
//
//  Created by psytronx on 8/2/15.
//  Copyright (c) 2015 Logical Dimension. All rights reserved.
//

#import "LocationsViewController.h"

@interface LocationsViewController ()

@end

@implementation LocationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// =========================================================================
#pragma mark -
#pragma mark Table View Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int num = 0;
    num = [self.locationListViewHelper getNumOfSections];
    
    return (num > 0) ? num : 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    int num = 0;
    int numOfRows = 0;
    
    num = [self.locationListViewHelper getNumOfSections];
    if (num == 0) { return 0; }
    NSString *sectionName = [self.locationListViewHelper getSectionName:section];
    numOfRows = [self.locationListViewHelper getNumOfRows:sectionName];
    
    return numOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Convenience variables
    NSInteger sectionNum = [indexPath section];
    NSInteger rowNum = [indexPath row];
    
    Location *location = [self.locationListViewHelper getLocationAtSection:sectionNum atRow:rowNum];
    NSString *rowName = location.name;
    NSString *code = ([location.code isEqualToString:@""]) ? @" " : location.code;
    //Note: The default space ensures that the cell is spaced consistently even if there's no code.
    NSInteger roomMapLocationId = location.RoomMapLocationId;
    
    static NSString *sectionsTableIdentifier = @"sectionsTableIdentifier";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier: sectionsTableIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:sectionsTableIdentifier] autorelease];
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
        //							   reuseIdentifier:sectionsTableIdentifier] autorelease];
        /*
         cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero
         reuseIdentifier: sectionsTableIdentifier] autorelease];
         */
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    [cell.textLabel setText:rowName];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    
    [cell.detailTextLabel setText:code];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
    
    /*
     UILabel *cellLabel = [[[UILabel alloc] initWithFrame:cell.frame] autorelease];
     NSString *cellLabelText = [[NSString alloc] initWithFormat:@"  %@", rowName];
     cellLabel.text = cellLabelText;
     cellLabel.font = [UIFont systemFontOfSize:15.0];
     cellLabel.backgroundColor = [UIColor clearColor];
     cellLabel.opaque = NO;
     [cell.contentView addSubview:cellLabel];
     cell.backgroundColor = [UIColor whiteColor];
     [cellLabel release];
     [cellLabelText release];
     */
    
    // If there is are floor plans for this location, show a button in the row.
    if (roomMapLocationId) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;//UITableViewCellAccessoryDisclosureIndicator;
    }
    
    /*
     if ([self.selectedBuildingIDsDict objectForKey:rowName] == nil){
     [[cell.contentView.subviews objectAtIndex:0] setFont:[UIFont systemFontOfSize:15.0]];
     //cell.textLabel.font = [UIFont systemFontOfSize:15.0];
     cell.backgroundColor = [UIColor whiteColor];
     }else{
     [[cell.contentView.subviews objectAtIndex:0] setFont:[UIFont boldSystemFontOfSize:20.0]];
     //cell.textLabel.font = [UIFont boldSystemFontOfSize:24.0];
     cell.backgroundColor = [UIColor greenColor];
     }
     */
    
    //	if (![self.selectedBuildingArray containsObject:rowName]){
    //		cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    //		//cell.accessoryType=UITableViewCellAccessoryNone;
    //	}else{
    //		cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0];
    //		//cell.accessoryType=UITableViewCellAccessoryCheckmark;
    //	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    int num = 0;
    NSString *sectionName = @"";
    
    num = [self.locationListViewHelper getNumOfSections];
    if (num == 0) { return @""; }
    sectionName = [self.locationListViewHelper getSectionName:section];
    
    return sectionName;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *keys;
    
    keys = [self.locationListViewHelper getListOfSectionNames];
    
    return keys;
}

#pragma mark -
#pragma mark Table View Delegate Methods

// For now, just have single select.
// Code here was originally in tableView:accessoryButtonTappedForRowWithIndexPath:
// - RH 12/28/2010
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // variables for section and row number
    self.selectedSectionNum = indexPath.section;
    self.selectedRowNum = indexPath.row;
    
    NSString *rowName = [[NSString alloc] initWithString:[self.locationListViewHelper getRowName:selectedSectionNum atRowIndex:selectedRowNum]];
    
    NSLog(@"rowName: %@", rowName);
    self.selectedBuildingName = rowName;
    [rowName release];
    
    //	[mIndicatorView startAnimating];
    //	[self.view addSubview:mIndicatorView];
    
    // RH 1/1/11 Comment out
    //	NSMutableArray *locArray = [[[NSMutableArray alloc] init] autorelease];
    //	[locArray addObject:rowName];
    
    NSMutableArray * arrayLocations = [[NSMutableArray alloc] init];
    [arrayLocations addObject:rowName]; // Build array of locations' name. Well, only one location in this case.
    NSMutableDictionary *locations = [self.locationListViewHelper getLocations:arrayLocations];
    [arrayLocations release];
    
    //	[self goMap_single:locArray];
    //	[self goMap_with_indicator:locations];
    [self goMap_reverse:locations];
    
    // take away that blue highlight
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// Go to floorplans view.
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //Convenience variables
    NSInteger sectionNum = [indexPath section];
    NSInteger rowNum = [indexPath row];
    
    // Go to floorplans view.
    Location *location = [self.locationListViewHelper getLocationAtSection:sectionNum atRow:rowNum];
    if (location){
        NSInteger roomMapLocationId = location.RoomMapLocationId;
        NSString * navTitle = location.name;
        FloorsViewController *controller = [[FloorsViewController alloc] initWithRoomMapLocationID: roomMapLocationId withTitle:navTitle];//initWithNibName:@"FloorsViewController" bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
    }
}


// ===========================================================================================
#pragma mark - Search Bar Methods

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
    [mIndicatorView startAnimating];
    [self.view addSubview:mIndicatorView];
    
    [self performSelector:@selector(showSearchResult:) withObject:searchText afterDelay:0.0];
    
    //[self.locationListObj rebuildSectionRowDict:searchText];
    
}

- (void)showSearchResult:(NSString *)searchText
{
    [self.locationListViewHelper rebuildSectionRowDict:searchText];
    
    [mIndicatorView stopAnimating];
    [mIndicatorView removeFromSuperview];
    
    // refresh the table view
    [self.myTable reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
