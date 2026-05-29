//
//  ContentView.swift
//  Frogger Bingo Game
//
//  Created by User on 27.05.2026.
//

import AVFoundation
import AudioToolbox
import Combine
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var audio = AudioController()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var screen: AppScreen = .home
    @State private var onboardingPage = 0
    @State private var selectedCategory: AnimalCategory?
    @State private var selectedMode: GameMode = .guessName
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true

    var body: some View {
        ZStack {
            PondBackground()
                .ignoresSafeArea()

            switch screen {
            case .onboarding:
                OnboardingView(
                    page: $onboardingPage,
                    onSkip: completeOnboarding,
                    onFinish: completeOnboarding
                )
            case .home:
                HomeView(
                    onPlay: { screen = .categories },
                    onInstructions: { screen = .instructions },
                    onSettings: { screen = .settings }
                )
            case .categories:
                CategoryView(
                    onBack: { screen = .home },
                    onSelect: { category in
                        selectedCategory = category
                        screen = .modePicker
                    }
                )
            case .modePicker:
                ModePickerView(
                    category: selectedCategory ?? .amphibians,
                    selectedMode: $selectedMode,
                    onBack: { screen = .categories },
                    onStart: { screen = .game }
                )
            case .game:
                GameView(
                    category: selectedCategory ?? .amphibians,
                    mode: selectedMode,
                    soundEnabled: soundEnabled,
                    vibrationEnabled: vibrationEnabled,
                    audio: audio,
                    onBack: { screen = .modePicker },
                    onHome: { screen = .home }
                )
            case .instructions:
                InstructionsView(
                    onBack: { screen = .home },
                    onStart: { screen = .categories }
                )
            case .settings:
                SettingsView(
                    soundEnabled: $soundEnabled,
                    musicEnabled: $musicEnabled,
                    vibrationEnabled: $vibrationEnabled,
                    onBack: { screen = .home }
                )
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            if !hasCompletedOnboarding {
                screen = .onboarding
            }
            audio.setBackgroundMusicEnabled(musicEnabled)
        }
        .onChange(of: musicEnabled) { enabled in
            audio.setBackgroundMusicEnabled(enabled)
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        screen = .home
    }
}

final class AudioController: ObservableObject {
    private var backgroundPlayer: AVAudioPlayer?

    func setBackgroundMusicEnabled(_ isEnabled: Bool) {
        isEnabled ? startBackgroundMusic() : stopBackgroundMusic()
    }

    func playCorrectAnswer(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    func playWrongAnswer(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1053)
    }

    func playWin(soundEnabled: Bool, vibrationEnabled: Bool) {
        if soundEnabled {
            AudioServicesPlaySystemSound(1025)
        }

        if vibrationEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func startBackgroundMusic() {
        if backgroundPlayer?.isPlaying == true { return }

        if backgroundPlayer == nil {
            guard let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") else {
                return
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)

                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0.45
                player.prepareToPlay()
                backgroundPlayer = player
            } catch {
                backgroundPlayer = nil
                return
            }
        }

        backgroundPlayer?.play()
    }

    private func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer?.currentTime = 0
    }
}

enum AppScreen {
    case onboarding
    case home
    case categories
    case modePicker
    case game
    case instructions
    case settings
}

enum GameMode: String, CaseIterable, Identifiable {
    case guessName = "Guess the Name"
    case findPicture = "Find the Picture"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .guessName: return "photo"
        case .findPicture: return "textformat"
        }
    }

    var tint: Color {
        switch self {
        case .guessName: return .frogGreen
        case .findPicture: return .coral
        }
    }

    var caption: String {
        switch self {
        case .guessName: return "See an animal picture and tap the correct name."
        case .findPicture: return "Read the animal name and find the matching picture."
        }
    }
}

struct Animal: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let assetName: String
    let symbol: String
    let colors: [Color]

    var bingoTitle: String {
        switch name {
        case "Brachiosaurus": return "Brachio\nsaurus"
        case "Styracosaurus": return "Styraco\nsaurus"
        case "Ankylosaurus": return "Ankylo\nsaurus"
        case "Stegosaurus": return "Stego\nsaurus"
        case "Compsognathus": return "Compso\ngnathus"
        case "Pachycephalosaurus": return "Pachy\ncephalo\nsaurus"
        case "Parasaurolophus": return "Para\nsauro\nlophus"
        case "Dilophosaurus": return "Dilopho\nsaurus"
        case "Plesiosaurus": return "Plesio\nsaurus"
        case "Archaeopteryx": return "Archaeo\npteryx"
        default: return name
        }
    }
}

