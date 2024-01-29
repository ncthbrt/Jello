//
//  JelloMathExpressionTypes.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2024/01/26.
//

import Foundation

public enum MathExpressionConstant {
    case e
    case pi
    case phi
    case tau
}

public enum MathExpressionInfixBinaryOperator: String, CaseIterable {
    case add
    case subtract
    case divide
    case multiply
    case pow
}

public enum MathExpressionPrefixUnaryOperator: String, CaseIterable {
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
    case unaryPlus
}

public enum MathExpressionVariable: Int {
    case x = 0
    case y = 1
    case z = 2
    case w = 3
}

public indirect enum MathExpression: Equatable {
    case literal(Float)
    case constant(MathExpressionConstant)
    case variable(MathExpressionVariable)
    case unaryOperator(MathExpressionPrefixUnaryOperator, MathExpression)
    case binaryOperator(MathExpressionInfixBinaryOperator, MathExpression, MathExpression)
}




