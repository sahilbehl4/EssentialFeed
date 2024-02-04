//
//  HTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Sahil Behl on 8/6/23.
//

import XCTest

@testable import EssentialFeed

final class HTTPClientTest: XCTestCase {
    var sut: HTTPClient!
    let url = URL(string: "www.test.com")!

    override func setUp() {
        super.setUp()
        sut = URLSessionHTTPClient()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_getFromURL_failsOnRequestError() async throws {
        let error = NSError(domain: "any error", code: 0)
        let capturedError = await resultErrorFor(data: nil, response: nil, error: error)
        XCTAssertEqual((capturedError as NSError?)?.domain, error.domain)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() async throws {
        let nonHttpResponse = URLResponse()
        let anyHttpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data()
        let anyError = NSError(domain: "any error", code: 0)
        var capturedError = await resultErrorFor(data: nil, response: nil, error: nil)
        XCTAssertNotNil(capturedError)
        
        capturedError = await resultErrorFor(data: anyData, response: nil, error: nil)
        XCTAssertNotNil(capturedError)
        
        capturedError = await resultErrorFor(data: anyData, response: nil, error: anyError)
        XCTAssertNotNil(capturedError)

        capturedError = await resultErrorFor(data: nil, response: nonHttpResponse, error: nil)
        XCTAssertNotNil(capturedError)

        capturedError = await resultErrorFor(data: anyData, response: nonHttpResponse, error: nil)
        XCTAssertNotNil(capturedError)

        capturedError = await resultErrorFor(data: nil, response: nonHttpResponse, error: anyError)
        XCTAssertNotNil(capturedError)
        
        capturedError = await resultErrorFor(data: nil, response: anyHttpResponse, error: anyError)
        XCTAssertNotNil(capturedError)

        capturedError = await resultErrorFor(data: anyData, response: nonHttpResponse, error: anyError)
        XCTAssertNotNil(capturedError)
        
        capturedError = await resultErrorFor(data: anyData, response: anyHttpResponse, error: anyError)
        XCTAssertNotNil(capturedError)
    }

    func test_getFromURL_SuccessOnHTTPResponseWithData() async throws {
        let anyHttpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data()

        URLProtocolStub.stub(data: anyData, response: anyHttpResponse, error: nil)
        
        do {
            let (data, response) = try await sut.get(from: url)
            XCTAssertEqual(data, anyData)
            XCTAssertEqual(response.statusCode, anyHttpResponse?.statusCode)
            XCTAssertEqual(response.url, anyHttpResponse?.url)
        } catch {
            XCTFail()
        }
    }

    func test_getFromURL_SuccessOnHTTPResponseWithEmptyData() async throws {
        let anyHttpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)

        URLProtocolStub.stub(data: nil, response: anyHttpResponse, error: nil)

        do {
            let (data, response) = try await sut.get(from: url)
            XCTAssertEqual(data, Data())
            XCTAssertEqual(response.statusCode, anyHttpResponse?.statusCode)
            XCTAssertEqual(response.url, anyHttpResponse?.url)
        } catch {
            XCTFail()
        }
    }

    func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) async -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)

        do {
            _ = try await sut.get(from: url)
            XCTFail()
        } catch {
            return error
        }

        return nil
    }

    func test_memoryLeaks() {
        let sutLeak = URLSessionHTTPClient()
        addTeardownBlock { [weak sutLeak] in
            XCTAssertNil(sutLeak)
        }
    }

    private class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}


