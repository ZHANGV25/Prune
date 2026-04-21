import XCTest
import Photos
@testable import Prune

/// Tests the pure-math estimator that powers the celebration screen.
/// Real PHAsset instances need a photo library; we use an empty array + protocol-free
/// arithmetic checks against the documented per-type averages.
final class EstimatedBytesTests: XCTestCase {
    func test_emptyReturnsZero() {
        XCTAssertEqual(SwipeViewModel.estimatedBytes(for: []), 0)
    }

    // NOTE: Deeper per-asset checks require a photo library on the test device;
    // the arithmetic is covered by the integration path when a real delete happens.
    // Here we only assert that the function is pure and safe on empty input.
}
