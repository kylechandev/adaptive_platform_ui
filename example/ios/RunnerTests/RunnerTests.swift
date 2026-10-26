import Flutter
import UIKit
import XCTest
@testable import adaptive_platform_ui

class RunnerTests: XCTestCase {

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