enum AnimalCategory: String, CaseIterable, Identifiable {
    case amphibians = "Amphibians"
    case reptiles = "Reptiles"
    case dinosaurs = "Dinosaurs"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .amphibians: return "Discover frogs, salamanders, and more!"
        case .reptiles: return "Explore lizards, snakes, and turtles!"
        case .dinosaurs: return "Travel back to prehistoric times!"
        }
    }

    var shortSubtitle: String {
        switch self {
        case .amphibians: return "Frogs and salamanders"
        case .reptiles: return "Lizards and turtles"
        case .dinosaurs: return "Bonus prehistoric world"
        }
    }

    var hero: String {
        switch self {
        case .amphibians: return "🐸"
        case .reptiles: return "🦎"
        case .dinosaurs: return "🦖"
        }
    }

    var cardAssetName: String {
        switch self {
        case .amphibians: return "category_amphibians_card"
        case .reptiles: return "category_reptiles_card"
        case .dinosaurs: return "category_dinosaurs_card"
        }
    }

    var assetPrefix: String {
        switch self {
        case .amphibians: return "amphibians"
        case .reptiles: return "reptiles"
        case .dinosaurs: return "dinosaurs"
        }
    }

    var accent: Color {
        switch self {
        case .amphibians: return .frogGreen
        case .reptiles: return .coral
        case .dinosaurs: return .dinoPurple
        }
    }

    var gradient: [Color] {
        switch self {
        case .amphibians: return [.mintGreen, .tealGreen]
        case .reptiles: return [.peach, .coral]
        case .dinosaurs: return [.lavender, .dinoPurple]
        }
    }

    var animals: [Animal] {
        switch self {
        case .amphibians:
            return [
                Animal(name: "Red-Eyed Tree Frog", assetName: "amphibians_0", symbol: "🐸", colors: [.blue, .black]),
                Animal(name: "Leopard Frog", assetName: "amphibians_1", symbol: "🐸", colors: [.brown, .olive]),
                Animal(name: "Eastern Newt", assetName: "amphibians_2", symbol: "🦎", colors: [.black, .white]),
                Animal(name: "American Toad", assetName: "amphibians_3", symbol: "🦎", colors: [.brown, .green]),
                Animal(name: "Toad", assetName: "amphibians_4", symbol: "🐸", colors: [.green, .yellow]),
                Animal(name: "Spotted Salamander", assetName: "amphibians_5", symbol: "🐸", colors: [.green, .red]),
                Animal(name: "Tree Frog", assetName: "amphibians_6", symbol: "🦎", colors: [.black, .yellow]),
                Animal(name: "African Clawed Frog", assetName: "amphibians_7", symbol: "🐸", colors: [.mint, .green]),
                Animal(name: "Red Salamander", assetName: "amphibians_8", symbol: "🦎", colors: [.orange, .green]),
                Animal(name: "Marbled Salamander", assetName: "amphibians_9", symbol: "🐸", colors: [.frogGreen, .mint]),
                Animal(name: "Glass Frog", assetName: "amphibians_10", symbol: "🐸", colors: [.green, .brown]),
                Animal(name: "Caecilian", assetName: "amphibians_11", symbol: "🐸", colors: [.green, .cyan]),
                Animal(name: "Pacific Tree Frog", assetName: "amphibians_12", symbol: "〰", colors: [.gray, .black]),
                Animal(name: "Axolotl", assetName: "amphibians_13", symbol: "🦎", colors: [.black, .orange]),
                Animal(name: "Hellbender", assetName: "amphibians_14", symbol: "🦎", colors: [.brown, .gray]),
                Animal(name: "Newt", assetName: "amphibians_15", symbol: "🦎", colors: [.orange, .red]),
                Animal(name: "Fire Salamander", assetName: "amphibians_16", symbol: "🦎", colors: [.green, .brown]),
                Animal(name: "Spring Peeper", assetName: "amphibians_17", symbol: "🐸", colors: [.green, .blue]),
                Animal(name: "Bullfrog", assetName: "amphibians_18", symbol: "🐸", colors: [.tan, .green]),
                Animal(name: "Frog", assetName: "amphibians_19", symbol: "🦎", colors: [.yellow, .black]),
                Animal(name: "Salamander", assetName: "amphibians_20", symbol: "🐸", colors: [.brown, .tan]),
                Animal(name: "Mudpuppy", assetName: "amphibians_21", symbol: "🦎", colors: [.red, .orange]),
                Animal(name: "Tiger Salamander", assetName: "amphibians_22", symbol: "🦎", colors: [.pink, .teal]),
                Animal(name: "Wood Frog", assetName: "amphibians_23", symbol: "🐸", colors: [.green, .brown]),
                Animal(name: "Poison Dart Frog", assetName: "amphibians_24", symbol: "🐸", colors: [.brown, .orange])
            ]
        case .reptiles:
            return [
                Animal(name: "Green Anaconda", assetName: "reptiles_0", symbol: "🦎", colors: [.green, .yellow]),
                Animal(name: "Bearded Dragon", assetName: "reptiles_1", symbol: "🐍", colors: [.black, .green]),
                Animal(name: "Corn Snake", assetName: "reptiles_2", symbol: "🐍", colors: [.green, .black]),
                Animal(name: "Gecko", assetName: "reptiles_3", symbol: "🦎", colors: [.green, .cyan]),
                Animal(name: "Garter Snake", assetName: "reptiles_4", symbol: "🐢", colors: [.teal, .blue]),
                Animal(name: "Monitor Lizard", assetName: "reptiles_5", symbol: "🐍", colors: [.green, .brown]),
                Animal(name: "Cobra", assetName: "reptiles_6", symbol: "🦎", colors: [.tan, .brown]),
                Animal(name: "Rattlesnake", assetName: "reptiles_7", symbol: "🐍", colors: [.brown, .orange]),
                Animal(name: "Box Turtle", assetName: "reptiles_8", symbol: "🐍", colors: [.orange, .brown]),
                Animal(name: "Leopard Gecko", assetName: "reptiles_9", symbol: "🐢", colors: [.green, .blue]),
                Animal(name: "Python", assetName: "reptiles_10", symbol: "🦎", colors: [.orange, .yellow]),
                Animal(name: "Crocodile", assetName: "reptiles_11", symbol: "🐍", colors: [.black, .brown]),
                Animal(name: "Lizard", assetName: "reptiles_12", symbol: "🐊", colors: [.green, .black]),
                Animal(name: "Tortoise", assetName: "reptiles_13", symbol: "🦎", colors: [.green, .mint]),
                Animal(name: "Chameleon", assetName: "reptiles_14", symbol: "🐊", colors: [.olive, .black]),
                Animal(name: "Boa Constrictor", assetName: "reptiles_15", symbol: "🐍", colors: [.orange, .red]),
                Animal(name: "Iguana", assetName: "reptiles_16", symbol: "🐍", colors: [.tan, .gray]),
                Animal(name: "Snapping Turtle", assetName: "reptiles_17", symbol: "🦎", colors: [.yellow, .orange]),
                Animal(name: "Komodo Dragon", assetName: "reptiles_18", symbol: "🐢", colors: [.brown, .green]),
                Animal(name: "Sea Turtle", assetName: "reptiles_19", symbol: "🐍", colors: [.black, .yellow]),
                Animal(name: "Turtle", assetName: "reptiles_20", symbol: "🦎", colors: [.green, .blue]),
                Animal(name: "Alligator", assetName: "reptiles_21", symbol: "🐢", colors: [.brown, .orange]),
                Animal(name: "King Cobra", assetName: "reptiles_22", symbol: "🐢", colors: [.tan, .green]),
                Animal(name: "Blue-Tongued Skink", assetName: "reptiles_23", symbol: "🦎", colors: [.gray, .brown]),
                Animal(name: "Snake", assetName: "reptiles_24", symbol: "🦎", colors: [.blue, .gray])
            ]
        case .dinosaurs:
            return [
                Animal(name: "T-Rex", assetName: "dinosaurs_0", symbol: "🪽", colors: [.orange, .black]),
                Animal(name: "Mosasaurus", assetName: "dinosaurs_1", symbol: "🦕", colors: [.gray, .brown]),
                Animal(name: "Triceratops", assetName: "dinosaurs_2", symbol: "🦖", colors: [.orange, .brown]),
                Animal(name: "Styracosaurus", assetName: "dinosaurs_3", symbol: "🦖", colors: [.green, .yellow]),
                Animal(name: "Ankylosaurus", assetName: "dinosaurs_4", symbol: "🪽", colors: [.blue, .orange]),
                Animal(name: "Carnotaurus", assetName: "dinosaurs_5", symbol: "🦖", colors: [.green, .red]),
                Animal(name: "Brachiosaurus", assetName: "dinosaurs_6", symbol: "🦖", colors: [.red, .orange]),
                Animal(name: "Apatosaurus", assetName: "dinosaurs_7", symbol: "🦕", colors: [.green, .mint]),
                Animal(name: "Spinosaurus", assetName: "dinosaurs_8", symbol: "🦖", colors: [.gray, .blue]),
                Animal(name: "Allosaurus", assetName: "dinosaurs_9", symbol: "🦕", colors: [.orange, .yellow]),
                Animal(name: "Diplodocus", assetName: "dinosaurs_10", symbol: "🐬", colors: [.blue, .teal]),
                Animal(name: "Oviraptor", assetName: "dinosaurs_11", symbol: "🦕", colors: [.green, .brown]),
                Animal(name: "Velociraptor", assetName: "dinosaurs_12", symbol: "🦖", colors: [.white, .orange]),
                Animal(name: "Stegosaurus", assetName: "dinosaurs_13", symbol: "🪽", colors: [.black, .gray]),
                Animal(name: "Archaeopteryx", assetName: "dinosaurs_14", symbol: "🦖", colors: [.green, .black]),
                Animal(name: "Baryonyx", assetName: "dinosaurs_15", symbol: "🦕", colors: [.yellow, .orange]),
                Animal(name: "Compsognathus", assetName: "dinosaurs_16", symbol: "🦕", colors: [.green, .blue]),
                Animal(name: "Pachycephalosaurus", assetName: "dinosaurs_17", symbol: "🦖", colors: [.orange, .red]),
                Animal(name: "Iguanodon", assetName: "dinosaurs_18", symbol: "🦕", colors: [.tan, .brown]),
                Animal(name: "Pteranodon", assetName: "dinosaurs_19", symbol: "🦕", colors: [.green, .purple]),
                Animal(name: "Parasaurolophus", assetName: "dinosaurs_20", symbol: "🦕", colors: [.orange, .yellow]),
                Animal(name: "Dilophosaurus", assetName: "dinosaurs_21", symbol: "🦖", colors: [.blue, .green]),
                Animal(name: "Kentrosaurus", assetName: "dinosaurs_22", symbol: "🦕", colors: [.yellow, .red]),
                Animal(name: "Plesiosaurus", assetName: "dinosaurs_23", symbol: "🦕", colors: [.gray, .green]),
                Animal(name: "Argentavis", assetName: "dinosaurs_24", symbol: "🐬", colors: [.blue, .gray])
            ]
        }
    }
}

