# MyTV: first showcase journey

MyTV is for a viewer who wants to find a channel, see whether a playable stream is available, and return to a favorite later. The catalog and the streams have different failure modes: a channel can exist even when its provider is unreachable.

| Viewer task | Acceptance for the showcase |
|---|---|
| Find a channel | A first-time viewer can search a populated fixture catalog without credentials. An empty search can be cleared. Failure to load availability is distinguishable from a channel with no streams. |
| Watch and recover | Selecting a playable fixture opens the player. An unavailable stream offers a way back to the channel. Leaving the player during preparation must not start playback later. |
| Return to a favorite | Favorite a channel, terminate and relaunch, and find the same channel in Favorites. When offline, retain its saved identity and explain why playback is unavailable. |

**First demo scope:** one repeatable journey on a named simulator, then a physical device. Use media cleared for redistribution and visibly label fixture data. Exclude account creation, catalog-wide stream availability guarantees and commercial distribution from this demo.

**Evidence still needed:** a credential-free showcase entry point, a cleared playback fixture, and a recorded run of the complete journey including recovery. Existing component tests cover parts of it; they do not establish end-to-end acceptance.
