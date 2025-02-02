//
//  Intro.swift
//  WSR
//
//  Created by 吴泓霖 on 2024/11/28.
//

import SwiftUI

struct IntroView: View {
    @State private var index=0
    @AppStorage("isIntroFinished")  private var isIntroFinished=false
    
    let gradientStart = Color(red: 255.0 / 255, green: 120.0 / 255, blue: 221.0 / 255)
    let gradientEnd = Color.purple//Color(red: 239.0 / 255, green: 172.0 / 255, blue: 120.0 / 255)
    
    var body: some View {
        VStack{
           
            Text("MetalVision\n利用原生硬件超分的本地画面增强软件")
                .font(.system(size: 34, weight: .bold, design: .default))
                .padding(.top,70)
                .multilineTextAlignment(.center)
                .frame(width: 300)
            
                TabView(selection: $index) {
                    ForEach(0..<3){i in
                        
                        Image(IntroPages[i].imageName)
                            .resizable()
                            .scaleEffect(0.7)
                            //.aspectRatio(1,contentMode: .fit)
                            .frame(width: 300,height: 300)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .onAppear {
                    UIPageControl.appearance().isHidden = true // 隐藏分页指示器
                }
               
                
            
            
            HStack(spacing:4){
                ForEach(0..<3){i in
                    Color(Color.accentColor)
                        .opacity(i == index ? 1 : 0.5)
                        .frame(width: i==index ? 16 : 8,height:8)
                        .animation(.easeInOut(duration: 0.4),value: i==index)
                }
            }
            
            ZStack{
                ForEach(0..<3){i in
                    VStack{
                        Text(IntroPages[i].title)
                            .font(.largeTitle)
                        Text(IntroPages[i].description)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                        //.padding(.top)
                            .padding(.horizontal,40)
                    }
                    .opacity(i==index ? 1 : 0)
                    .offset(CGSize(width: 0, height: i==index ? 0 : 100))
                    .animation(.easeInOut, value: i==index)
                }
               
            }
            if !isIntroFinished{
                Button {
                    if(index>1){
                        isIntroFinished=true
                    }else{
                        index+=1
                    }
                } label: {
                    ZStack{
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [gradientStart, gradientEnd]), // 渐变的颜色数组
                                    startPoint: .topLeading, // 渐变的起始点
                                    endPoint: .bottomTrailing // 渐变的结束点
                                )
                            )
                            .frame(maxWidth: 230,maxHeight: 55)
                            .cornerRadius(12) // 可选：添加圆角
                            .shadow(radius: 5) // 可选：添加阴影
                        Text(index>1 ? "开始体验" : "下一步")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                    }
                }
                .padding(.bottom,120)
            }else{
                Spacer()
                Spacer()
            }
            

        }
        .padding()
    }
}

#Preview {
    IntroView()
        
}
