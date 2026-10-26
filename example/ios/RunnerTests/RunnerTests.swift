import Flutter
import UIKit
import XCTest
@testable import adaptive_platform_ui

class RunnerTests: XCTestCase {

  /// Native highlight tracking must not make the custom long press fail.
  func testLongPressCoexistsOnlyWithTabBarGestures() {
    let platform = iOS26TabBarPlatformView(
      frame: CGRect(x: 0, y: 0, width: 430, height: 83), viewId: 42,
      args: ["labels": ["Home", "Add"], "sfSymbols": ["house", "plus"], "longPressEnabled": true],
      messenger: TestBinaryMessenger()
    )
    let bar = platform.view().subviews.compactMap { $0 as? UITabBar }.first!
    let longPress = bar.gestureRecognizers!.first { $0.delegate === platform }!
    XCTAssertTrue(longPress.isEnabled)

    let highlight = UILongPressGestureRecognizer()
    let buttonView = UIView()
    bar.addSubview(buttonView)
    buttonView.addGestureRecognizer(highlight)
    XCTAssertTrue(platform.gestureRecognizer(longPress, shouldRecognizeSimultaneouslyWith: highlight))
    bar.addGestureRecognizer(highlight)
    XCTAssertTrue(platform.gestureRecognizer(longPress, shouldRecognizeSimultaneouslyWith: highlight))

    let outsideView = UIView()
    outsideView.addGestureRecognizer(highlight)
    XCTAssertFalse(platform.gestureRecognizer(longPress, shouldRecognizeSimultaneouslyWith: highlight))
  }

  /// Exercise real UIKit tab layouts across widths and writing directions.
  func testNativeLongPressItemGeometry() {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 430, height: 900))
    let controller = UIViewController()
    window.rootViewController = controller
    window.makeKeyAndVisible()
    defer { window.isHidden = true }

    for direction in [UISemanticContentAttribute.forceLeftToRight, .forceRightToLeft] {
      for width in [320.0, 430.0, 844.0] {
        let bar = UITabBar(frame: CGRect(x: 0, y: 0, width: width, height: 83))
        bar.semanticContentAttribute = direction
        bar.items = (0..<5).map { UITabBarItem(title: "Tab \($0)", image: UIImage(systemName: "house"), tag: $0) }
        controller.view.addSubview(bar)
        bar.layoutIfNeeded()

        var indices = Set<Int>()
        for x in stride(from: 0.0, to: width, by: 2.0) {
          for y in stride(from: 0.0, to: 83.0, by: 2.0) {
            if let index = bar.longPressItemIndex(at: CGPoint(x: x, y: y)) {
              if indices.insert(index).inserted {
                var hit = bar.hitTest(CGPoint(x: x, y: y), with: nil)
                while let view = hit, !(view is UIControl) { hit = view.superview }
                XCTAssertEqual(hit?.accessibilityLabel, bar.items?[index].title)
              }
            }
          }
        }
        XCTAssertEqual(indices, Set(0..<5), "Missing native buttons at width \(width), direction \(direction)")
        let hits = stride(from: 0.0, to: width, by: 2.0).compactMap {
          bar.longPressItemIndex(at: CGPoint(x: $0, y: 30))
        }
        XCTAssertFalse(hits.isEmpty)
        XCTAssertEqual(hits, direction == .forceRightToLeft ? hits.sorted(by: >) : hits.sorted())
        XCTAssertNil(bar.longPressItemIndex(at: CGPoint(x: -1, y: 30)))
        XCTAssertNil(bar.longPressItemIndex(at: CGPoint(x: width + 1, y: 30)))
        bar.removeFromSuperview()
      }
    }
  }

}

/// Register native channels without starting a Dart engine in gesture tests.
private final class TestBinaryMessenger: NSObject, FlutterBinaryMessenger {
  /// Discard outbound messages; this test exercises native gesture arbitration.
  func send(onChannel channel: String, message: Data?) {}

  /// Complete requests so native code never waits on an absent Dart isolate.
  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
    callback?(nil)
  }

  /// Accept channel registrations without retaining the platform view.
  func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
    return 1
  }

  /// No channel state is retained by this test messenger.
  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}
