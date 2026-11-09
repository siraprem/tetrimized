# TETR.IO request filtering

The app uses a small, local, opt-out rule set (`TETRIMIZED_ADBLOCK=false` disables it at build time). No remote filter list, background service, timer, MutationObserver, or per-request Dart callback is used.

## Why Android uses a local native fork

The pinned upstream `flutter_inappwebview_android` 1.1.3 ContentBlocker determines a request's resource type by issuing an HTTP `HEAD` for each URL before matching rules (`ContentBlockerHandler.getResourceTypeFromUrl`). That is not appropriate on the request path of a performance-sensitive game. The local fork therefore checks hostnames in native `shouldInterceptRequest` and returns an empty 204 response before sending matching requests to the network. A precompiled regex also cancels matching subframe navigations. The Android rule is enabled only when the configured regex matches the Tetrimized marker exactly. iOS/macOS use WebKit's native content-rule implementation.

## Observed hosts and policy

A clean-profile Waydroid run of the TETR.IO landing page, without login or gameplay, exposed these advertising/auction/identity hosts and resource initiators through the browser Performance API:

- `pub.network` — scripts, fetches, links, images
- `doubleclick.net`, `googletagservices.com`, `googlesyndication.com` — Google ad delivery/auction resources
- `amazon-adsystem.com` — Amazon ad/APS resources
- `gum.criteo.com`, `id5-sync.com`, `id.hadron.ad.gt`, `cdn.hadronid.net`, `match.adsrvr.org`, `id.a-mx.com`, `intentiq.com` — ad/identity matching resources
- `live.primis.tech`, `tag.durationmedia.net`, `s0.2mdn.net` — ad/video delivery resources

The rule matches only these host roots and their subdomains. It intentionally does not block `tetr.io`, game/content hosts such as `kagari.online` and `moon.kagari.moe`, Sentry, Xsolla, or Google's Funding Choices consent host. Other observed third-party hosts are left alone until their purpose is verified.

The browser `initiatorType` is an indication of how a resource was requested, not a definitive server-side MIME/resource classification. TETR.IO changes its ad auctions and third-party hosts, so the list needs periodic review and regression testing.

## Validation limits

The headless smoke test verifies page readiness and the injected key function and prints resource initiators, WebView timing, Android PSS, CPU, and UI-frame summaries. One clean-profile Waydroid A/B run saw 250 resource entries with filtering off and 169 with filtering on; the ad-provider selection and network are dynamic, so this single comparison does not prove a stable performance improvement. It verifies the page remains loadable, not gameplay or Galaxy A14 performance. Repeat A/B runs and test account/login/game-critical flows before treating the rules as release-ready.
