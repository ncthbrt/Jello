//
//  SwiftCompilerBlackboard.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2023/12/27.
//

import Foundation


public class JelloCompilerBlackboard {
    public static var fragOutputColorId : UInt32 = 0
    
    
    public static func clear(){
        fragOutputColorId = 0
    }
}
