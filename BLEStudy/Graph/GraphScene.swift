//
//  GraphScene.swift
//  GraphViewStudy
//
//  Created by mio kato on 2022/03/15.
//

import SpriteKit

class GraphScene: SKScene {
    // 受け取る値の配列
    private var values = [Float]()
    // 保持する値の最大値
    private let maxValues = Constants.samplingRate * Constants.waveDuration
    // グラフを表示する時間
    var timeDuration: Float {
        return Float(maxValues)
    }
    // 画面の幅
    var viewWidth: Float!
    // 画面の高さ
    var viewHeight: Float!
    // 波形の高さを調節
    var scale: Float = 1.0
    let yMaxHeight: Float = 120000
    let yminHeight: Float = 10
    let yDefaultHeight: Float = 5000
    var yCurrentHeight: Float {
        let y = yDefaultHeight / scale
        if y > yMaxHeight {
            return yMaxHeight
        }
        if y < yminHeight {
            return yminHeight
        }
        return y
    }
    
    override func didMove(to view: SKView) {
        // フレームレート
        view.preferredFramesPerSecond = 60
        // 背景色
        scene?.backgroundColor = .white
        
        viewHeight = Float(view.frame.height) * 0.5
        viewWidth = Float(view.frame.width)
    }
    
    /// 波形の値を更新
    func setValues(values: [Float]) {
        self.values = values
    }
   
    /// 画面を更新
    override func update(_ currentTime: TimeInterval) {
        guard values.count == maxValues else {
            return
        }
        
        var points = [CGPoint]()
        for (i, value) in self.values.enumerated() {
            let ratio = value / yCurrentHeight
            let height = viewHeight * ratio
            let width = Float(i) / timeDuration * viewWidth
            let point = CGPoint(x: CGFloat(width), y: CGFloat(height))
            points.append(point)
        }
        draw(points: points)
    }
    
    func draw(points: [CGPoint]) {
        removeAllChildren()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        
        for point in points {
            path.addCurve(to: point, controlPoint1: point, controlPoint2: point)
        }

        let shapeNode = SKShapeNode(path: path.cgPath)
        shapeNode.strokeColor = UIColor.black
        addChild(shapeNode)
    }
}
