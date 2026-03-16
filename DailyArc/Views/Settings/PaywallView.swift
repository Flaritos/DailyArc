import SwiftUI
import StoreKit

/// Premium purchase sheet.
/// Shows feature benefits, localized price from StoreKit, purchase & restore actions.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeKit = StoreKitManager.shared
    @State private var showDismissToast = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DailyArcSpacing.xl) {
                    Spacer(minLength: DailyArcSpacing.lg)

                    // App Icon
                    Image(systemName: "circle.dotted.and.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(DailyArcTokens.accent)
                        .accessibilityHidden(true)

                    // Title
                    Text("Unlock Your Full Arc")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("One payment. Yours forever.")
                        .font(.system(size: 16))
                        .foregroundStyle(DailyArcTokens.textSecondary)

                    // Privacy differentiator
                    Text("Your insights. Your device. Your price.")
                        .font(.system(size: 16))
                        .foregroundStyle(DailyArcTokens.textTertiary)

                    // Feature list
                    VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
                        featureRow("Track every habit, not just three")
                        featureRow("See how your habits shape your mood")
                        featureRow("Get personalized suggestions that grow with you")
                        featureRow("Explore your trends over weeks and months")
                        featureRow("Export everything, anytime")
                        featureRow("Home screen widgets that keep your arc visible")
                    }
                    .padding(.horizontal, DailyArcSpacing.lg)

                    // Price
                    if let product = storeKit.premiumProduct {
                        VStack(spacing: DailyArcSpacing.xs) {
                            Text("\(product.displayPrice) one-time")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(DailyArcTokens.accent)

                            // Per-day cost anchoring
                            let perDay = product.price / 365
                            Text("That's \(perDay.formatted(.currency(code: product.priceFormatStyle.currencyCode ?? "USD").precision(.fractionLength(0...2)))) a day after your first year.")
                                .typography(.caption)
                                .foregroundStyle(DailyArcTokens.textTertiary)

                            Text("No subscriptions. No recurring charges.")
                                .font(.system(size: 14))
                                .foregroundStyle(DailyArcTokens.textTertiary)
                        }
                    } else {
                        ProgressView()
                            .padding()
                    }

                    // Purchase Button
                    purchaseButton

                    // Restore
                    Button {
                        Task { await storeKit.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.accent)
                    }

                    // Error
                    if let error = storeKit.errorMessage {
                        Text(error)
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DailyArcSpacing.lg)
                    }

                    // Not Now
                    Button {
                        showDismissToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    } label: {
                        Text("Not now")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                    }

                    Spacer(minLength: DailyArcSpacing.xxl)
                }
                .padding(.horizontal, DailyArcSpacing.lg)
            }
            .background(DailyArcTokens.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showDismissToast {
                    Text("No worries — DailyArc is great free too.")
                        .typography(.bodySmall)
                        .padding(DailyArcSpacing.md)
                        .background(DailyArcTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                        .shadow(color: DailyArcTokens.cardShadow, radius: 8)
                        .padding(.bottom, DailyArcSpacing.xxl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: showDismissToast)
                }
            }
            .onChange(of: storeKit.purchaseState) { _, newValue in
                if newValue == .success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DailyArcSpacing.sm) {
            Image(systemName: "checkmark")
                .font(.body.bold())
                .foregroundStyle(DailyArcTokens.success)
                .frame(width: 24)
            Text(text)
                .typography(.bodyLarge)
                .foregroundStyle(DailyArcTokens.textPrimary)
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        Button {
            Task { await storeKit.purchase() }
        } label: {
            Group {
                switch storeKit.purchaseState {
                case .idle, .error:
                    Text("Unlock Your Arc")
                        .typography(.bodyLarge)
                        .fontWeight(.semibold)
                case .loading:
                    ProgressView()
                        .tint(.white)
                case .success:
                    Image(systemName: "checkmark")
                        .font(.title2.bold())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(DailyArcTokens.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
        }
        .disabled(storeKit.purchaseState == .loading || storeKit.purchaseState == .success)
        .padding(.horizontal, DailyArcSpacing.lg)
    }
}
