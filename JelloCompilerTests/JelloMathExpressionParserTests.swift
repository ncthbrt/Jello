//
//  JelloMathExpressionParserTests.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2024/01/27.
//
import Foundation
import JelloCompilerStatic
import XCTest

final class JelloMathExpressionParserTests: XCTestCase {
    func testThatParsingComplexExpressionProducesExpectedResult() throws {
        let result = try parseMathExpression("sin(3*x^(1.0+2))")
        let expectedResult: MathExpression =  MathExpression.unaryOperator(.sin, MathExpression.binaryOperator(.multiply, .literal(3.0), MathExpression.binaryOperator(.pow, .variable(.x), MathExpression.binaryOperator(.add, .literal(1.0), .literal(2)))))
        XCTAssertEqual(result, expectedResult)
    }
    
    func testThatParsingInfixOperatorsProducesExpectedResult() throws {
        let result = try parseMathExpression("x+y+z")
        let expectedResult: MathExpression =  MathExpression.binaryOperator(.add, MathExpression.binaryOperator(.add, .variable(.x), .variable(.y)), .variable(.z))
        XCTAssertEqual(result, expectedResult)
    }
}
