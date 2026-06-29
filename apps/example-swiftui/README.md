# @rheo/example-swiftui

Runnable SwiftUI example for **RheoSwiftUI**, mirroring [`@rheo/example-expo`](../example-expo): a config screen, then `RheoProvider` + `FlowView` against a local API.

## Prerequisites

- **Xcode** with the **iOS Simulator** runtime installed
- Local Rheo API on port **4000** (see below)

## Setup

From the monorepo root:

```bash
pnpm install

# API + dashboard + this example on the iOS Simulator
pnpm dev:local:app:swiftui
# or with stress ClickHouse data:
pnpm dev:local:app:stress:swiftui
```

Standalone build/launch (API already running):

```bash
pnpm --filter @rheo/example-swiftui build
pnpm --filter @rheo/example-swiftui run
```

Or open the package in Xcode and press Run:

```bash
pnpm --filter @rheo/example-swiftui open
```

Select the **RheoExampleSwiftUI** scheme and an **iPhone** simulator.

## First launch

The config form asks for the same fields as the Expo example:

| Field | Example |
| --- | --- |
| Publishable key | `ob_pk_test_…` from the dashboard |
| Channel id | `ch_test_…` pinned to a published flow |
| API base URL | `http://127.0.0.1:4000` (iOS Simulator → host machine) |
| User id | any stable id (e.g. `example-user`) |

Tap **Start flow** to mount `RheoProvider` + `FlowView`. OAuth and email/password auth layers resolve with stub handlers (same behavior as the Expo sample). When the flow completes or is abandoned, you return to the config screen.

**Hide navigation bar in flow:** enable on the config screen to hide the navigation title and back button while `FlowView` runs. Default off.

**Offline resolve fallback:** enable **Offline resolve fallback** on the config screen (default on). Stop the API or set a bad API URL, then start the flow — you should see the hardcoded `OfflineResolveFallbackView` instead of the live manifest. Turn the toggle off to use the SDK default error (“Error to load the content” + Try again).

Settings are stored in **UserDefaults** under `rheo.exampleConfig.v1`.

## AppsFlyer (optional)

To exercise MMP attribution with `appsFlyerAttribution: .automatic`, add your AppsFlyer dev key to `Support/Info.plist`:

```xml
<key>RHEO_EXAMPLE_APPSFLYER_DEV_KEY</key>
<string>your_dev_key</string>
<key>RHEO_EXAMPLE_APPSFLYER_IOS_APP_ID</key>
<string>1234567890</string>
```

Link **AppsFlyerLib** in the example target (CocoaPods or SPM), enable **AppsFlyer** for the app in the dashboard, and run on a **dev build** (not required for basic flow testing).

## Local API URL

The bundled `Support/Info.plist` sets `NSAllowsLocalNetworking` so HTTP to `127.0.0.1` works in the simulator. Use `http://127.0.0.1:4000`, not `localhost`, if you hit connection issues.

## Verifying events

After completing a flow, query ClickHouse the same way as the Expo README (`flow_started`, `step_viewed`, `flow_completed`, etc.).

## Scripts

| Command | Action |
| --- | --- |
| `pnpm --filter @rheo/example-swiftui build` | `xcodebuild` for the iOS Simulator |
| `pnpm --filter @rheo/example-swiftui run` | Build, install, and launch on a simulator |
| `pnpm --filter @rheo/example-swiftui open` | Open `Package.swift` in Xcode |

### Choosing a simulator

When you run `pnpm --filter @rheo/example-swiftui run` in a terminal, the script lists every available **iOS** simulator and asks you to pick one (newest OS first).

Skip the menu and pin a device instead:

```bash
# env vars (also used by dev:local scripts)
SWIFTUI_SIMULATOR_NAME="iPhone 16" SWIFTUI_SIMULATOR_OS=18.4 \
  pnpm --filter @rheo/example-swiftui run

# CLI flags
node scripts/run-swiftui-example.mjs run --device "iPhone 16" --os 18.4

# show the menu even if env vars are set
node scripts/run-swiftui-example.mjs run --pick
```

Defaults when nothing is set and stdin is not a TTY: `iPhone 17 Pro`, iOS `26.5`.
