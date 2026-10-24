import SwiftUI

enum Tab: CaseIterable {
    case today, history, settings

    var label: String {
        switch self {
        case .today: "Today"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: "house"
        case .history: "calendar"
        case .settings: "gearshape"
        }
    }

    // calendar has no filled twin, so the selected symbol is named rather than
    // built by appending .fill
    var selectedIcon: String {
        switch self {
        case .today: "house.fill"
        case .history: "calendar"
        case .settings: "gearshape.fill"
        }
    }
}

struct MoopTabBar: View {
    @Binding var selection: Tab
    var reselect: (Tab) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    if selection == tab { reselect(tab) } else { selection = tab }
                } label: {
                    VStack(spacing: Space.dot) {
                        Rectangle()
                            .fill(selection == tab ? Moop.violet : .clear)
                            .frame(width: 26, height: 2)
                        Image(systemName: selection == tab ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 19))
                        Text(tab.label)
                            .font(MoopType.micro)
                    }
                    .foregroundStyle(selection == tab ? Moop.violet : Moop.ink.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.top, Space.tick)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
            }
        }
        .frame(height: 66)
        .background(Moop.canvas)
        .overlay(alignment: .top) {
            Rectangle().fill(Moop.veil).frame(height: 1)
        }
    }
}
