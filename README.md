# MyPremiumPal

A tweak to unlock premium features in MyFitnessPal app by intercepting and modifying API responses.

## Requirements
- iOS 18+
- Ability to sideload with a custom dylib

## Features
This tweak provides the following premium features:
- Unlocks Premium+ tier subscription
- Enables all premium features by modifying their entitlement status
- Works by intercepting the GetSubscriptionSummary GraphQL response

## Installation

### Using Sideloadly:
1. Download the official MyFitnessPal IPA from the App Store using a tool like ipatool or iMazing
2. Download the compiled `MyPremiumPal.dylib` from the releases or build it yourself
3. Open Sideloadly and load the MyFitnessPal IPA
4. In the `Advnced Options` menu:
   - Enable "Inject dylibs/frameworks"
   - Add the `MyPremiumPal.dylib` file
   - You do not need to have "Cydia Substrate", "Substitute", or "Sideload Spoofer" checked
5. Click Start to sign with your Apple Developer account and install to your device

## How It Works
This tweak uses method swizzling to hook into NSURLSession's `dataTaskWithRequest:completionHandler:` method. It specifically targets the GetSubscriptionSummary GraphQL operation and modifies the JSON response to:

1. Set `currentTier` to "PREMIUM_PLUS"
2. Set `hasPremium` to YES
3. Modify all features to have "ENTITLED" `entitlement` status
4. Set all features to "PREMIUM_PLUS" `subscriptionTier`

The modified response is then passed back to the app, making it think you have a valid premium subscription.

## Development
### Prerequisites
- [Theos](https://theos.dev/docs/installation) development environment
- For optimal building, install one of the following plist utilities:
  - `plutil` (macOS, included by default)
  - `libplist-utils` (Linux: `apt-get install libplist-utils`)
  - `ply` (Cross-platform Python library: `pip install ply`)

### Building
To compile:

```bash
# Build the dylib
make
```

The dylib file will be located in `.theos/obj/debug/` directory.

## Compatibility
- Tested with MyFitnessPal version 25.11.1
- Supports arm64 architecture

## Disclaimer
This is for educational purposes only. Please support developers by purchasing premium subscriptions. 