# Diagnosis: StoreKit “Subscribe button does nothing” (and App Review 2.1(a))

## Symptom observed
Apple App Review reported: tapping **Subscribe** on iPad did not respond.

In-app behavior (after adding better error handling): alert shows
`Subscription options are not available right now. Please try again.`

## Code-level root cause (why tap could be silent)
StoreKit product loading/purchase was effectively “silent” when:
- expected subscription `Product` IDs were missing from `SubscriptionManager.products` (or not loadable),
- `product.purchase()` returned `.pending` or `.userCancelled`,
- and the UI only reacted to `purchaseError` or `isPro`.

## StoreKit product identifiers (from code)
File: `MedCertify/ViewModels/SubscriptionManager.swift`
- Annual: `com.medcertify.pro.annual`
- Monthly: `com.medcertify.pro.monthly`

The paywall fetches these products via:
- `Product.products(for: [annualProductID, monthlyProductID])`

## App Store Connect setup issue (Missing Metadata)
App Store Connect showed subscription entries as `Missing Metadata` until you completed:
- Subscription Prices
- Localization (Display Name + Description)
- Subscription Review Screenshot
- (and ensure the subscriptions are attached to the app version under App Review)

Without those, StoreKit may not return the expected products.

## Additional discovered blocker: bundle-id mismatch
What happened:
- App Store Connect app record bundle id (shown in screenshot): `com.socialreporthq.credvault`
- Xcode project (initially) used: `com.socialreporthq.medcertify`
- StoreKit can only retrieve subscription products if the build’s **bundle identifier** matches the App Store Connect app record.

## Fix applied to remove silent failures (code hardening)
1. `MedCertify/ViewModels/SubscriptionManager.swift`
   - `loadProducts()` now sets `purchaseError` when:
     - product load fails, or
     - expected annual/monthly product IDs are missing
   - `purchaseAnnual()` / `purchaseMonthly()` now set `purchaseError` when the matching `Product` isn’t found (no more no-op return).
   - `purchase(_:)` now sets `purchaseError` for `.userCancelled` and `.pending`.

2. `MedCertify/Views/Onboarding/PaywallView.swift`
   - Added `isLoadingProducts` state
   - Disabled Subscribe/Restore while products are loading
   - Shows the existing SwiftUI alert once `purchaseError` is set.

## Fix applied to align the App Store app record
Updated Xcode project bundle id:
- `MedCertify.xcodeproj/project.pbxproj`
  - `PRODUCT_BUNDLE_IDENTIFIER` for `MedCertify` target:
    - Debug/Release: `com.socialreporthq.medcertify` -> `com.socialreporthq.credvault`
  - Tests/UITests bundle ids were left unchanged.

## Practical checklist for the next app (repeat this)
1. Verify **App Store Connect app record bundle id** matches the archived build’s bundle id exactly.
2. Ensure both subscription SKUs exist and are fully configured:
   - Prices (for the testing territories/currencies)
   - Localization
   - Review screenshot
3. Ensure subscriptions are attached to the exact app version you’re submitting.
4. Fresh install / clean device test after changing bundle id.
5. Confirm Subscribe:
   - shows Apple purchase sheet, or
   - shows an in-app error (never silent no-op).

