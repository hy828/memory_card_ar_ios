//
//  GamePrepareView.swift
//  arproject
//
//  Created by lhy on 2023/5/31.
//

import SwiftUI

struct GamePrepareView: View {
    
    @Binding var gameStarted: Bool
    
    var body: some View {
        ZStack {
            Color.white // 白色背景
                .ignoresSafeArea(.all)
            VStack {
                Image(systemName: "flag.checkered.2.crossed") // Logo
                    .foregroundColor(.black)
                    .font(.system(size: 50))
                    .bold()
                    .padding(20)
                Text("Memory Card Game") // 游戏名称
                    .font(.system(size: 50))
                    .fontDesign(.rounded)
                    .foregroundColor(.orange)
                    .bold()
                    .multilineTextAlignment(.center)
                Button(action: { //游戏开始的按钮
                    gameStarted = true
                }, label: {
                    Text("Play")
                        .bold()
                        .font(.title)
                        .padding(5)
                })
                .buttonStyle(.bordered)
                .padding(20)
            }
        }
    }
}

struct GamePrepareView_Previews: PreviewProvider {
    static var previews: some View {
        GamePrepareView(gameStarted: .constant(false))
    }
}
