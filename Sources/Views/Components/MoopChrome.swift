import SwiftUI

// the wordmark and whatever the screen wants to say on the right
struct MoopHeader: View {
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("moop.")
                .font(MoopType.title)
                .foregroundStyle(Moop.ink)
            Spacer()
            if let trailing {
                Text(trailing.uppercased())
                    .font(MoopType.micro)
                    .tracking(0.8)
                    .foregroundStyle(Moop.ink.opacity(0.6))
            }
        }
        .padding(.horizontal, Space.gutter)
    }
}

// the one loud action on a screen
struct MoopAction: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(MoopType.statement)
                    .foregroundStyle(Moop.onAccent)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Moop.onAccent)
            }
            .padding(.horizontal, Space.beat)
            .frame(height: 56)
            .background(Moop.citrus, in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct MoopBadge: View {
    var text: String
    var tint: Color = Moop.citrus

    var body: some View {
        Text(text.uppercased())
            .font(MoopType.micro)
            .tracking(0.6)
            .foregroundStyle(Moop.onAccent)
            .padding(.horizontal, Space.cut)
            .frame(height: 26)
            .background(tint, in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
    }
}

// every photo in moop is square, whatever shape it arrived in, so a week of
// them reads as one grid instead of a ragged column.
struct PhotoCard: View {
    var image: UIImage?
    var corner: CGFloat = Edge.soft

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Moop.veil
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

// one back link, so every pushed screen leaves the same way
struct MoopBack: View {
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.dot) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(MoopType.detail)
            }
            .foregroundStyle(Moop.violet)
            .padding(.vertical, Space.tick)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to \(label)")
    }
}

// destructive, and it looks it. the trash is the only red thing on the screen.
struct MoopTrash: View {
    var what: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Moop.alert)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete \(what)")
    }
}

// a quiet row of label and value, used all over settings
struct MoopRow: View {
    var label: String
    var value: String?
    var tint: Color = Moop.ink
    var chevron = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(MoopType.reading)
                    .foregroundStyle(tint)
                Spacer()
                if let value {
                    Text(value)
                        .font(MoopType.detail)
                        .foregroundStyle(Moop.violet)
                }
                if chevron {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Moop.violet)
                }
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}
