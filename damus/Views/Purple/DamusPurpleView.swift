//
//  DamusPurpleView.swift
//  damus
//
//  Created by William Casarin on 2023-03-21.
//

import SwiftUI
import StoreKit

fileprivate let damus_products = ["purpleyearly","purple"]

enum ProductState {
    case loading
    case loaded([Product])
    case failed
    
    var products: [Product]? {
        switch self {
        case .loading:
            return nil
        case .loaded(let ps):
            return ps
        case .failed:
            return nil
        }
    }
}

func non_discounted_price(_ product: Product) -> String {
    return (product.price * 1.1984569224).formatted(product.priceFormatStyle)
}

enum DamusPurpleType: String {
    case yearly = "purpleyearly"
    case monthly = "purple"
}

struct PurchasedProduct {
    let tx: StoreKit.Transaction
    let product: Product
}

struct DamusPurpleView: View {
    @State var products: ProductState
    @State var purchased: PurchasedProduct? = nil
    @State var selection: DamusPurpleType = .yearly
    
    @Environment(\.dismiss) var dismiss
    
    init() {
        self._products = State(wrappedValue: .loading)
    }
    
    var body: some View {
        ZStack {
            DamusGradient()
            
            ScrollView {
                MainContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackNav())
        .onReceive(handle_notify(.switched_timeline)) { _ in
            dismiss()
        }
        .onAppear {
            notify(.display_tabbar, false)
        }
        .onDisappear {
            notify(.display_tabbar, true)
        }
        .task {
            await load_products()
        }
    }
    
    func handle_transactions(products: [Product]) async {
        for await update in StoreKit.Transaction.updates {
            switch update {
            case .verified(let tx):
                let prod = products.filter({ prod in tx.productID == prod.id }).first
                
                if let prod,
                   let expiration = tx.expirationDate,
                   Date.now < expiration
                {
                    self.purchased = PurchasedProduct(tx: tx, product: prod)
                    break
                }
            case .unverified:
                continue
            }
        }
    }
    
    func load_products() async {
        do {
            let products = try await Product.products(for: damus_products)
            self.products = .loaded(products)
            await handle_transactions(products: products)

            print("loaded products", products)
        } catch {
            self.products = .failed
            print("Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    func Icon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .frame(width: 50, height: 50)
    }
    
    func Title(_ txt: String) -> some View {
        Text(txt)
            .font(.title)
            .foregroundColor(.white)
    }
    
    func Subtitle(_ txt: String) -> some View {
        Text(txt)
            .foregroundColor(.white.opacity(0.65))
    }
    
    var ProductLoadError: some View {
        Text("Ah dang there was an error loading subscription information from the AppStore. Please try again later :(")
            .foregroundColor(.white)
    }
    
    var SaveText: Text {
        Text("Save 14%")
            .font(.callout)
            .italic()
            .foregroundColor(DamusColors.green)
    }
     
    func subscribe(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(.verified(let tx)):
            print("success \(tx.debugDescription)")
        case .success(.unverified(let tx, let res)):
            print("success unverified \(tx.debugDescription) \(res.localizedDescription)")
        case .pending:
            break
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }
    
    var product: Product? {
        return self.products.products?.filter({
            prod in prod.id == selection.rawValue
        }).first
    }
    
    func price_description(product: Product) -> Text {
        if product.id == "purpleyearly" {
            return (
                Text("Anually") +
                Text(verbatim: " ") +
                Text(verbatim: non_discounted_price(product)).strikethrough().foregroundColor(DamusColors.lightGrey) +
                Text(verbatim: " ") +
                Text(verbatim: product.displayPrice).fontWeight(.bold)
            )
        } else {
            return (
                Text("Monthly") +
                Text(verbatim: " ") +
                Text(verbatim: product.displayPrice).fontWeight(.bold))
        }
    }
    
    func ProductsView(_ products: [Product]) -> some View {
        VStack {
            Text("Save 20% off on an annual subscription")
                .font(.callout.bold())
                .foregroundColor(.white)
            ForEach(products) { product in
                
                Button(action: {
                    Task { @MainActor in
                        do {
                            try await subscribe(product)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }, label: {
                    price_description(product: product)
                })
                .buttonStyle(GradientButtonStyle())
            }
        }
    }
    
    func PurchasedView(_ purchased: PurchasedProduct) -> some View {
        VStack(spacing: 10) {
            Text("Purchased!")
                .font(.title2)
                .foregroundColor(.white)
            price_description(product: purchased.product)
                .foregroundColor(.white)
                .opacity(0.65)
            Text("Purchased on")
                .font(.title2)
                .foregroundColor(.white)
            Text(format_date(Int64(purchased.tx.purchaseDate.timeIntervalSince1970)))
                .foregroundColor(.white)
                .opacity(0.65)
            if let expiry = purchased.tx.expirationDate {
                Text("Renews on")
                    .font(.title2)
                    .foregroundColor(.white)
                Text(format_date(Int64(expiry.timeIntervalSince1970)))
                    .foregroundColor(.white)
                    .opacity(0.65)
            }
        }
    }
    
    var ProductStateView: some View {
        Group {
            switch self.products {
            case .failed:
                ProductLoadError
            case .loaded(let products):
                if let purchased {
                    PurchasedView(purchased)
                } else {
                    ProductsView(products)
                }
            case .loading:
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }
    
    var MainContent: some View {
        VStack {
            HStack {
                Image("logo-nobg")
                    .resizable()
                    .frame(width: 80, height: 80)
                
                Text("Purple")
                    .font(.system(size: 60.0).weight(.bold))
                    .foregroundColor(.white)
            }
            .offset(x: -12)
            
            Text("Subscription")
                .font(.title3)
                .foregroundColor(.white)
                .offset(y: -18)
            
            VStack(alignment: .leading, spacing: 30) {
                HStack(spacing: 20) {
                    Icon("digital-nomad")
                    
                    VStack(alignment: .leading) {
                        Title("Help Build The Future")
                        
                        Subtitle("Support damus development and help build the future of decentralized communication on the web.")
                    }
                }
                
                HStack(spacing: 20) {
                    Icon("special-features")
                    
                    VStack(alignment: .leading) {
                        Title("Early Access")
                        
                        Subtitle("Get access to new features before anyone else: bookmark folders, multi-account, and more!")
                    }
                }
                
                HStack(spacing: 20) {
                    Icon("undercover")
                    
                    VStack(alignment: .leading) {
                        Title("Member Rewards")
                        
                        Subtitle("Access to member-exclusive badges, private relays, and more!")
                    }
                }
                
            }
            .padding([.trailing, .leading], 30)
            
            VStack(alignment: .center) {
                ProductStateView
            }
            .padding([.top], 20)

            
            Spacer()
        }
    }
}

struct DamusPurpleView_Previews: PreviewProvider {
    static var previews: some View {
        /*
        DamusPurpleView(products: [
            DamusProduct(name: "Yearly", id: "purpleyearly", price: Decimal(69.99)),
            DamusProduct(name: "Monthly", id: "purple", price: Decimal(6.99)),
        ])
         */
        
        DamusPurpleView()
    }
}
