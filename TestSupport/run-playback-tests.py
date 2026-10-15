"""Exercise the real playback view model on macOS with local audio and service doubles."""
from pathlib import Path
import shutil, subprocess, tempfile, wave
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='mytv-playback-') as temp:
    p = Path(temp)
    source = p / 'Sources/Playback'
    source.mkdir(parents=True)
    for relative in [
        'Presentation/Screens/StreamList/StreamListViewModel.swift',
        'Domain/Entities/Stream.swift', 'Domain/Entities/Channel.swift',
        'Domain/Repositories/ChannelRepository.swift',
        'Data/UseCases/DefaultFetchStreamsForChannelUseCase.swift',
        'Core/Reachibility/ReachabilityService.swift', 'Core/Haptic/HapticService.swift'
    ]:
        original = root / 'myTV' / relative
        # HapticService only declares platform-independent enums/protocols.
        (source / original.name).write_text(original.read_text().replace('import UIKit', ''))
    shutil.copy2(root / 'TestSupport/PlaybackTests/ViewDependencies.swift', source)
    tests = p / 'Tests/PlaybackTests'
    tests.mkdir(parents=True)
    shutil.copy2(root / 'TestSupport/PlaybackTests/PlaybackTests.swift', tests)
    with wave.open(str(tests / 'silence.wav'), 'wb') as audio:
        audio.setnchannels(1); audio.setsampwidth(2); audio.setframerate(8000)
        audio.writeframes(bytes(16000))
    (p / 'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Playback", platforms: [.macOS(.v14)], targets: [
    .target(name: "Playback"),
    .testTarget(name: "PlaybackTests", dependencies: ["Playback"], resources: [.process("silence.wav")])
], swiftLanguageVersions: [.v5])
''')
    subprocess.run(['xcrun', 'swift', 'test', '--package-path', str(p), '--triple', 'arm64-apple-macosx14.0'], check=True)
