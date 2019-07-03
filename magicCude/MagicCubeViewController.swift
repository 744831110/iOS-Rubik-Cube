//
//  MagicCubeViewController.swift
//  SwiftProject
//
//  Created by 陈谦 on 2019/6/20.
//  Copyright © 2019 陈谦. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

enum RotationType: Int {
    case x = 0
    case y
    case z
    case error
}

enum RotationDirectionType: Int {
    case positive = 1
    case negative = -1
    mutating func changeContrary() {
        if self == .positive {
            self = .negative
        } else {
            self = .positive
        }
    }
}

enum CudeCover: Int {
    case green = 0
    case blue
    case yellow
    case white
    case red
    case orange
}

class MagicCubeViewController: UIViewController {
    
    private var scnView: SCNView?
    /// 旋转时的每一个面，其中每个array中包含该面中的9个方块
    var rotaionNodes: [[[SCNNode]]] = [[[],[],[]], [[],[],[]], [[],[],[]]]
    /// 所有的node
    var nodes: [SCNNode] = []
    let sideLength: CGFloat = 2
    /// 手势开始时点击的点（世界坐标系）
    var beganWorldCoordinates = SCNVector3Zero
    /// 手势开始时点击的node
    var beganNode: SCNNode?
    /// 魔方正中间的node
    var centerNode: SCNNode?
    /// 旋转action(动画)是否完成
    var didActionComplete: Bool = true {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                guard self.solveArray.count != 0 else {
                    return
                }
                let temp = self.solveArray.removeFirst()
                guard let rotation = temp.0, let index = temp.1, let rotationDirection = temp.2 else {
                    return
                }
                self.rotationSide(rotation: rotation, index: index, direction: rotationDirection)
            }
        }
    }
    /// 魔方状态
    let magicCube = MagicCube()
    /// 滑动记录
    var slideRecordArray: [(RotationType,Int , RotationDirectionType)] = []
    /// 解决魔方button
    var solveButton: UIButton = {
        let button = UIButton()
        button.setTitle("解决魔方", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(solveCube), for: .touchUpInside)
        button.backgroundColor = .white
        button.frame = CGRect(x: 50, y: 30, width: 100, height: 50)
        return button
    }()
    /// 解决魔方队列
    let queue = DispatchQueue(label: "com.swiftProject.magicCube", attributes: .concurrent)
    /// 解决魔方步骤
    var solveArray: [(RotationType?, Int?, RotationDirectionType?)] = []
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        makeScene()
        makeNode()
        view.addSubview(solveButton)
    }
    
    private func makeScene() {
        scnView = SCNView(frame: UIScreen.main.bounds)
        self.view .addSubview(scnView!)
        scnView?.center = view.center
        scnView?.backgroundColor = UIColor.lightGray
        scnView?.antialiasingMode = .multisampling2X
        let scene = SCNScene()
        scnView?.scene = scene
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panHandle(_:)))
        scnView?.addGestureRecognizer(panGesture)
        panGesture.delegate = self
    }

    private func makeNode() {
        makeCude()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scnView?.scene?.rootNode.addChildNode(cameraNode)
        scnView?.allowsCameraControl = true
        cameraNode.position = SCNVector3(0, 0, 20)
    }

    private func makeCude() {
        let colors = [UIColor.red, // front
                UIColor.white, // right
                UIColor.orange, // back
                UIColor.yellow, // left
                UIColor.green, // top
                UIColor.blue] // bottom
        for z in -1...1 {
            for y in -1...1 {
                for x in -1...1 {
                    let node = makeCudeNode(colors: colors, temp: (x, y, z))
                    if x == 0 && y == 0 && z == 0 {
                        centerNode = node
                    }
                }
            }
        }
    }

    private func makeCudeNode(colors: [UIColor], temp: (x: Int, y: Int, z: Int)) -> SCNNode? {
        let box = SCNBox(width: sideLength, height: sideLength, length: sideLength, chamferRadius: 0.1)
        let sideMaterials = colors.map { color -> SCNMaterial in
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.locksAmbientWithDiffuse = true
            return material
        }
        box.materials = sideMaterials

        let node = SCNNode()
        node.geometry = box
        let xPoint = CGFloat(temp.x) * sideLength
        let yPoint = CGFloat(temp.y) * sideLength
        let zPoint = CGFloat(temp.z) * sideLength
        node.position = SCNVector3(xPoint, yPoint, zPoint)
        rotaionNodes[0][temp.x+1].append(node)
        rotaionNodes[1][temp.y+1].append(node)
        rotaionNodes[2][temp.z+1].append(node)
        nodes.append(node)
        scnView?.scene?.rootNode.addChildNode(node)
        return node
    }
    
    @objc private func panHandle(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            let results = scnView?.hitTest(panGesture.location(ofTouch: 0, in: scnView), options: nil)
            beganWorldCoordinates = results?.first?.worldCoordinates ?? SCNVector3Zero
            beganNode = results?.first?.node
        } else if panGesture.state == .changed {
            guard didActionComplete else {
                panGesture.state = .ended
                return
            }
            let results = scnView?.hitTest(panGesture.location(ofTouch: 0, in: scnView), options: nil)
            let worldCoordinates = results?.first?.worldCoordinates
            guard worldCoordinates != nil else {
                return
            }
            let translationx = worldCoordinates!.x - beganWorldCoordinates.x
            let translationy = worldCoordinates!.y - beganWorldCoordinates.y
            let translationz = worldCoordinates!.z - beganWorldCoordinates.z
            
            /// 根据滑动路径中的两个点来判断手指滑动方向和滑动正反方向
            func max(x: Float, y: Float, z: Float) -> (RotationType, RotationDirectionType){
                let fabsx = fabsf(x)
                let fabsy = fabsf(y)
                let fabsz = fabsf(z)
                var maxNum = fabsx
                var rotationType: RotationType = .x
                var diraction: RotationDirectionType = (x>0) ? .positive : .negative
                if maxNum<fabsy {
                    maxNum = fabsy
                    rotationType = .y
                    diraction = (y>0) ? .negative : .positive
                }
                if maxNum<fabsz {
                    maxNum = fabsz
                    rotationType = .z
                    diraction = (z>0) ? .positive : .negative
                }
                /// 如果两个点的最大方向距离小于2，则忽略
                guard maxNum>=2 else {
                    return (.error ,.positive)
                }
                /// 纠正滑动正反方向
                switch rotationType {
                case .x:
                    if -3.1<beganWorldCoordinates.z && -2.9>beganWorldCoordinates.z {
                        diraction.changeContrary()
                    }
                    if 3.1>beganWorldCoordinates.y && 2.9<beganWorldCoordinates.y {
                        diraction.changeContrary()
                    }
                case .y:
                    if 2.9<beganWorldCoordinates.x && 3.1>beganWorldCoordinates.x {
                        diraction.changeContrary()
                    }
                    if -3.1<beganWorldCoordinates.z && -2.9>beganWorldCoordinates.z {
                        diraction.changeContrary()
                    }
                case .z:
                    if 2.9<beganWorldCoordinates.x && 3.1>beganWorldCoordinates.x {
                        diraction.changeContrary()
                    }
                    if -3.1<beganWorldCoordinates.y && -2.9>beganWorldCoordinates.y {
                        diraction.changeContrary()
                    }
                case .error:
                    break;
                }
                
                /// 将手指滑动方向转换成该面绕着某个轴(x,y,z)转
                let rotation = fingleRotationToCudeRotation(rotationType: rotationType, beganWorldCoordinates: beganWorldCoordinates)
                
                return (rotation, diraction)
            }
            let temp = max(x: translationx, y: translationy, z: translationz)
            guard beganNode != nil else {
                return
            }
            var rotationIndex = -1
            guard temp.0 != .error else {
                return
            }
            /// 找出绕着某个轴转的三个面中有哪个面包含了beganNode
            for index in 0..<rotaionNodes[temp.0.rawValue].count {
                guard isContainNodeForPosition(rotaionNodes[temp.0.rawValue][index], beganNode!) != -1 else {
                    continue
                }
                rotationIndex = index
            }
            didActionComplete = false
            /// 开始旋转
            rotationSide(rotation: temp.0, index: rotationIndex, direction: temp.1)
            printCubeForColor(side: magicCube.up)
            printCubeForColor(side: magicCube.left)
            printCubeForColor(side: magicCube.front)
            printCubeForColor(side: magicCube.right)
            printCubeForColor(side: magicCube.back)
            printCubeForColor(side: magicCube.down)
            panGesture.state = .ended
        }
    }
    
    private func rotationSide(rotation: RotationType, index: Int, direction: RotationDirectionType) {
        print(rotation)
        print(index)
        print(direction)
        guard index != -1 else {
            return
        }
        var axis = SCNVector3Zero
        switch rotation {
        case .x:
            axis.x = Float(direction.rawValue)
        case .y:
            axis.y = Float(direction.rawValue)
        case .z:
            axis.z = Float(direction.rawValue)
        case .error:
            break
        }
        guard centerNode != nil else {
            return
        }
        /// centerNode添加某一个面的所有node除了它自己
        /// 需要进行坐标系的转换，从scnView.scene.rootNode到centerNode
        for node in rotaionNodes[rotation.rawValue][index] {
            guard !SCNVector3EqualToVector3(centerNode!.position, node.position) else {
                continue
            }
            let transform = centerNode?.convertTransform(node.transform, from: scnView?.scene?.rootNode)
            if transform != nil {
                node.transform = transform!
            }
            node.removeFromParentNode()
            centerNode?.addChildNode(node)
        }
        
        let customAction = SCNAction.rotate(by: CGFloat(Double.pi / 2), around: axis, duration: 0.4)
        centerNode?.runAction(customAction, completionHandler: { [weak self] in
            /// 动画完毕后将该面的点添加回scnView.scene.rootNode
            /// 需要进行坐标系的转换，从centerNode到scnView.scene.rootNode
            /// 要对rotationNodes进行更新
            for node in (self?.centerNode)!.childNodes {
                node.transform = node.presentation.worldTransform
                node.removeFromParentNode()
                self?.scnView?.scene?.rootNode.addChildNode(node)
            }
            self?.rotaionNodes = [[[],[],[]], [[],[],[]], [[],[],[]]]
            for node in (self?.nodes)! {
                self?.rotaionNodes[0][lroundf(node.position.x)/2+1].append(node)
                self?.rotaionNodes[1][lroundf(node.position.y)/2+1].append(node)
                self?.rotaionNodes[2][lroundf(node.position.z)/2+1].append(node)
            }
            self?.didActionComplete = true
            /// 更改魔方状态
            self?.magicCube.rotationMagicCube(rotationType: rotation, index: index, direction: direction)
            self?.slideRecordArray.append((rotation, index, direction))
        })
    }
    
    /// array中是否包括a node
    private func isContainNodeForPosition(_ array: [SCNNode], _ a: SCNNode) -> Int {
        for index in 0..<array.count {
            if SCNVector3EqualToVector3(a.position, array[index].position) {
                return index
            }
        }
        return -1
    }
    
    /// 手指滑动方向转换成绕某个轴旋转
    private func fingleRotationToCudeRotation(rotationType: RotationType, beganWorldCoordinates: SCNVector3) -> RotationType {
        /// 通过手指开始落在某个面上以及手指滑动的方向可以判断魔方需要绕着某条轴转
        switch cudeCoverInclueVector3(pointe: beganWorldCoordinates) {
        case .x:
            if rotationType == .y {
                return .z
            } else if rotationType == .z {
                return .y
            } else {
                return .error
            }
        case .y:
            if rotationType == .x {
                return .z
            } else if rotationType == .z {
                return .x
            } else {
                return .error
            }
        case .z:
            if rotationType == .y {
                return .x
            } else if rotationType == .x {
                return .y
            } else {
                return .error
            }
        case .error:
            return .error
        }
    }
    
    /// 判断pointe在哪个轴的面上
    private func cudeCoverInclueVector3(pointe: SCNVector3) -> RotationType {
        var result = 0
        var rotationType: RotationType = .error
        if (pointe.x < 3.1 && pointe.x > 2.9) || (pointe.x < -2.9 && pointe.x > -3.1) {
            result += 1
            rotationType = .x
        }
        if (pointe.y < 3.1 && pointe.y > 2.9) || (pointe.y < -2.9 && pointe.y > -3.1) {
            result += 2
            rotationType = .y
        }
        if (pointe.z < 3.1 && pointe.z > 2.9) || (pointe.z < -2.9 && pointe.z > -3.1) {
            result += 4
            rotationType = .z
        }
        
        return rotationType
    }
    
    @objc func solveCube() {
        let queue = DispatchQueue(label: "com.swiftProject.magicCube", attributes: .concurrent)
        queue.async {
            let argv = self.magicCube.magicCubeStateString()
            let contentPointer = strdup(argv)
            let result = solve(2, contentPointer)
            let resultString = String(cString: result!)
            print("magic cube result string is \(resultString)")
            free(contentPointer)
            let array = resultString.split(separator: " ")
            for subString in array {
                var rotation: RotationType?
                var rotationDirection: RotationDirectionType?
                var index: Int?
                var isAnticlockwise = false
                if subString.contains("'") {
                    isAnticlockwise = true
                }
                if subString.contains("U") {
                    rotation = .y
                    index = 2
                    rotationDirection = isAnticlockwise ? .positive : .negative
                } else if subString.contains("D") {
                    rotation = .y
                    index = 0
                    rotationDirection = isAnticlockwise ? .negative : .positive
                } else if subString.contains("L") {
                    rotation = .x
                    index = 0
                    rotationDirection = isAnticlockwise ? .negative : .positive
                } else if subString.contains("R") {
                    rotation = .x
                    index = 2
                    rotationDirection = isAnticlockwise ? .positive : .negative
                } else if subString.contains("F") {
                    rotation = .z
                    index = 2
                    rotationDirection = isAnticlockwise ? .positive : .negative
                } else if subString.contains("B") {
                    rotation = .z
                    index = 0
                    rotationDirection = isAnticlockwise ? .negative : .positive
                }
                let temp = (rotation, index, rotationDirection)
                self.solveArray.append(temp)
                if subString.contains("2") {
                    self.solveArray.append(temp)
                }
            }
            DispatchQueue.main.async {
                /// 按照解决方法转动魔方
                guard self.solveArray.count != 0 else {
                    return
                }
                let temp = self.solveArray.removeFirst()
                guard let rotation = temp.0, let index = temp.1, let rotationDirection = temp.2 else {
                    return
                }
                self.rotationSide(rotation: rotation, index: index, direction: rotationDirection)
            }
        }
    }
    
    private func printCubeForColor(side: [[MagicCubeDirection]]) {
        for edge in side {
            var array: [CudeCover] = []
            for cell in edge {
                guard let color = CudeCover(rawValue: cell.rawValue) else {
                    print("print cube for color is error")
                    return
                }
                array.append(color)
            }
            print(array)
        }
        print("                               ")
    }
}
/// 手势冲突解决
extension MagicCubeViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let results = scnView?.hitTest(gestureRecognizer.location(in: scnView), options: nil)
        let firstNode = results?.first?.node
        return firstNode != nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
