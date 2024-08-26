import XCTest

@testable import howto

class ConfigTests: XCTestCase {
    func testNewConfigWithGoogleEngine() {
        let result = Config.new(engineType: "google", num: 5)

        switch result {
        case let .success(config):
            XCTAssert(config.engine is GoogleEngine)
            XCTAssertEqual(config.num, 5)
        case .failure:
            XCTFail("Config creation should not fail for valid input")
        }
    }

    func testNewConfigWithBingEngine() {
        let result = Config.new(engineType: "bing", num: 10)

        switch result {
        case let .success(config):
            XCTAssert(config.engine is BingEngine)
            XCTAssertEqual(config.num, 10)
        case .failure:
            XCTFail("Config creation should not fail for valid input")
        }
    }

    func testNewConfigWithInvalidEngine() {
        let result = Config.new(engineType: "yahoo", num: 5)

        switch result {
        case .success:
            XCTFail("Config creation should fail for invalid engine")
        case let .failure(error):
            XCTAssertEqual(error, .invalidSearchEngine)
        }
    }

    func testNewConfigCaseInsensitivity() {
        let result = Config.new(engineType: "GoOgLe", num: 5)

        switch result {
        case let .success(config):
            XCTAssert(config.engine is GoogleEngine)
        case .failure:
            XCTFail("Config creation should not fail for case-insensitive input")
        }
    }

    func testNewConfigWithInvalidNumber() {
        let result = Config.new(engineType: "google", num: 0)

        switch result {
        case .success:
            XCTFail("Config creation should fail for invalid number")
        case let .failure(error):
            XCTAssertEqual(error, .invalidNumber)
        }
    }
}