struct HomeView: View {
    let onPlay: () -> Void
    let onInstructions: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 42)

            VStack(spacing: 8) {
                BrandFrog(size: 138)
                BrandLogo(width: 250)

                Text("Educational Animal Adventure")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.soil)
                    .padding(.top, 12)
            }

            Spacer()

            Button(action: onPlay) {
                Label("PLAY", systemImage: "play.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
            .buttonStyle(PillButtonStyle(color: .frogGreen))
            .padding(.horizontal, 72)

            HStack(spacing: 18) {
                SecondaryHomeButton(title: "Instructions", icon: "questionmark.circle", action: onInstructions)
                SecondaryHomeButton(title: "Settings", icon: "gearshape", action: onSettings)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

struct OnboardingView: View {
    @Binding var page: Int
    let onSkip: () -> Void
    let onFinish: () -> Void

    private let pages = OnboardingPage.pages

    var body: some View {
        VStack {
            PageDots(current: page, total: pages.count)
                .padding(.top, 22)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                Button("Skip", action: onSkip)
                    .font(.headline)
                    .foregroundStyle(Color.charcoal.opacity(0.72))

                Spacer()

                Button(action: {
                    if page == pages.count - 1 {
                        onFinish()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            page += 1
                        }
                    }
                }) {
                    Label(page == pages.count - 1 ? "Start Playing" : "Next", systemImage: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 18)
                }
                .buttonStyle(PillButtonStyle(color: .frogGreen))
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 30)
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let kind: Kind

    enum Kind {
        case welcome
        case categories
        case modes
        case bingo
    }

    static let pages = [
        OnboardingPage(title: "Welcome to", subtitle: "Learn amazing animals while playing bingo!", kind: .welcome),
        OnboardingPage(title: "Choose Your Favorite Animal World!", subtitle: "Explore three amazing categories", kind: .categories),
        OnboardingPage(title: "Two Ways to Play!", subtitle: "", kind: .modes),
        OnboardingPage(title: "BINGO!", subtitle: "Complete lines and become a nature expert!", kind: .bingo)
    ]
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            switch page.kind {
            case .welcome:
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(Color.charcoal)
                    BrandFrog(size: 116)
                    BrandLogo(width: 248)
                    Text(page.subtitle)
                        .font(.title3)
                        .foregroundStyle(Color.soil)
                        .multilineTextAlignment(.center)
                        .padding(.top, 18)
                }
            case .categories:
                VStack(spacing: 18) {
                    Text(page.title)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.charcoal)
                        .multilineTextAlignment(.center)
                    Text(page.subtitle)
                        .font(.headline)
                        .foregroundStyle(Color.soil)
                    VStack(spacing: 16) {
                        ForEach(AnimalCategory.allCases) { category in
                            CategoryBanner(category: category, compact: true)
                        }
                    }
                    .padding(.horizontal, 54)
                }
            case .modes:
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(Color.charcoal)
                    ModeIntroCard(mode: .guessName)
                    ModeIntroCard(mode: .findPicture)
                }
                .padding(.horizontal, 24)
            case .bingo:
                VStack(spacing: 20) {
                    TrophyBadge()
                    Text(page.title)
                        .font(.system(size: 52, weight: .regular))
                        .foregroundStyle(Color.charcoal)
                    Text(page.subtitle)
                        .font(.title3)
                        .foregroundStyle(Color.soil)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 18) {
                        MiniCreature(symbol: "🐸", label: "Frogs", color: .frogGreen)
                        MiniCreature(symbol: "🦖", label: "Dinos", color: .dinoPurple)
                        MiniCreature(symbol: "🦎", label: "Reptiles", color: .coral)
                    }
                    .padding(24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                }
            }

            Spacer()
        }
    }
}

