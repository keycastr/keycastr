# Developer's notes

## Running and Debugging

After cloning the repository, open the project directory in a terminal or git client and run the following command: `git submodule update --init --recursive`

In order to run KeyCastr in the debugger the built product needs accessibility permissions just as the released app does. Upon first launching a new build in Xcode you may see a fatal error dialog or macOS Security & Privacy prompt. On macOS 10.15 and above, simply click 'Allow' and check the box next to KeyCastr in the Input Monitoring preferences pane. On macOS 10.14 or earlier, open System Preferences -> Privacy -> Accessibility, right click on KeyCastr.app under Built Products in the Xcode project navigator and select 'Show in Finder', and drag KeyCastr.app from the Build/Products folder into the Accessibility list. In Xcode, ctrl-cmd-R to run the same build again.

## Creating a Release
 - Update app version metadata in `Info.plist` and `MainMenu.nib/keyedobjects.nib`
 - Developer ID must be set up for code signing and notarization
 - Archive the app and follow Apple's instructions for uploading a release to be notarized
 - Upon receiving the success notification from Apple, export the notarized build from the project
 - Verify exported artifact is notarized (w/ shell command)
 - Update the zip file in the `bin/` folder to contain the new .app build
 - Create a tag for this version, i.e. `git tag -am'Version <NEW_VERSION>' v<NEW_VERSION>`
 - Push the commits and tags with `git push origin head && git push --tags`
 - Update `https://keycastr.github.io/appcast.xml` with tools bundled with Sparkle
 - Update brew-cask (a community member sometimes gets to it first :) )
