We are using CocoaPods for RestKit/AFNetworking

Installation
---
* Install Homebrew
* Install Latest version of git (>1.8)
* Then:

```
sudo gem install cocoapods
pod setup
git clone git@github.com:switchcam/switchcam-ios.git
cd switchcam-ios
pod install
```

**If building the project fails with errors like:**

```
Undefined symbols for architecture i386:
  "_OBJC_CLASS_$_TestFlight", referenced from:
      objc-class-ref in AppDelegate.o
ld: symbol(s) not found for architecture i386
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

Then you need to download and install the Testflight SDK, following the integration steps at https://testflightapp.com/sdk/doc/1.0beta1/
