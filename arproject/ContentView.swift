//
//  ContentView.swift
//  arproject
//
//  Created by lhy on 2023/5/31.
//

import SwiftUI
import RealityKit
import Combine
import Foundation

struct ContentView : View {
    
    @State var gameEnded: Bool = false // 游戏是否结束
    @State var gameStarted: Bool = false // 游戏是否开始
    @State var win: Bool = false // 游戏结果：True-赢，False-输
    @State var timer = 60 // 计时器
    
    var body: some View {
        if !gameStarted && !gameEnded { // 游戏开始前
            GamePrepareView(gameStarted: $gameStarted)
        } else if gameStarted && gameEnded { // 游戏结束后
            GameEndView(gameEnded: $gameEnded, win: $win, timer: $timer)
        } else { // 游戏进行中
            ZStack {
                ARViewContainer(gameEnded: $gameEnded, timer: $timer, win: $win).edgesIgnoringSafeArea(.all)
//                Text("\(timer)")
//                    .font(.largeTitle)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
//                    .foregroundColor(.white)
//                    .padding(40)
//                    .clipShape(Circle())
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    let arView = ARView(frame: .zero)
    let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2]) // 平行平面
    var pairedCards: Int = 0 // 配对成功的数量
    @Binding var gameEnded: Bool
    @Binding var timer: Int
    @Binding var win: Bool
    
    func makeUIView(context: Context) -> ARView {
        
        arView.scene.addAnchor(anchor)
        
        var cards: [CardEntity] = []
        
        for i in 1...16 { // 生成卡片
            let cardTemplate = try! Entity.loadModel(named: "card")
            let cardEntity = CardEntity()
            cardEntity.model = cardTemplate.model
            cardEntity.transform = cardTemplate.transform
            cardEntity.name = "card_\(i)"
            cardEntity.card.revealed = false
            cardEntity.card.name = "card_\(i)"
            cardEntity.generateCollisionShapes(recursive: true)
            cards.append(cardEntity)
        }
        
        for (index, card) in cards.enumerated() { // 卡片坐标
            let x = Float(index%4)-1.5
            let z = Float(index/4)-1.5
            
            card.position = [x*0.1, 0, z*0.1]
            
            anchor.addChild(card)
        }
        
        // 卡片下的物品屏蔽
        let boxSize: Float = 1
        let boxMesh = MeshResource.generateBox(size: boxSize)
        let material = OcclusionMaterial()
        let occlusionBox = ModelEntity(mesh: boxMesh, materials: [material])
        occlusionBox.position.y = -boxSize / 2 - 0.001
        anchor.addChild(occlusionBox)
        
        var models: [ModelEntity] = []
        
        for i in 1...8 { // 生成物品
            let model = try! Entity.loadModel(named: "memory_card_\(i)")
            model.name = "model_\(i)"
            model.setScale(SIMD3<Float>(0.2, 0.2, 0.2), relativeTo: anchor)
            model.generateCollisionShapes(recursive: true)
            for _ in 1...2 {
                models.append(model.clone(recursive: true))
            }
        }
        models.shuffle() // 打乱物品顺序
        for (index, object) in models.enumerated() { // 绑定物品和卡片
            cards[index].card.model = object.name
            cards[index].addChild(object)
        }
        
        // 物品异步加载，无法定义每个model的名字，indexing一直出现问题
//        var cancellable: AnyCancellable? = nil
//
//        cancellable = ModelEntity.loadModelAsync(named: "memory_card_1")
//            .append(ModelEntity.loadModelAsync(named: "memory_card_2"))
//            .append(ModelEntity.loadModelAsync(named: "memory_card_3"))
//            .append(ModelEntity.loadModelAsync(named: "memory_card_4"))
//            .append(ModelEntity.loadModelAsync(named: "memory_card_5"))
//            .append(ModelEntity.loadModelAsync(named: "memory_card_6"))
//            .append(ModelEntity.loadModelAsync(named: "memory_card_7"))
//            .append(ModelEntity.loadModelAsync(named: "memory_card_8"))
//            .collect()
//            .sink(receiveCompletion: { error in
//                print("Error: \(error)")
//                cancellable?.cancel()
//            }, receiveValue: { entities in
//                var objects: [ModelEntity] = []
//                var i = 1
//                for e in entities {
//                    e.name = "model_" + i
//                    i += 1
//                    print(e.name)
//                    e.setScale(SIMD3<Float>(0.2, 0.2, 0.2), relativeTo: anchor)
//                    e.generateCollisionShapes(recursive: true)
//                    for _ in 1...2 {
//                        objects.append(e.clone(recursive: true))
//                    }
//                }
//                objects.shuffle()
//                for (index, object) in objects.enumerated() {
//                    print(object.name)
//                    cards[index].card.model = object.name
//                    cards[index].addChild(object)
//                }
//                cancellable?.cancel()
//            })
        
        // 5秒后翻转物品到卡片下
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            for i in cards {
                i.hide()
            }
            startTimer() // 启动计时器
        }
        
        // 每秒更新物品状况
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            for i in cards {
                if i.card.paired == false {
                    i.hide()
                } else {
                    i.reveal()
                }
            }
        }
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    // 主要处理点击手势的监听
    class ARCoordinator: NSObject {
        
        var manager: ARViewContainer
        var openedCards: [CardEntity] = [] // 记录打开的卡片
        
        init(_ manager: ARViewContainer) {
            self.manager = manager
            super.init()
            let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
            manager.arView.addGestureRecognizer(tap) // 点击监听载入到arView
        }
        @objc func onTap(_ sender: UITapGestureRecognizer) { // 点击后的处理函数
            if let cardEntity = manager.arView.entity(at: sender.location(in: manager.arView)) as? CardEntity { // 找到点击所对应的卡片
                if cardEntity.card.paired == false { // 卡片尚未配对
                    cardEntity.reveal() // 翻开卡片
                    openedCards.append(cardEntity)
//                    print("count: \(openedCards.count)")
//                    print("card: \(cardEntity.name)")
                    if openedCards.count == 2 { // 已翻开两张卡片
                        if openedCards[0].card.model == openedCards[1].card.model { // 配对成功
                            print(openedCards[0].card.model)
                            print(openedCards[1].card.model)
                            manager.pairedCards += 1
                            print("already pair: \(manager.pairedCards)")
                            openedCards[0].card.paired = true
                            openedCards[1].card.paired = true
                            if manager.pairedCards == 8 { // 所有卡片已配对完
                                manager.gameEnded = true // 游戏结束
                                manager.win = true 
                                print("winwinwin")
                            }
                        } else {
                            // 等待一秒钟再关闭卡片，写不出TT
//                            DispatchQueue.main.asyncAfter(deadline: .now() + .second(1), execute: {
//                            })
//                            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
//                                print("111:\(self.openedCards.count)")
//                            }
//                            print("222:\(self.openedCards.count)")
                        }
                        self.openedCards.removeAll() // 清空数组
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> ARCoordinator { ARCoordinator(self) }
    
    // 计时器：每次倒计时一秒
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { i in
            self.timer -= 1
            print(timer)
            if timer <= 0 { // 时间到，游戏结束，输了
                i.invalidate()
                gameEnded = true
            }
        }
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
