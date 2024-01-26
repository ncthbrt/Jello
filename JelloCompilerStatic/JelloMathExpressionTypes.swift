//
//  JelloMathExpressionTypes.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2024/01/26.
//

import Foundation


public enum MathExpressionBinaryOperator: String, CaseIterable {
    case add
    case subtract
    case divide
    case multiply
}

public enum MathExpressionUnaryOperator: String, CaseIterable {
    case sqrt
    case floor
    case ceil
    case round
    case cos
    case acos
    case sin
    case asin
    case tan
    case atan
    case abs
    case log
    case negate
}

public enum MathExpressionVariable: Int {
    case x = 0
    case y = 1
    case z = 2
    case w = 3
}

public indirect enum MathExpression {
    case literal(Float)
    case variable(MathExpressionVariable)
    case unaryOperator(MathExpressionUnaryOperator, MathExpression)
    case binaryOperator(MathExpressionBinaryOperator, MathExpression, MathExpression)
}




