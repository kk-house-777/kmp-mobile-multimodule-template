import ProjectDescription

let bundleId = "$(PRODUCT_BUNDLE_IDENTIFIER)"
let project = Project(
    name: "ios-app",
    settings: .settings(configurations: [
        .debug(name: "Debug", xcconfig: "./xcconfigs/ios-app.xcconfig"),
        .release(name: "Release", xcconfig: "./xcconfigs/ios-app.xcconfig"),
    ]),
    targets: [
        .target(
            name: "ios-app",
            destinations: .iOS,
            product: .app,
            bundleId: "\(bundleId)",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    // CMP Integration
                    "CADisableMinimumFrameDurationOnPhone": true
                ]
            ),
            sources: ["ios-app/**"],
            resources: ["ios-app/**"],
            dependencies: [
                .target(name: "Feature"),
            ]
        ),
        .target(
            name: "KMPFramework",
            destinations: .iOS,
            product: .framework,
            bundleId: "\(bundleId).kmp.framework",
            sources: ["KMPFramework/**"],
            scripts: [
                .pre(
                    script: """
                            cd "$SRCROOT/.."
                            ./gradlew :ios:kmp-umbrella:embedAndSignAppleFrameworkForXcode
                            """,
                    name: "Compile Kotlin Framework"
                )
            ],
            settings: .settings(base: [
                "FRAMEWORK_SEARCH_PATHS": "kmp-umbrella/build/xcode-frameworks/**",
                "OTHER_LDFLAGS": "-framework shared" // フレームワークの名称と合わせる
            ])
        ),
        .target(
            name: "Feature",
            destinations: .iOS,
            product: .framework,
            bundleId: "\(bundleId).feature",
            sources: ["Feature/**"],
            dependencies: [
                .target(name: "KMPFramework")
            ]
        )
    ]
)
