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

    func test_getFromURL_performsGETRequestWithURL() {
        let exp = expectation(description: "Wait for request")
        exp.expectedFulfillmentCount = 2

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, request.url)
            XCTAssertEqual(request.httpMethod, request.httpMethod)
            exp.fulfill()
        }
        sut.get(from: url, completion: { _ in exp.fulfill() })
        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {
        let error = NSError(domain: "any error", code: 0)

        let capturedError = resultErrorFor(data: nil, response: nil, error: error)
        XCTAssertEqual((capturedError as NSError?)?.domain, error.domain)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let nonHttpResponse = URLResponse()
        let anyHttpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data()
        let anyError = NSError(domain: "any error", code: 0)
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))

        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHttpResponse, error: nil))

        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHttpResponse, error: nil))

        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHttpResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHttpResponse, error: anyError))

        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHttpResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHttpResponse, error: anyError))
    }

    func test_getFromURL_SuccessOnHTTPResponseWithData() {
        let anyHttpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data()

        URLProtocolStub.stub(data: anyData, response: anyHttpResponse, error: nil)

        let expectation = expectation(description: "")

        sut.get(from: url) { result in
            switch result {
            case let .success((response, data)):
                XCTAssertEqual(data, anyData)
                XCTAssertEqual(response.statusCode, anyHttpResponse?.statusCode)
                XCTAssertEqual(response.url, anyHttpResponse?.url)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_getFromURL_SuccessOnHTTPResponseWithEmptyData() {
        let anyHttpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data()

        URLProtocolStub.stub(data: nil, response: anyHttpResponse, error: nil)

        let expectation = expectation(description: "")

        sut.get(from: url) { result in
            switch result {
            case let .success((response, data)):
                XCTAssertEqual(data, Data())
                XCTAssertEqual(response.statusCode, anyHttpResponse?.statusCode)
                XCTAssertEqual(response.url, anyHttpResponse?.url)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)

        let expectation = expectation(description: "")
        var capturedError: Error?
        sut.get(from: url) { result in
            switch result {
            case .failure(let error):
                capturedError = error
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        return capturedError
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


