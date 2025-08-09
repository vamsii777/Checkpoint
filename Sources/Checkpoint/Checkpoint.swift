//
//  RateLimitMiddleware.swift
//  
//
//  Created by Adolfo Vera Blasco on 13/6/24.
//

import Redis
import Vapor

public typealias CheckpointHandler = @Sendable (Request) -> Void
public typealias CheckpointRateLimitHandler = @Sendable (Request, Response, Checkpoint.ErrorMetadata) -> Void
public typealias CheckpointErrorHandler = @Sendable (Request, Response, AbortError, Checkpoint.ErrorMetadata) -> Void

public actor Checkpoint {
	private let algorithm: any Algorithm
	
	nonisolated(unsafe) public var willCheck: CheckpointHandler?
	nonisolated(unsafe) public var didCheck: CheckpointHandler?
	nonisolated(unsafe) public var didFailWithTooManyRequest: CheckpointRateLimitHandler?
	nonisolated(unsafe) public var didFail: CheckpointErrorHandler?
	
	public init(using algorithm: some Algorithm) {
		self.algorithm = algorithm
	}
	
}

extension Checkpoint: AsyncMiddleware {
	public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		let response = try await next.respond(to: request)
		
		do {
			willCheck?(request)
			try await checkRateLimitFor(request: request)
			didCheck?(request)
		} catch let abort as AbortError {
			let errorMetadata = ErrorMetadata()
			
			switch abort.status {
				case .tooManyRequests:
					didFailWithTooManyRequest?(request, response, errorMetadata)
					
					throw Abort(.tooManyRequests,
								headers: errorMetadata.httpHeaders,
								reason: errorMetadata.reason)
				default:
					didFail?(request, response, abort, errorMetadata)
					
					throw Abort(.badRequest,
								headers: errorMetadata.httpHeaders,
								reason: errorMetadata.reason)
			}
		}

		return response
	}
	
	private func checkRateLimitFor(request: Request) async throws {
		try await algorithm.checkRequest(request)
	}
}

public extension Checkpoint {
	final class ErrorMetadata {
		public var headers: [String : String]?
		public var reason: String?
		
		var httpHeaders: HTTPHeaders {
			var httpHeaders = HTTPHeaders()
			
			guard let headers else {
				return httpHeaders
			}
			
			for (key, content) in headers {
				httpHeaders.add(name: key, value: content)
			}
			
			return httpHeaders
		}
	}
}

extension Checkpoint {
	enum HTTPErrorDescription {
		static let unauthorized = "X-Api-Key header not available in the request"
		static let rateLimitReached = "You have exceed your ApiKey network requests rate"
	}
}