struct CategoryView: View {
    let onBack: () -> Void
    let onSelect: (AnimalCategory) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                BackButton(title: "Back", action: onBack)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    Text("Choose Your\nAnimal World")
                        .font(.system(size: 34, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.charcoal)
                    Text("Pick a category to start playing!")
                        .font(.title3)
                        .foregroundStyle(Color.soil)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 20) {
                    ForEach(AnimalCategory.allCases) { category in
                        Button { onSelect(category) } label: {
                            CategoryBanner(category: category, compact: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct ModePickerView: View {
    let category: AnimalCategory
    @Binding var selectedMode: GameMode
    let onBack: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            BackButton(title: "Back", action: onBack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 22)

            Text(category.rawValue)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Color.charcoal)

            Text(category.shortSubtitle)
                .font(.title3)
                .foregroundStyle(Color.soil)

            VStack(spacing: 16) {
                ForEach(GameMode.allCases) { mode in
                    Button { selectedMode = mode } label: {
                        HStack(spacing: 18) {
                            Image(systemName: mode.icon)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 58, height: 58)
                                .background(mode.tint)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(mode.rawValue)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.charcoal)
                                Text(mode.caption)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.soil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(selectedMode == mode ? category.accent : .gray.opacity(0.35))
                        }
                        .padding(18)
                        .background(selectedMode == mode ? mode.tint.opacity(0.12) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button(action: onStart) {
                Label("Start Game", systemImage: "play.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .buttonStyle(PillButtonStyle(color: category.accent))
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}

struct GameView: View {
    let category: AnimalCategory
    let mode: GameMode
    let soundEnabled: Bool
    let vibrationEnabled: Bool
    let audio: AudioController
    let onBack: () -> Void
    let onHome: () -> Void

    @State private var animals: [Animal] = []
    @State private var marked: Set<UUID> = []
    @State private var targetIndex = 0
    @State private var seconds = 0
    @State private var didWin = false
    @State private var paused = false
    @State private var wrongAnswer: UUID?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var target: Animal {
        guard animals.indices.contains(targetIndex) else { return category.animals[0] }
        return animals[targetIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            GameTopBar(
                seconds: seconds,
                score: marked.count,
                paused: paused,
                onBack: onBack,
                onPause: { paused.toggle() }
            )

            ZStack {
                LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .bottom)

                if didWin {
                    WinView(
                        category: category,
                        seconds: seconds,
                        score: marked.count,
                        onAgain: resetGame,
                        onHome: onHome
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 24) {
                        PromptCard(category: category, mode: mode, animal: target)
                            .padding(.top, 34)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                            ForEach(animals) { animal in
                                BingoCell(
                                    category: category,
                                    animal: animal,
                                    mode: mode,
                                    isMarked: marked.contains(animal.id),
                                    isWrong: wrongAnswer == animal.id,
                                    action: { choose(animal) }
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .onAppear(perform: resetGame)
        .onReceive(timer) { _ in
            guard !didWin && !paused else { return }
            seconds += 1
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: didWin)
    }

    private func choose(_ animal: Animal) {
        guard !marked.contains(animal.id), !didWin, !paused else { return }

        if animal.id == target.id {
            audio.playCorrectAnswer(enabled: soundEnabled)
            marked.insert(animal.id)
            if hasBingo() {
                finishWin()
            } else {
                moveToNextTarget()
            }
        } else {
            audio.playWrongAnswer(enabled: soundEnabled)
            wrongAnswer = animal.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                wrongAnswer = nil
            }
        }
    }

    private func moveToNextTarget() {
        let remainingIndices = animals.indices.filter { !marked.contains(animals[$0].id) }
        guard let index = remainingIndices.randomElement() else {
            finishWin()
            return
        }
        targetIndex = index
    }

    private func finishWin() {
        guard !didWin else { return }
        audio.playWin(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled)
        didWin = true
    }

    private func resetGame() {
        animals = category.animals.shuffled()
        marked = []
        targetIndex = animals.indices.randomElement() ?? 0
        seconds = 0
        didWin = false
        paused = false
        wrongAnswer = nil
    }

    private func hasBingo() -> Bool {
        let winningLines = [
            [0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
            [15, 16, 17, 18, 19], [20, 21, 22, 23, 24],
            [0, 5, 10, 15, 20], [1, 6, 11, 16, 21], [2, 7, 12, 17, 22],
            [3, 8, 13, 18, 23], [4, 9, 14, 19, 24],
            [0, 6, 12, 18, 24], [4, 8, 12, 16, 20]
        ]

        return winningLines.contains { line in
            line.allSatisfy { index in
                animals.indices.contains(index) && marked.contains(animals[index].id)
            }
        }
    }
}

struct InstructionsView: View {
    let onBack: () -> Void
    let onStart: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                BackButton(title: "Back", action: onBack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 18)

                VStack(spacing: 10) {
                    Text("How to Play")
                        .font(.system(size: 38, weight: .regular))
                        .foregroundStyle(Color.charcoal)
                    Text("Learn the rules of Frogger Bingo!")
                        .font(.title3)
                        .foregroundStyle(Color.soil)
                }

                InstructionCard(icon: "🐸", color: .frogGreen, title: "Choose a Category") {
                    Text("Start by selecting your favorite animal world: Amphibians, Reptiles, or Dinosaurs. Each category has unique creatures to discover!")
                    HStack {
                        MiniCreature(symbol: "🐸", label: "Amphibians", color: .frogGreen)
                        MiniCreature(symbol: "🦎", label: "Reptiles", color: .coral)
                        MiniCreature(symbol: "🦖", label: "Dinosaurs", color: .dinoPurple)
                    }
                }

                InstructionCard(icon: "T", color: .coral, title: "Select Game Mode") {
                    Text("Pick your preferred way to play bingo:")
                    ModeExplainer(mode: .guessName)
                    ModeExplainer(mode: .findPicture)
                }

                InstructionCard(icon: "▦", color: .dinoPurple, title: "Play the Game") {
                    Text("Match animals with their names or pictures on the 5x5 bingo grid. Each correct answer marks a cell!")
                    HStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { index in
                            ZStack {
                                Circle()
                                    .fill(index < 2 ? Color.frogGreen : Color.white)
                                if index < 2 {
                                    Image(systemName: "checkmark")
                                        .font(.title2.weight(.bold))
                                }
                            }
                            .frame(width: 48, height: 48)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.dinoPurple.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                InstructionCard(icon: "🏆", color: .gold, title: "Win the Game") {
                    Text("Complete a full line horizontally, vertically, or diagonally to win. You will see your time, score, and star rating.")
                }

                Button(action: onStart) {
                    Text("Start Playing!")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(PillButtonStyle(color: .frogGreen))
                .padding(.horizontal, 64)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct SettingsView: View {
    @Binding var soundEnabled: Bool
    @Binding var musicEnabled: Bool
    @Binding var vibrationEnabled: Bool
    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                BackButton(title: "Back", action: onBack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 22)

                Text("Settings")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color.charcoal)
                Text("Customize your experience")
                    .font(.title3)
                    .foregroundStyle(Color.soil)
                    .padding(.bottom, 14)

                SettingRow(icon: "speaker.wave.2.fill", color: .frogGreen, title: "Sound Effects", subtitle: "Game sounds and feedback", isOn: $soundEnabled)
                SettingRow(icon: "music.note", color: .coral, title: "Background Music", subtitle: "Play relaxing tunes", isOn: $musicEnabled)
                SettingRow(icon: "iphone", color: .dinoPurple, title: "Vibration", subtitle: "Haptic feedback", isOn: $vibrationEnabled)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        Image(systemName: "info.circle")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.frogGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("About Frogger Bingo")
                                .font(.title3.weight(.semibold))
                            Text("An educational game for children ages 4-10 to learn about amphibians, reptiles, and dinosaurs through fun bingo gameplay.")
                                .font(.subheadline)
                                .foregroundStyle(Color.soil)
                        }
                    }

                    HStack {
                        StatSmall(title: "Version", value: "1.0.0")
                        Spacer()
                        StatSmall(title: "Categories", value: "3")
                        Spacer()
                        StatSmall(title: "Animals", value: "75+")
                    }
                }
                .foregroundStyle(Color.charcoal)
                .padding(24)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
                .padding(.top, 14)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct GameTopBar: View {
    let seconds: Int
    let score: Int
    let paused: Bool
    let onBack: () -> Void
    let onPause: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(Color.charcoal)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "stopwatch")
                Text(format(seconds))
            }

            HStack(spacing: 8) {
                Image(systemName: "trophy")
                Text("\(score)/25")
            }
            .padding(.leading, 18)

            Spacer()

            Button(action: onPause) {
                Image(systemName: paused ? "play.fill" : "pause")
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(Color.charcoal)
        }
        .font(.headline)
        .foregroundStyle(Color.charcoal)
        .padding(.horizontal, 22)
        .frame(height: 92)
        .background(Color.gameTop)
        .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
    }
}

struct PromptCard: View {
    let category: AnimalCategory
    let mode: GameMode
    let animal: Animal

    var body: some View {
        VStack(spacing: 20) {
            if mode == .guessName {
                Text("Who is shown in the picture?")
                    .font(.headline)
                    .foregroundStyle(Color.soil)
                AnimalPicture(category: category, animal: animal, size: 138, rounded: 22)
            } else {
                Text("Where do you see \(Text(animal.name).bold())?")
                    .font(.headline)
                    .foregroundStyle(Color.soil)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(minHeight: 48)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, mode == .guessName ? 28 : 40)
        .padding(.horizontal, 24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
    }
}

struct BingoCell: View {
    let category: AnimalCategory
    let animal: Animal
    let mode: GameMode
    let isMarked: Bool
    let isWrong: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if mode == .guessName {
                    Text(animal.bingoTitle)
                        .font(.system(size: animal.bingoTitle.contains("\n") ? 9 : 10, weight: .medium))
                        .foregroundStyle(Color.charcoal)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .lineSpacing(-1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.58)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    AnimalPicture(category: category, animal: animal, size: 58, rounded: 14)
                }

                if isMarked {
                    Color.frogGreen.opacity(0.82)
                    Image(systemName: "checkmark")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: mode == .guessName ? 60 : 58)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: mode == .guessName ? 14 : 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: mode == .guessName ? 14 : 16, style: .continuous)
                    .stroke(isWrong ? Color.red : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(mode == .guessName ? 0.10 : 0.20), radius: 7, y: 5)
            .scaleEffect(isWrong ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isMarked)
    }
}

struct WinView: View {
    let category: AnimalCategory
    let seconds: Int
    let score: Int
    let onAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal, .blue, category.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ConfettiLayer()

            VStack(spacing: 24) {
                Spacer(minLength: 28)

                TrophyBadge()
                VStack(spacing: -8) {
                    LogoText(text: "BINGO!", color: .orange)
                }
                Text("The \(category.rawValue.lowercased()) are proud of you!")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)

                HStack(spacing: 18) {
                    ResultStat(icon: "trophy", title: "Animals\nFound", value: "\(score)", color: .frogGreen)
                    ResultStat(icon: "stopwatch", title: "Time", value: format(seconds), color: .coral)
                    ResultStat(icon: "star.fill", title: "Rating", value: "★★★", color: .dinoPurple)
                }
                .padding(24)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    Button(action: onAgain) {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .frame(height: 88)
                    }
                    .buttonStyle(PillButtonStyle(color: .frogGreen, radius: 14))

                    Button(action: onHome) {
                        Label("Home", systemImage: "house")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.charcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .frame(height: 88)
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

struct CategoryBanner: View {
    let category: AnimalCategory
    let compact: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(category.cardAssetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(height: compact ? 106 : 142)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 7)
    }
}

struct AnimalPicture: View {
    let category: AnimalCategory
    let animal: Animal
    let size: CGFloat
    let rounded: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: animal.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(.white.opacity(0.24))
                .frame(width: size * 0.8)
                .offset(x: -size * 0.22, y: -size * 0.24)
            Circle()
                .fill(.black.opacity(0.16))
                .frame(width: size * 0.64)
                .offset(x: size * 0.24, y: size * 0.28)
            Text(animal.symbol)
                .font(.system(size: size * 0.48))
                .shadow(color: .black.opacity(0.22), radius: 4, y: 3)
            Image(animal.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: rounded, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 12, y: 9)
    }
}

struct BrandFrog: View {
    let size: CGFloat

    var body: some View {
        Image("brand_frog")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
        .frame(width: size, height: size)
    }
}

struct BrandLogo: View {
    let width: CGFloat

    var body: some View {
        Image("brand_logo")
            .resizable()
            .scaledToFit()
            .frame(width: width)
        .frame(width: width, height: width * 0.38)
    }
}

struct PondBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.paleMint, .softMint, .mintGreen.opacity(0.65)], startPoint: .top, endPoint: .bottom)

            ForEach(0..<14, id: \.self) { index in
                LeafShape()
                    .fill(Color.leafGreen.opacity(index.isMultiple(of: 2) ? 0.20 : 0.12))
                    .frame(width: CGFloat([58, 74, 42, 92, 38][index % 5]), height: CGFloat([24, 34, 20, 42, 18][index % 5]))
                    .rotationEffect(.degrees(Double(index * 31)))
                    .offset(x: CGFloat([-165, -98, -22, 74, 142, 176, -142][index % 7]),
                            y: CGFloat([-340, -244, -160, -70, 45, 162, 284][index % 7]))
            }

            ForEach(0..<5, id: \.self) { index in
                Ellipse()
                    .stroke(.white.opacity(0.28), lineWidth: 2)
                    .frame(width: CGFloat(210 + index * 38), height: CGFloat(46 + index * 10))
                    .offset(y: CGFloat(210 + index * 34))
            }
        }
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.25))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.25))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY))
        return path
    }
}

