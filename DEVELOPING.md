# Developer's notes

## Running and Debugging

After cloning the repository, open the project directory in a terminal or git client and run the following command: `git submodule update --init --recursive`

In order to run KeyCastr in the debugger the built product will need accessibility or input monitoring permissions just as the released app does. Remove any existing references to KeyCastr from the Accessibility and/or Input Monitoring sections in the Security & Privacy pane within the System Preferences.app. Locate the built product created by Xcode and drag it into the Accessibility or Input Monitoring list. Use ctrl-cmd-R in Xcode to run the same build again.

## Creating a Release
 - Update app version metadata in `Info.plist`
  - note that Sparkle uses kCFBundleVersionKey for its update version comparison, which shows up in the "Build" field in Xcode
 - Developer ID must be set up for code signing and notarization
 - Archive the app and follow Apple's instructions for uploading a release to be notarized
 - Upon receiving the success notification from Apple, export the notarized build from the project
 - Verify exported artifact is notarized (w/ shell command)
 - Update the zip file in the `bin/` folder to contain the new .app build
 - Commit the `Info.plist` and updated app zip and create a tag for this version, i.e. `git tag -am'Version <NEW_VERSION>' v<NEW_VERSION>`
 - Push the commits and tags with `git push origin head && git push --tags`
 - Create the release on GitHub from the recently pushed tag and attach the zipped copy of the app
 - Update `https://keycastr.github.io/appcast.xml` using the `generate_appcast` tool bundled with Sparkle
 - Update Homebrew cask using `brew bump-cask-pr` (a community member sometimes gets to it first :) )
