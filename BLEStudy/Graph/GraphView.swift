//
//  GraphView.swift
//  GraphViewStudy
//
//  Created by mio kato on 2022/03/15.
//

import UIKit
import SpriteKit

class GraphView: SKView {
    
    var graphScene: GraphScene?
    
    var yHeight: Float?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func setup() {
        let scene = GraphScene(size: bounds.size)
        scene.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        scene.scaleMode = .aspectFill
        presentScene(scene)
        self.graphScene = scene
        
        showsFPS = false
        ignoresSiblingOrder = false
        showsNodeCount = false
    }
    
    func update(values: [Float]) {
       
        graphScene?.setValues(values: values)
    }
    
    func updateScale(scale: Float) {
        graphScene?.scale = scale
        yHeight = graphScene?.yCurrentHeight
    }
}
