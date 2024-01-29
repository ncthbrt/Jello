//
//  JelloMathExpressionLexerTests.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2024/01/26.
//

import Foundation
import XCTest

final class JelloMathExpressionLexerTests: XCTestCase {
    func testThatLexxingComplexExpressionProducesExpectedResult() throws {
        let result = try mathExpressionLexer(input: "sin(3^(1.0+2))")
        let expectedResult = [MathExpressionToken.sin, MathExpressionToken.literal(3), MathExpressionToken.pow, MathExpressionToken.leftBracket, MathExpressionToken.literal(1.0), MathExpressionToken.plus, MathExpressionToken.literal(2), MathExpressionToken.rightBracket, MathExpressionToken.rightBracket]
        XCTAssertEqual(result, expectedResult)
    }
    
    func testThatLexxingInfixOperatorsProducesExpectedResult() throws {
        let result = try mathExpressionLexer(input: "x+y+z")
        let expectedResult =  [MathExpressionToken.x, MathExpressionToken.plus, MathExpressionToken.y, MathExpressionToken.plus, MathExpressionToken.z]
        XCTAssertEqual(result, expectedResult)
    }
}
