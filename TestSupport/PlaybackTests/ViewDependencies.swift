// Display-only dependencies; the test runner copies the production playback logic unchanged.
struct OfflineBannerViewModel { static let `default` = Self() }
struct LoadingViewModel { static let streamPreparationDefault = Self() }
enum Localizable {
    enum App { static let ok = "OK" }
    enum Stream {
        enum List { enum Empty { static let title = "Empty"; static let message = "No streams" } }
        enum Player { enum Error {
            static let title = "Playback error"
            static let noWorkingStreams = "No working streams"
            static let invalidURL = "Invalid URL"
            static let cannotPlay = "Cannot play"
        } }
    }
}