struct LogoText: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 33, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .shadow(color: .white, radius: 0, x: 2, y: 2)
            .shadow(color: .white, radius: 0, x: -2, y: -2)
            .shadow(color: .black.opacity(0.24), radius: 0, x: 3, y: 4)
    }
}

struct BackButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "chevron.left")
                .font(.headline)
                .foregroundStyle(Color.charcoal)
        }
    }
}

struct SecondaryHomeButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Color.charcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .background(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
    }
}

struct PageDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.frogGreen : Color.white.opacity(0.72))
                    .frame(width: index == current ? 32 : 8, height: 8)
            }
        }
    }
}

struct ModeIntroCard: View {
    let mode: GameMode

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 18) {
                Text(mode == .guessName ? "A" : "B")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(mode.tint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(mode.rawValue)
                    .font(.title2.weight(.semibold))
            }

            HStack(spacing: 12) {
                if mode == .guessName {
                    MiniCreature(symbol: "🐸", label: "", color: .frogGreen)
                    Text("See an animal picture,\nchoose the correct name!")
                        .font(.subheadline)
                        .foregroundStyle(Color.soil)
                } else {
                    MiniCreature(symbol: "🐸", label: "", color: .coral)
                    MiniCreature(symbol: "🦎", label: "", color: .coral)
                    MiniCreature(symbol: "🦖", label: "", color: .coral)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(mode.tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .foregroundStyle(Color.charcoal)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 8)
    }
}

struct MiniCreature: View {
    let symbol: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(symbol)
                .font(.system(size: 28))
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.soil)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }
}

