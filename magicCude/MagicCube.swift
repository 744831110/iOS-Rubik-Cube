//
//  MagicCube.swift
//  SwiftProject
//
//  Created by 陈谦 on 2019/6/28.
//  Copyright © 2019 陈谦. All rights reserved.
//

import Foundation
import UIKit

enum MagicCubeDirection: Int {
    case up = 0
    case down
    case left
    case right
    case front
    case back
    
    func toString() -> String {
        switch self {
        case .up:
            return "U"
        case .down:
            return "D"
        case .left:
            return "L"
        case .right:
            return "R"
        case .front:
            return "F"
        case .back:
            return "B"
        }
    }
}

class MagicCube {
    var up: [[MagicCubeDirection]] = [[.up, .up, .up], [.up, .up, .up], [.up, .up, .up]]
    var down: [[MagicCubeDirection]] = [[.down, .down, .down], [.down, .down, .down], [.down, .down, .down]]
    var left: [[MagicCubeDirection]] = [[.left, .left, .left], [.left, .left, .left], [.left, .left, .left]]
    var right: [[MagicCubeDirection]] = [[.right, .right, .right], [.right, .right, .right], [.right, .right, .right]]
    var front: [[MagicCubeDirection]] = [[.front, .front, .front], [.front, .front, .front], [.front, .front, .front]]
    var back: [[MagicCubeDirection]] = [[.back, .back, .back], [.back, .back, .back], [.back, .back, .back]]
    
    func rotationMagicCube(rotationType: RotationType, index: Int, direction: RotationDirectionType) {
        guard  rotationType != .error else {
            return
        }
        var rotationIndex = index
        if rotationType == .y {
            rotationIndex = 2 - index
        }
        sideRotation(rotationType: rotationType, index: rotationIndex, direction: direction)
        edgeRotation(rotationType: rotationType, index: rotationIndex, direction: direction)
    }
    
    func edgeRotation(rotationType: RotationType, index: Int, direction: RotationDirectionType){
        switch rotationType {
        case .x:
            let array = [front[0][index], front[1][index], front[2][index]]
            if direction == .negative {
                for i in 0...2 {
                    front[i][index] = down[i][index]
                }
                for i in 0...2 {
                    down[i][index] = back[2-i][2-index]
                }
                for i in 0...2 {
                    back[2-i][2-index] = up[i][index]
                }
                for i in 0...2 {
                    up[i][index] = array[i]
                }
            } else {
                for i in 0...2 {
                    front[i][index] = up[i][index]
                }
                for i in 0...2 {
                    up[i][index] = back[2-i][2-index]
                }
                for i in 0...2 {
                    back[2-i][2-index] = down[i][index]
                }
                for i in 0...2 {
                    down[i][index] = array[i]
                }
            }
        case .y:
            let array = front[index]
            if direction == .negative {
                for i in 0...2 {
                    front[index][i] = right[index][i]
                }
                for i in 0...2 {
                    right[index][i] = back[index][i]
                }
                for i in 0...2 {
                    back[index][i] = left[index][i]
                }
                for i in 0...2 {
                    left[index][i] = array[i]
                }
            } else {
                for i in 0...2 {
                    front[index][i] = left[index][i]
                }
                for i in 0...2 {
                    left [index][i] = back[index][i]
                }
                for i in 0...2 {
                    back[index][i] = right[index][i]
                }
                for i in 0...2 {
                    right[index][i] = array[i]
                }
            }
        case .z:
            let array = down[2-index]
            if direction == .negative {
                for i in 0...2 {
                    down[2-index][i] = right[2-i][2-index]
                }
                for i in 0...2 {
                    right[i][2-index] = up[index][i]
                }
                for i in 0...2 {
                    up[index][i] = left[2-i][index]
                }
                for i in 0...2 {
                    left[i][index] = array[i]
                }
            } else {
                for i in 0...2 {
                    // change down error
                    down[2-index][i] = left[i][index]
                }
                for i in 0...2 {
                    left[i][index] = up[index][2-i]
                }
                for i in 0...2 {
                    up[index][i] = right[i][2-index]
                }
                for i in 0...2 {
                    right[i][2-index] = array[2-i]
                }
            }
        case .error:
            return
        }
    }
    
    func sideRotation(rotationType: RotationType, index: Int, direction: RotationDirectionType) {
        switch rotationType {
        case .x:
            if direction == .negative {
                if index == 2 {
                    sideRotation(side: &right, direction: .negative)
                } else if index == 0 {
                    sideRotation(side: &left, direction: .positive)
                }
                
            } else {
                if index == 2 {
                    sideRotation(side: &right, direction: .positive)
                } else if index == 0 {
                    sideRotation(side: &left, direction: .negative)
                }
            }
        case .y:
            if direction == .negative {
                if index == 2 {
                    sideRotation(side: &down, direction: .positive)
                } else if index == 0 {
                    sideRotation(side: &up, direction: .negative)
                }
            } else {
                if index == 2 {
                    sideRotation(side: &down, direction: .negative)
                } else if index == 0 {
                    sideRotation(side: &up, direction: .positive)
                }
            }
        case .z:
            if direction == .negative {
                if index == 2 {
                    sideRotation(side: &front, direction: .negative)
                } else if index == 0 {
                    sideRotation(side: &back, direction: .positive)
                }
            } else {
                if index == 2 {
                    sideRotation(side: &front, direction: .positive)
                } else if index == 0 {
                    sideRotation(side: &back, direction: .negative)
                }
            }
        case .error:
            return
        }
    }
    
    func sideRotation(side: inout [[MagicCubeDirection]], direction: RotationDirectionType){
        var edgeArray: Array<MagicCubeDirection>?
        switch direction {
        case .negative:
            edgeArray = side[0]
            for i in 0...2 {
                side[0][i] = side[2-i][0]
            }
            for i in 0...2 {
                side[i][0] = side[2][i]
            }
            for i in 0...2 {
                side[2][i] = side[2-i][2]
            }
            for i in 0...2 {
                side[i][2] = edgeArray![i]
            }
        case .positive:
            edgeArray = side[0]
            for i in 0...2 {
                side[0][i] = side[i][2]
            }
            for i in 0...2 {
                side[i][2] = side[2][2-i]
            }
            for i in 0...2 {
                side[2][2-i] = side[2-i][0]
            }
            for i in 0...2 {
                side[i][0] = edgeArray![2-i]
            }
        }
    }
    
    func magicCubeStateString() -> String {
        var string = ""
        let state = [up, right, front, down, left, back]
        for side in state {
            for edge in side {
                for cell in edge {
                    string = string + cell.toString()
                }
            }
        }
        return string
    }
}
