//
//  DictionaryExtensionTest.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import XCTest

class DictionaryExtensionTest: XCTestCase {
	
	let testDict = [
		"a": [1, 2],
		"c": [4]
	]
	
	var dict: [String: [Int]] = [:]
    
    override func setUp() {
        super.setUp()
        dict = testDict
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAppendToExisting() {
		dict.append(3, to: "a")
		let expected = [1, 2, 3]
		XCTAssert(dict["a"] ?? [] == expected, "Incorrect result appending item to existing container: expected \(expected) but found \(dict["a"])")
    }
	
	func testAppendToNew() {
		dict.append(0, to: "b")
		let expected = [0]
		XCTAssert(dict["b"] ?? [] == expected, "Incorrect result appending item to new container: expected \(expected) but found \(dict["b"])")
	}
	
	func testAppendContentsOfToExisting() {
		dict.appendContents(of: [3, 4], to: "a")
		let expected = [1, 2, 3, 4]
		XCTAssert(dict["a"] ?? [] == expected, "Incorrect result appending contents to existing container: expected \(expected) but found \(dict["a"])")
	}
	
	func testAppendContentsOfToNew() {
		dict.appendContents(of: [0, 1], to: "b")
		let expected = [0, 1]
		XCTAssert(dict["b"] ?? [] == expected, "Incorrect result appending contents to new container: expected \(expected) but found \(dict["b"])")
	}
	
	func testAppendContentsOfEmptyToNew() {
		dict.appendContents(of: [], to: "b")
		let expected: [Int] = []
		XCTAssert(dict["b"] ?? [-1] == expected, "Incorrect result appending contents to new container: expected \(expected) but found \(dict["b"])")
	}
	
	func testAppendContentsOf() {
		dict.appendContents(of: ["a": [3, 4], "b": [0]])
		let expected = ["a": [1, 2, 3, 4], "b": [0], "c": [4]]
		let aIsCorrect = dict["a"] ?? [] == expected["a"] ?? [-1]
		let bIsCorrect = dict["b"] ?? [] == expected["b"] ?? [-1]
		let cIsCorrect = dict["c"] ?? [] == expected["c"] ?? [-1]
		XCTAssert(aIsCorrect && bIsCorrect && cIsCorrect, "Incorrect result appending contents of dictionary: expected \(expected) but found \(dict)")
	}
	
	func testContents() {
		let contents = dict.contents
		let countIsCorrect = contents.count == 3
		let contentIsCorrect = contents.contains(1) && contents.contains(2) && contents.contains(4)
		XCTAssert(countIsCorrect && contentIsCorrect, "Incorrect contents: expected \([1, 2, 4]) but found \(contents)")
	}
	
	func testCountDiff() {
		let other = ["a": [1, 2], "b": [0], "c": [4, 5, 6], "d": []]
		let countDiff = dict.countDiff(with: other)
		let expected = ["a": 0, "b": -1, "c": -2, "d": 0]
		let aIsCorrect = countDiff["a"] ?? .max == expected["a"] ?? -.max
		let bIsCorrect = countDiff["b"] ?? .max == expected["b"] ?? -.max
		let cIsCorrect = countDiff["c"] ?? .max == expected["c"] ?? -.max
		let dIsCorrect = countDiff["d"] ?? .max == expected["d"] ?? -.max
		XCTAssert(aIsCorrect && bIsCorrect && cIsCorrect && dIsCorrect, "Incorrect countDiff: expected \(expected) but found \(countDiff)")
	}
	
}
