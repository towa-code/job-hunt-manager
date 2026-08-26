import SwiftUI

/// モダン・ミニマルなライトUIのデザインシステム
extension Color {
    /// 背景の地色（淡いオフホワイト）
    static let surface = Color(red: 0.973, green: 0.973, blue: 0.976)
    /// カード・行などの一段明るい面
    static let surfaceRaised = Color(red: 1.0, green: 1.0, blue: 1.0)
    /// カードの境界線
    static let surfaceBorder = Color.black.opacity(0.07)
    /// 本文テキスト
    static let textPrimary = Color(red: 0.106, green: 0.114, blue: 0.137)
    /// 補足テキスト
    static let textSecondary = Color(red: 0.486, green: 0.502, blue: 0.537)
    /// シグナルカラー（強調・通知・志望度）
    static let signal = Color(red: 1.0, green: 0.541, blue: 0.239)

    // ステータス用インジケータカラー
    static let statusBlue = Color(red: 0.231, green: 0.435, blue: 0.878)
    static let statusCyan = Color(red: 0.078, green: 0.659, blue: 0.643)
    static let statusViolet = Color(red: 0.427, green: 0.310, blue: 0.878)
    static let statusGreen = Color(red: 0.086, green: 0.639, blue: 0.290)
    static let statusRed = Color(red: 0.882, green: 0.114, blue: 0.282)
    static let statusGray = Color(red: 0.420, green: 0.447, blue: 0.502)

    /// 選考区分「インターン」のバッジ
    static let internBadge = Color(red: 0.129, green: 0.494, blue: 0.635)
}

// `.foregroundStyle(.textPrimary)` のように暗黙メンバとして使えるようにする
extension ShapeStyle where Self == Color {
    static var surface: Color { .surface }
    static var surfaceRaised: Color { .surfaceRaised }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var signal: Color { .signal }
}

extension Font {
    /// 見出し用の丸ゴシック
    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// ラベル・ピル用
    static let pillLabel = Font.system(.caption, design: .rounded).weight(.semibold)

    /// カレンダーの帯など、ピルより一段小さいラベル用
    static let barLabel = Font.system(.caption2, design: .rounded).weight(.semibold)

    /// 日付・数値用の等幅フォント
    static let mono = Font.system(.callout, design: .monospaced)
}

/// 右上にシグナルカラーのグロウを置いた、明るい背景
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color.surface
            RadialGradient(
                colors: [Color.signal.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

/// 各タブ最上部の見出し行。右端に任意のアクションを置ける
struct PageHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.heading(22))
                .foregroundStyle(.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.leading, 32)
        .padding(.trailing, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

extension PageHeader where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

/// ヘッダー右の主アクション。シグナルカラーで塗る
struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pillLabel)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.signal, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// ヘッダー右の副アクション。枠線だけの控えめなカプセル
struct SecondaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .secondaryCapsule()
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    /// 副アクションのカプセル装飾。ButtonStyle を挟めない Menu のラベルにも使う
    func secondaryCapsule() -> some View {
        font(.pillLabel)
            .foregroundStyle(Color.signal)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.surfaceRaised, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.surfaceBorder, lineWidth: 1))
    }
}

/// 選考ステータスを示すドット付きピル
/// 選考区分のバッジ。本選考は既定なので、インターンのときだけ出す想定
struct KindBadgeView: View {
    let kind: SelectionKind

    var body: some View {
        Text(kind.label)
            .font(.pillLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.internBadge.opacity(0.14), in: Capsule())
            .foregroundStyle(Color.internBadge)
    }
}

struct StatusPillView: View {
    let status: SelectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.indicatorColor)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.pillLabel)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.surfaceRaised, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.surfaceBorder, lineWidth: 1)
        )
    }
}

/// 志望度を示すドットインジケータ（●●○）
struct PriorityDotsView: View {
    let priority: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < priority ? Color.signal : Color.surfaceBorder)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

/// カード風のコンテナ
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.surfaceBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
}
