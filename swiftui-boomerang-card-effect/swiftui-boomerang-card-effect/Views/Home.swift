//
//  Home.swift
//  swiftui-boomerang-card-effect
//
//  Created by Jco Bea on 10/11/22.
//

import SwiftUI

struct Home: View {

    // MARK: - Sample Cards
    @State var cards: [Card] = []

    // MARK: - View Properties
    @State var isBlurEnabled: Bool = false
    @State var isRotationEnabled: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            Toggle("Enable Blur", isOn: $isBlurEnabled)
            Toggle("Enable Rotation", isOn: $isRotationEnabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            BoomerangCard(isBlurEnabled: isBlurEnabled,
                          isRotationEnabled: isRotationEnabled, cards: $cards)
                .frame(height: 220)
                .padding(.horizontal, 15)
        }
        .padding(15)
        .frame(width: .infinity,
               height: .infinity,
               alignment: .bottom)
        .background {
            Color("BG")
                .ignoresSafeArea()
        }
//        .preferredColorScheme(.dark)
        .onAppear {
            setupCards()
        }
    }

    // MARK: - Setting-up Cards
    func setupCards() {
        for _ in 1...5 {
            cards.append(.init())
        }

        // For infinite cards
        // logic is simple, place the first card at last
        // when last card is arrived, set index to 0
        if var first = cards.first {
            first.id = UUID().uuidString
            cards.append(first)
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// MARK: - Boomerang Card View
struct BoomerangCard: View {
    var isBlurEnabled: Bool = false
    var isRotationEnabled: Bool = true
    @Binding var cards: [Card]

    // MARK: - Gesture Properties
    @State var offset: CGFloat = 0
    @State var currentIndex: Int = 0

    var body: some View {
        GeometryReader {
            let size = $0.size

            ZStack {
                ForEach(cards.reversed()) { card in
                    // Text(card.id)
                    CardView(card: card, size: size)
                    // MARK: - Move only current active card
                        .offset(y: currentIndex == indexOf(card: card) ? offset : 0)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7), value: offset == .zero)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged(onChanged(value:))
                    .onEnded(onEnded(value:))
            )
        }
    }

    // MARK: - Gesture Calls
    func onChanged(value: DragGesture.Value) {
        offset = currentIndex == (cards.count - 1) ? 0 : value.translation.height
    }

    func onEnded(value: DragGesture.Value) {
        var translation = value.translation.height
        // Since we only need negative
        translation = (translation < 0 ? -translation : 0)
        translation = (currentIndex == (cards.count - 1) ? 0 : translation)

        // MARK: Since our card height is 220
        if translation > 110 {
            // MARK: Doing boomerang effect and updating current index
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.6)) {
                // Apply rotation and extra offset
                cards[currentIndex].isRotated = true
                // Give slightly bigger than the card height
                cards[currentIndex].extraOffset = -350
                cards[currentIndex].scale = 0.7
            }

            // After a little delay resetting gesture offset and extra offset
            // pushing card into back using zIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.6)) {
                    cards[currentIndex].zIndex = -100
                    for index in cards.indices {
                        cards[index].extraOffset = 0
                    }

                    // MARK: Updating current index
                    if currentIndex != (cards.count - 1) {
                        currentIndex += 1
                    }

                    offset = .zero
                }
            }

            // After animation completed, resetting rotation and scaling and setting proper zIndex value
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for index in cards.indices {
                    if index == currentIndex {
                        // MARK: Placing the card at the right index
                        // NOTE: Since the current index is updated +1 previously
                        // The index will become negative -1 now
                        if cards.indices.contains(currentIndex - 1) {
                            cards[currentIndex - 1].zIndex = ZIndex(card: cards[currentIndex - 1])
                        }
                    } else {
                        cards[index].isRotated = false
                        withAnimation(.linear) {
                            cards[index].scale = 1
                        }
                    }
                }

                if currentIndex == (cards.count - 1) {
                    // Resetting the index to 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        for index in cards.indices {
                            // Resetting zIndex to 0
                            cards[index].zIndex = 0
                        }
                        currentIndex = 0
                    }
                }

            }
        } else {
            offset = .zero
        }

    }

    func ZIndex(card: Card) -> Double {
        let index = indexOf(card: card)
        let totalCount = cards.count

        return currentIndex > index ? Double(index - totalCount) : cards[index].zIndex
    }

    @ViewBuilder
    func CardView(card: Card, size: CGSize) -> some View {
        let index = indexOf(card: card)
        // MARK: - Custom View
        Image(systemName: "creditcard")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .blur(radius: card.isRotated && isBlurEnabled ? 6.5 : 0)
            .background()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//            .foregroundColor([.cyan, .blue, .brown, .red, .yellow, .green, .pink].randomElement())
            .scaleEffect(card.scale, anchor: card.isRotated ? .center : .top)
            .rotation3DEffect(.init(degrees: isRotationEnabled && card.isRotated ? 360 : 0), axis: (x: 0, y: 0, z: 1))
            .offset(y: -offsetFor(index: index))
            .offset(y: card.extraOffset)
            .scaleEffect(scaleFor(index: index), anchor: .top)
            .zIndex(card.zIndex)
    }


    // MARK: - Scale and offset values for each card
    // Addressing negative Indeces
    func scaleFor(index value: Int) -> Double {
        let index = Double(value - currentIndex)

        if  index >= 0 {
            // Showing 3 cards
            if index > 3 {
                return 0.8
            }

            return 1 - (index / 15)
        } else {
            // Showing 3 cards
            if -index > 3 {
                return 0.8
            }

            return 1 + (index / 15)
        }

    }

    func offsetFor(index value: Int) -> Double {
        let index = Double(value - currentIndex)

        if index >= 0 {
            // Showing 3 cards
            if index > 3 {
                return 30
            }

            return (index * 15)
        } else {
            // Showing 3 cards
            if -index > 3 {
                return 30
            }

            return (-index * 15)
        }
    }

    func indexOf(card: Card) -> Int {
        if let index = cards.firstIndex(where: { c in
            c.id == card.id
        }) {
            return index
        }
        return 0
    }
}
