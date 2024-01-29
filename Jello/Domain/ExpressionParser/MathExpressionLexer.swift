//
//  MathExpressionLexer.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/26.
//

import Foundation


public enum MathExpressionToken: Equatable {
    case literal(Float)
    case leftBracket
    case rightBracket
   
    case plus
    case minus
    case divide
    case multiply
    case pow
    
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
  
    case pi
    case phi
    case tau
    
    case x
    case y
    case z
    case w
    case e
}

public enum MathExpressionLexerError : Error {
    case failure
}

fileprivate let literalRegex: Regex = /([0-9]*[.])?[0-9]+/
fileprivate let leftBracketRegex: Regex = /\(/
fileprivate let rightBracketRegex: Regex = /\)/

fileprivate let plusRegex: Regex = /\+/
fileprivate let minusRegex: Regex = /\-/
fileprivate let multiplyRegex: Regex = /\*/
fileprivate let divideRegex: Regex = /\//
fileprivate let powRegex: Regex = /\^/

fileprivate let sqrtRegex: Regex = /sqrt\(/
fileprivate let floorRegex: Regex = /floor\(/
fileprivate let ceilRegex: Regex = /ceil\(/
fileprivate let roundRegex: Regex = /round\(/
fileprivate let cosRegex: Regex = /cos\(/
fileprivate let acosRegex: Regex = /acos\(/
fileprivate let sinRegex: Regex = /sin\(/
fileprivate let asinRegex: Regex = /asin\(/
fileprivate let tanRegex: Regex = /tan\(/
fileprivate let atanRegex: Regex = /atan\(/
fileprivate let absRegex: Regex = /abs\(/
fileprivate let logRegex: Regex = /log\(/

fileprivate let eRegex: Regex = /e/
fileprivate let piRegex: Regex = /pi/
fileprivate let phiRegex: Regex = /phi/
fileprivate let tauRegex: Regex = /tau/

fileprivate let xRegex: Regex = /x/
fileprivate let yRegex: Regex = /y/
fileprivate let zRegex: Regex = /z/
fileprivate let wRegex: Regex = /w/

fileprivate typealias TokenGenerator = (String) -> MathExpressionToken?

fileprivate let tokenList: [(Regex, MathExpressionToken)] = [
    (leftBracketRegex, .leftBracket),
    (rightBracketRegex, .rightBracket),
    (plusRegex, .plus),
    (minusRegex, .minus),
    (multiplyRegex, .multiply),
    (divideRegex, .divide),
    (powRegex, .pow),
    (sqrtRegex, .sqrt),
    (floorRegex, .floor),
    (ceilRegex, .ceil),
    (roundRegex, .round),
    (cosRegex, .cos),
    (acosRegex, .acos),
    (sinRegex, .sin),
    (asinRegex, .asin),
    (tanRegex, .tan),
    (atanRegex, .atan),
    (absRegex, .abs),
    (logRegex, .log),
    (eRegex, .e),
    (piRegex, .pi),
    (phiRegex, .phi),
    (tauRegex, .tau),
    (xRegex, .x),
    (yRegex, .y),
    (zRegex, .z),
    (wRegex, .w)
]


public func mathExpressionLexer(input: String) throws -> [MathExpressionToken] {
    var tokens = [MathExpressionToken]()
    var content = input[...]

     while (content.count > 0) {
         var matched = false
         if let match = try literalRegex.prefixMatch(in: content) {
             if let f = Float(match.output.0) {
                 tokens.append(MathExpressionToken.literal(f))
                 matched = true
                 content = content[match.range.upperBound...]
             }
         } else {
             for (pattern, token) in tokenList {
                 if let match = try pattern.prefixMatch(in: content) {
                     tokens.append(token)
                     content = content[match.endIndex...]
                     matched = true
                     break
                 }
             }
         }

         if !matched {
             throw MathExpressionLexerError.failure
         }
     }
     return tokens

}


