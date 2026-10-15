from pathlib import Path
import tempfile,subprocess,shutil,json
root=Path(__file__).resolve().parents[1]
features=['DisableOutwardActorInference','InferSendableFromCaptures','GlobalActorIsolatedTypesUsability','MemberImportVisibility','InferIsolatedConformances','NonisolatedNonsendingByDefault']
flags=['-default-isolation','MainActor']+[x for f in features for x in ['-enable-upcoming-feature',f]]
with tempfile.TemporaryDirectory(prefix='mytv-adapter-') as temp:
 p=Path(temp);(p/'Sources/Adapter').mkdir(parents=True);(p/'Tests/AdapterTests').mkdir(parents=True)
 shutil.copy2(root/'myTV/Data/Network/Client/HTTPClient.swift',p/'Sources/Adapter/HTTPClient.swift')
 shutil.copy2(root/'TestSupport/LegacyHTTPClient.swift',p/'Sources/Adapter/Legacy.swift')
 shutil.copy2(root/'TestSupport/AdapterTests.swift',p/'Tests/AdapterTests/AdapterTests.swift')
 (p/'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Adapter", platforms: [.macOS(.v14)], dependencies: [.package(url: "https://github.com/Anurag-Chourasia/CommonNetworking.git", exact: "1.1.0")], targets: [.target(name: "Adapter", dependencies: [.product(name: "CommonNetworking", package: "CommonNetworking")], swiftSettings: [.unsafeFlags(FLAGS)]), .testTarget(name: "AdapterTests", dependencies: ["Adapter"])], swiftLanguageVersions: [.v5])
'''.replace('FLAGS',json.dumps(flags)))
 subprocess.run(['xcrun','swift','test','--package-path',str(p),'--triple','arm64-apple-macosx14.0','-Xswiftc','-strict-concurrency=complete','-Xswiftc','-warnings-as-errors'],check=True)