struct TrophyBadge: View {
    var body: some View {
        Image(systemName: "trophy")
            .font(.system(size: 58, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 132, height: 132)
            .background(Color.gold)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
    }
}

struct InstructionCard<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(color)
                    .clipShape(Circle())
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.charcoal)
            }

            content
                .font(.body)
                .foregroundStyle(Color.soil)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.13), radius: 14, y: 7)
    }
}

struct ModeExplainer: View {
    let mode: GameMode

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: mode.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(mode.tint)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.rawValue)
                    .font(.headline)
                    .foregroundStyle(Color.charcoal)
                Text(mode.caption)
                    .font(.subheadline)
                    .foregroundStyle(Color.soil)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(mode.tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SettingRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.charcoal)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.soil)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.13), radius: 14, y: 8)
    }
}

struct StatSmall: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.soil)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.charcoal)
        }
    }
}

struct ResultStat: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 66, height: 66)
                .background(color)
                .clipShape(Circle())
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.soil)
                .frame(height: 30)
            Text(value)
                .font(value.contains("★") ? .title2.weight(.bold) : .system(size: 30, weight: .regular))
                .foregroundStyle(value.contains("★") ? Color.gold : Color.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ConfettiLayer: View {
    private let colors: [Color] = [.gold, .coral, .frogGreen, .dinoPurple, .white]

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<34, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat(5 + (index % 4) * 3), height: CGFloat(8 + (index % 3) * 4))
                    .rotationEffect(.degrees(Double(index * 19)))
                    .position(
                        x: CGFloat((index * 47) % Int(max(proxy.size.width, 1))),
                        y: CGFloat((index * 83) % Int(max(proxy.size.height, 1)))
                    )
                    .opacity(0.85)
            }
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    let color: Color
    var radius: CGFloat = 38

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: color.opacity(0.32), radius: configuration.isPressed ? 6 : 14, y: configuration.isPressed ? 3 : 9)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

