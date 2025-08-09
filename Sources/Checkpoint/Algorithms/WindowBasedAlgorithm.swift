//
//  WindowBasedLimiter.swift
//  
//
//  Created by Adolfo Vera Blasco on 17/6/24.
//

#if canImport(Combine)
import Combine
#else
import OpenCombine
#endif
import Foundation
import Dispatch

public typealias WindowBasedAction = @Sendable () throws -> Void

/// For those algorithims thar works with fixed time windows.
public protocol WindowBasedAlgorithm: Algorithm {
	/// Start the timer for a given duration (time window)
	func startWindow(havingDuration seconds: Double, performing action: @escaping WindowBasedAction) -> AnyCancellable
	/// Perfomrs the reset operation when the time windo ends.
	func resetWindow() async throws
}

extension WindowBasedAlgorithm {
	public func startWindow(havingDuration seconds: Double, performing action: @escaping WindowBasedAction) -> AnyCancellable {
		#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
		// Use Timer.publish on Apple platforms
		return Timer.publish(every: seconds, on: .main, in: .common)
			.autoconnect()
			.sink { _ in
				do {
					try action()
				} catch let timerError {
					self.logging?.error("🚨 Something wrong at timer: \(timerError.localizedDescription)")
				}
			}
		#else
		// Use DispatchSourceTimer for other platforms (Linux, etc.)
		let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		timer.schedule(deadline: .now() + seconds, repeating: seconds)
		timer.setEventHandler {
			do {
				try action()
			} catch let timerError {
				self.logging?.error("🚨 Something wrong at timer: \(timerError.localizedDescription)")
			}
		}
		timer.resume()
		
		// Return an AnyCancellable that cancels the timer
		return AnyCancellable {
			timer.cancel()
		}
		#endif
	}
}

