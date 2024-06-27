//
//  GamePrepareView.swift
//  arproject
//
//  Created by lhy on 2023/5/31.
//

import SwiftUI

struct GameEndView: View {
    
    @Binding var gameEnded: Bool
    @Binding var win: Bool
    @Binding var timer: Int
    
    var body: some View {
        ZStack {
            Color.white // 白色背景
                .ignoresSafeArea(.all)
            VStack {
                if win == true { // 赢了
                    Text("😄")
                        .font(.system(size: 35))
                        .padding(20)
                    Text("Win")
                        .foregroundColor(.black)
                        .font(.system(size: 40))
                        .bold()
                } else { // 输了
                    Text("😭")
                        .font(.system(size: 35))
                        .padding(20)
                    Text("Lose")
                        .foregroundColor(.black)
                        .font(.system(size: 40))
                        .bold()
                }
                Button(action: { // 重新开始的按钮
                    gameEnded = false
                    win = false
                    timer = 60
                }, label: {
                    Text("Restart")
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

struct GameEndView_Previews: PreviewProvider {
    static var previews: some View {
        GameEndView(gameEnded: .constant(true), win: .constant(false), timer: .constant(60))
    }
}
