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
    // 受け取る値で表示できる最大の値
    let yMaxHeight: Float = 120000
    // 受け取る値で表示できる最小の値
    let yminHeight: Float = 10
    // デフォルトの描画できる高さの幅
    let yDefaultHeight: Float = 5000
    // 現在の描画できる高さの幅
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
    // 描画する線
    var lineNode = SKShapeNode()
    // 一時的に保持する一つ前の線の描画位置
    var lastPoint: CGPoint = .zero
    
    override func didMove(to view: SKView) {
        // フレームレート
        view.preferredFramesPerSecond = 60
        // 背景色
        scene?.backgroundColor = .white
        // 描画する線の色
        lineNode.strokeColor = UIColor.black
        addChild(lineNode)
        
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
        
        // 画面を描画
        let path = CGMutablePath()
        path.move(to: .zero)
        for (i, value) in self.values.enumerated() {
            let ratio = value / yCurrentHeight
            let height = viewHeight * ratio
            let width = Float(i) / timeDuration * viewWidth
            let point = CGPoint(x: CGFloat(width), y: CGFloat(height))
            path.addLine(to: point)
            lastPoint = point
            path.move(to: lastPoint)
        }
        lineNode.path = path
    }
}