func format(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return String(format: "%d:%02d", minutes, remainder)
}

extension String {
    var assetSlug: String {
        lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

extension Color {
    static let paleMint = Color(red: 0.91, green: 0.98, blue: 0.91)
    static let softMint = Color(red: 0.72, green: 0.94, blue: 0.76)
    static let mintGreen = Color(red: 0.44, green: 0.86, blue: 0.57)
    static let tealGreen = Color(red: 0.00, green: 0.67, blue: 0.50)
    static let leafGreen = Color(red: 0.31, green: 0.69, blue: 0.28)
    static let frogGreen = Color(red: 0.34, green: 0.72, blue: 0.36)
    static let coral = Color(red: 1.00, green: 0.45, blue: 0.31)
    static let peach = Color(red: 1.00, green: 0.72, blue: 0.53)
    static let dinoPurple = Color(red: 0.53, green: 0.38, blue: 0.78)
    static let lavender = Color(red: 0.71, green: 0.46, blue: 1.00)
    static let gold = Color(red: 1.00, green: 0.74, blue: 0.00)
    static let charcoal = Color(red: 0.19, green: 0.19, blue: 0.21)
    static let soil = Color(red: 0.43, green: 0.29, blue: 0.25)
    static let gameTop = Color(red: 0.96, green: 0.98, blue: 0.95)
    static let olive = Color(red: 0.38, green: 0.45, blue: 0.16)
    static let tan = Color(red: 0.78, green: 0.62, blue: 0.43)
}
