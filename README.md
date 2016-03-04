# umap
University Map app, rewritten for iOS 8+ compatibility

This app provides a directory for campus locations of a given university. We (Logical Dimension) released this back in 2009. After letting the application lay dormant for years, I decided to completely rewrite it so that it supports modern versions of iOS.

The app works by providing a list of campus locations that the user can select and view on a map. If a user presses the disclosure indicator of a table cell, the map will apear and show that location's pin. The user can also select multiple locations and view them simultaneously on the map. If a pin is pressed, it brings up an action sheet that gives option to show directions in Apple Maps. If the user has the Google Maps or Uber app, those can be accessed as well using deep linking.

Campus and location data is stored on our databases and served by a simple web API. When the app is loaded for the first time, it fetches the data (using AFNetworking) and caches it. The app checks for new data once a week and refreshes the cache if needed.

Future features: 
- Use Core Graphics instead of PNG's to render check-box icons.
- Differentiate between different types of locations, e.g. Parking structures vs. lecture halls vs. restaurant/food.
- Incorporate local business locations from Yelp or Google API.

##Setting up development environment

1. Get Cocoa Pods on your system. Cocoa Pods is the premier package manager for XCode development.
2. Clone the repo into your disk. Go into the project's folder.
3. Run 'pod install'. After that's done, from now on, use the workspace file generated to open the project in XCode.

##Steps for deploying to App Store for a school (more detailed instructions will be fleshed out later):

1. Make sure App Id and distribution profile exists for that school. Make sure the distribution profile is active.
2. Add app to our Google Analytics account, via https://developers.google.com/mobile/add?platform=ios. Use the Analytics Property "University Map".
3. In the file info.plist, set the Bundle Identifier field equal the App Id. E.g. "com.logicaldimension.uscmap". Note, the App Id is case-sensitive. Also, make sure the field "Bundle versions string, short" has the proper semver version number.
4. In the file GoogleService-Info.plist, set the BUNDLE_ID field equal the App Id.
5. In the file app-settings.plist, set the Campus Code field equal to the campus code as noted in our database, and the Campus Name field equal to however you want the school's name to show up in the app. E.g. "university_of_southern_california_california_us" and "University of Southern California" respectively.
6. Edit the archive scheme. Make sure Archive Name is equal to whatever the name of the app is, i.e. the title that will appear below the app icon. E.g. "USC Map"
7. Make sure provisioning profiles in XCode are up-to-date. To do this: Open the XCode menu option. Select Preferences. In the windows that appears, select the Accounts tab. Click on View Details. In the popup that appears, click the refresh button.
8. Archive the project. Make sure iOS device is selected in build options, not a simulator.
9. After archiving, a window will appear that allows you to submit to the App Store. First, select Validate to validate the archive. Then, select Submit to App Store to submit.*
*Note: this does not submit the app for review by Apple. This merely pushes the archive to make it accessible by iTunes Connect.
10. In iTunes Connect, access the app you want to deploy to. Create a new version and select the build of the archive you just uploaded. 
11. Through iTunes Connect, you can use Test Flight to beta test apps. Afterwards, you can deploy.


##Useful web-based tools for dealing with image resizing for icons and screenshots:
- https://launchkit.io
- http://makeappicon.com (Gotta love that toaster action!)

##Other useful tools
https://github.com/kylef/cocoapods-deintegrate - This is a life saver when trying to rename a project that uses Cocoa Pods!

