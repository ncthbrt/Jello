//
//  MathExpressionParser.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/26.
//

import Foundation
import JelloCompilerStatic
import DequeModule

public enum MathExpressionParserError : Error {
    case failure
}

func processLeftBracket(tokens: inout Deque<MathExpressionToken>) throws -> MathExpression {
    let lhs = try mathExpressionParser(tokens: &tokens, minBindingPower: 0)
    if tokens.popFirst() != .rightBracket {
        throw MathExpressionParserError.failure
    }
    return lhs
}

func processBracketedUnaryOperator(op: MathExpressionPrefixUnaryOperator, tokens: inout Deque<MathExpressionToken>) throws -> MathExpression {
    let lhs = try mathExpressionParser(tokens: &tokens, minBindingPower: 0)
    if tokens.popFirst() != .rightBracket {
        throw MathExpressionParserError.failure
    }
    return MathExpression.unaryOperator(op, lhs)
}

public func mathExpressionParser(tokens: inout Deque<MathExpressionToken>, minBindingPower: UInt8) throws -> MathExpression {
    var lhs: MathExpression = switch tokens.popFirst() {
        case .literal(let f): MathExpression.literal(f)
        case .leftBracket: try processLeftBracket(tokens: &tokens)
        case .x: MathExpression.variable(.x)
        case .y: MathExpression.variable(.y)
        case .z: MathExpression.variable(.z)
        case .w: MathExpression.variable(.w)
        case .e: MathExpression.constant(.e)
        case .tau: MathExpression.constant(.tau)
        case .pi: MathExpression.constant(.pi)
        case .phi: MathExpression.constant(.phi)
        case .sqrt: try processBracketedUnaryOperator(op: .sqrt, tokens: &tokens)
        case .floor: try processBracketedUnaryOperator(op: .floor, tokens: &tokens)
        case .ceil: try processBracketedUnaryOperator(op: .ceil, tokens: &tokens)
        case .round: try processBracketedUnaryOperator(op: .round, tokens: &tokens)
        case .cos: try processBracketedUnaryOperator(op: .cos, tokens: &tokens)
        case .acos: try processBracketedUnaryOperator(op: .acos, tokens: &tokens)
        case .sin: try processBracketedUnaryOperator(op: .sin, tokens: &tokens)
        case .asin: try processBracketedUnaryOperator(op: .asin, tokens: &tokens)
        case .tan: try processBracketedUnaryOperator(op: .tan, tokens: &tokens)
        case .atan: try processBracketedUnaryOperator(op: .atan, tokens: &tokens)
        case .abs: try processBracketedUnaryOperator(op: .abs, tokens: &tokens)
        case .log: try processBracketedUnaryOperator(op: .log, tokens: &tokens)
        case .minus: MathExpression.unaryOperator(.negate, try mathExpressionParser(tokens: &tokens, minBindingPower: prefixBindingPower(op: .negate).rhs))
        case .plus: MathExpression.unaryOperator(.unaryPlus, try mathExpressionParser(tokens: &tokens, minBindingPower: prefixBindingPower(op: .unaryPlus).rhs))
        case .multiply, .divide, .pow, .none, .rightBracket:
            throw MathExpressionParserError.failure
    };
    
    while true {
        if tokens.isEmpty {
            return lhs
        }
        
        if let op = tokenToInfixOperator(token: tokens.first!) {
            let (leftBindingPower, rightBindingPower) = infixBindingPower(op: op)
            if leftBindingPower < minBindingPower {
                break
            }
            tokens.removeFirst()
            let rhs = try mathExpressionParser(tokens: &tokens, minBindingPower: rightBindingPower)
            lhs = MathExpression.binaryOperator(op, lhs, rhs)
        } else {
            break
        }
    }
    return lhs
}




func tokenToInfixOperator(token: MathExpressionToken) -> MathExpressionInfixBinaryOperator? {
    switch token {
    case .minus:
        return .subtract
    case .plus:
        return .add
    case .multiply:
        return .multiply
    case .divide:
        return .divide
    case .pow:
        return .pow
    default:
        return nil
    }
}


func infixBindingPower(op: MathExpressionInfixBinaryOperator) -> (lhs: UInt8, rhs: UInt8) {
    switch op {
    case .add, .subtract:
        (lhs: 1, rhs: 2)
    case .multiply, .divide:
        (lhs: 3, rhs: 4)
    case .pow:
        (lhs: 5, rhs: 6)
    }
}

func prefixBindingPower(op: MathExpressionPrefixUnaryOperator) -> (lhs:(), rhs: UInt8) {
    switch op {
    case .negate: (lhs: (), rhs: 7)
    case .unaryPlus: (lhs: (), rhs: 7)
    default: (lhs: (), rhs: 0)
    }
}


public func parseMathExpression(_ input: String) throws -> MathExpression {
    let tokens = try mathExpressionLexer(input: input)
    var tokenQueue = Deque(tokens)
    return try mathExpressionParser(tokens: &tokenQueue, minBindingPower: 0)
}
