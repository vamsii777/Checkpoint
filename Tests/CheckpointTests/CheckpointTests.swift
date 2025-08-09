import Redis
import XCTest
import XCTVapor
@testable import Checkpoint

final class CheckpointTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
	
	func testLeakingBucket() {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("leaking-bucket") { request -> HTTPStatus in
			return .ok
		}
		
		let leakingBucketAlgorithm = LeakingBucket {
			LeakingBucketConfiguration(bucketSize: 10, 
									   removingRate: 5,
									   removingTimeInterval: .minutes(count: 1))
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 6379,
																	 database: 0)
			
			return app.redis("rate")
		}
		
		let checkpoint = Checkpoint(using: leakingBucketAlgorithm)
		
		app.middleware.use(checkpoint)
		
		(0...20).forEach { index in
			try? app.test(.GET, "leaking-bucket", afterResponse: { testResponse in
				app.logger.info("\(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
	
	func testTokenBucket() throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("token-bucket") { request -> HTTPStatus in
			return .ok
		}
		
		let tokenbucketAlgorithm = TokenBucket {
			TokenBucketConfiguration(bucketSize: 10,
									 refillRate: 0,
									 refillTimeInterval: .seconds(count: 20))
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 6379,
																	 database: 0)
			
			return app.redis("rate")
		} logging: {
			app.logger
		}
		
		let checkpoint = Checkpoint(using: tokenbucketAlgorithm)
		
		app.middleware.use(checkpoint)
		
		(0...20).forEach { index in
			try? app.test(.GET, "token-bucket", afterResponse: { testResponse in
				app.logger.info("\(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
	
	func testFixedWindowCounter() {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("fixed-window-counter") { request -> HTTPStatus in
			return .ok
		}
		
		let fixedWindowAlgorithm = FixedWindowCounter {
			FixedWindowCounterConfiguration(requestPerWindow: 10,
											timeWindowDuration: .minutes(count: 2))
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 6379,
																	 database: 0)
			
			return app.redis("rate")
		}
		
		
		let checkpoint = Checkpoint(using: fixedWindowAlgorithm)
		
		app.middleware.use(checkpoint)
		
		(0...20).forEach { index in
			try? app.test(.GET, "fixed-window-counter", afterResponse: { testResponse in
				app.logger.info("\(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
	
	func testSlidingWindowLog() {
		let app = Application(.testing)
		defer { app.shutdown() }
		
		app.get("sliding-window-log") { request -> HTTPStatus in
			return .ok
		}
		
		let slidingWindowLogAlgorith = SlidingWindowLog {
			SlidingWindowLogConfiguration(requestPerWindow: 10,
										  windowDuration: .minutes(count: 2))
		} storage: {
			// Rate limit database in Redis
			app.redis("rate").configuration = try? RedisConfiguration(hostname: "localhost",
																	 port: 6379,
																	 database: 0)
			
			return app.redis("rate")
		}
		
		
		let checkpoint = Checkpoint(using: slidingWindowLogAlgorith)
		
		app.middleware.use(checkpoint)
		
		(0...20).forEach { index in
			try? app.test(.GET, "sliding-window-log", afterResponse: { testResponse in
				app.logger.info("\(index) = \(testResponse.status)")
				if index < 10 {
					XCTAssertEqual(testResponse.status, .ok)
				} else {
					XCTAssertEqual(testResponse.status, .tooManyRequests)
				}
			})
		}
	}
}
