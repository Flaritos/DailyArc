import StoreKit
import SwiftUI

/// StoreKit 2 integration for DailyArc premium.
/// Product: "com.dailyarc.premium" — non-consumable lifetime unlock ($5.99).
/// @AppStorage("isPremium") is a CACHE only. Source of truth: Transaction.currentEntitlements.
@Observable
@MainActor
final class StoreKitManager {

    // MARK: - Singleton

    static let shared = StoreKitManager()

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var errorMessage: String?

    /// Cached premium status — optimistic loading from AppStorage on launch.
    var isPremium: Bool {
        get {
            access(keyPath: \.isPremium)
            return UserDefaults.standard.bool(forKey: "isPremium")
        }
        set {
            withMutation(keyPath: \.isPremium) {
                UserDefaults.standard.set(newValue, forKey: "isPremium")
            }
        }
    }

    enum PurchaseState: Sendable {
        case idle
        case loading
        case success
        case error
    }

    // MARK: - Constants

    private static let productID = "com.dailyarc.premium"

    // MARK: - Private

    private nonisolated(unsafe) var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    private init() {
        transactionListenerTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task {
            await loadProducts()
            await checkEntitlement()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available products from the App Store.
    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.productID])
        } catch {
            products = []
        }
    }

    /// Purchase the premium product.
    func purchase() async {
        guard let product = products.first else {
            purchaseState = .error
            errorMessage = "Product not available. Please try again later."
            return
        }

        purchaseState = .loading
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPremium = true
                purchaseState = .success
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .error
            errorMessage = "Something went sideways. Tap to try again."
        }
    }

    /// Restore previous purchases (Family Sharing included).
    func restorePurchases() async {
        purchaseState = .loading
        errorMessage = nil

        do {
            try await AppStore.sync()
            await checkEntitlement()

            if isPremium {
                purchaseState = .success
            } else {
                purchaseState = .error
                errorMessage = "No previous purchase found. Make sure you're signed into the same Apple ID."
            }
        } catch {
            purchaseState = .error
            errorMessage = "Could not restore purchases. Please try again."
        }
    }

    /// Verify entitlement from Transaction.currentEntitlements.
    func checkEntitlement() async {
        var foundPremium = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                foundPremium = true
                break
            }
        }

        isPremium = foundPremium
    }

    // MARK: - Private

    /// Listen for transaction updates (purchases, refunds, Family Sharing changes).
    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.productID {
                    if transaction.revocationDate == nil {
                        isPremium = true
                    } else {
                        isPremium = false
                    }
                }
                await transaction.finish()
            }
        }
    }

    /// Verify a StoreKit transaction result.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }

    /// The premium product, if loaded.
    var premiumProduct: Product? {
        products.first { $0.id == Self.productID }
    }
}
