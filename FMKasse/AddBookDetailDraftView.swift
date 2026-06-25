import Foundation
import SwiftUI

struct AddBookDetailDraftView: View {
    let contract: Contract
    let machineId: Int64
    @Binding var draftDetails: [BookDetailDraft]
    var onCancel: () -> Void
    var onTransactionComplete: (() -> Void)? = nil

    @State private var articleGroups: [ArticleGroup] = []
    @State private var selectedGroup: ArticleGroup? = nil
    @State private var articles: [Article] = []
    @State private var isLoadingGroups = true
    @State private var isLoadingArticles = false
    @State private var error: String? = nil
    @State private var selectedArticle: Article? = nil
    @State private var isTransactionLoading = false
    @State private var transactionError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if isLoadingGroups {
                ProgressView("Lade Artikelgruppen...")
                    .font(Equans.Fonts.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                Text("Fehler: \(error)")
                    .foregroundColor(Equans.Colors.danger)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 1. ArticleGroup-Kacheln oben
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(articleGroups, id: \.id) { group in
                            ArticleGroupCard(group: group, isSelected: group.id == selectedGroup?.id) {
                                self.selectedGroup = group
                                loadArticles()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                Divider().padding(.vertical, 4)
                // 2. Artikelliste alphabetisch
                List(articles.sorted { ($0.articletitle ?? "") < ($1.articletitle ?? "") }, id: \.id) { article in
                    Button(action: { selectedArticle = article }) {
                        HStack {
                            Text(article.articletitle ?? "-")
                                .font(Equans.Fonts.body)
                                .foregroundColor(Equans.Colors.textPrimary)
                            Spacer()
                            if let rate = article.articlerate {
                                Text(String(format: "%.2f CHF", rate))
                                    .font(Equans.Fonts.roboto(13, weight: .bold))
                                    .foregroundColor(Equans.Colors.darkGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Equans.Colors.surface)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            Spacer()
            // 3. Abbrechen-Button unten
            HStack {
                Button(action: { onCancel() }) {
                    Label("Abbrechen", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(Equans.Colors.textSecondary)
            }
            .padding(.bottom, 8)
            Button(action: {
                completeTransaction()
            }) {
                Label("Transaktion abschliessen", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .tint(Equans.Colors.darkGreen)
            .padding(.bottom, 24)
            .disabled(isTransactionLoading)
            .alert(isPresented: .init(get: { transactionError != nil }, set: { _ in transactionError = nil })) {
                Alert(title: Text("Fehler"), message: Text(transactionError ?? ""), dismissButton: .default(Text("OK")))
            }
        }
        .background(Equans.Colors.background.ignoresSafeArea())
        .onAppear(perform: loadArticleGroups)
        .sheet(item: $selectedArticle) { article in
            EditBookDetailDraftView(
                article: article,
                amount: "1",
                price: String(format: "%.2f", article.articlerate ?? 0),
                description: "",
                onSave: { amount, price, description in
                    let newDetail = BookDetailDraft(
                        fk_article: article.id,
                        articletitle: article.articletitle,
                        bookdetaildescr: description.isEmpty ? nil : description,
                        booknbrsarticle: amount,
                        bookdetailprice: price
                    )
                    draftDetails.append(newDetail)
                    selectedArticle = nil
                },
                onCancel: { selectedArticle = nil }
            )
        }
    }

    private func loadArticleGroups() {
        isLoadingGroups = true
        error = nil
        SupabaseManager.shared.fetchArticleGroups { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let groups):
                    let filteredGroups = groups.filter { $0.fk_contract == contract.id }
                    self.articleGroups = filteredGroups
                    self.selectedGroup = filteredGroups.first
                    self.isLoadingGroups = false
                    self.loadArticles()
                case .failure(let err):
                    self.error = err.localizedDescription
                    self.isLoadingGroups = false
                }
            }
        }
    }

    private func loadArticles() {
        guard let group = selectedGroup else {
            self.articles = []
            return
        }
        isLoadingArticles = true
        SupabaseManager.shared.fetchArticles(forGroup: group.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let articles):
                    self.articles = articles
                case .failure(let err):
                    self.articles = []
                    self.error = err.localizedDescription
                }
                self.isLoadingArticles = false
            }
        }
    }

    private func completeTransaction() {
        guard !isTransactionLoading else { return }
        isTransactionLoading = true
        transactionError = nil
        SupabaseManager.shared.insertBookJournal(
            fk_contract: contract.id,
            fk_machine: machineId,
            bookreference1: nil,
            bookreference2: nil
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newJournal):
                    let group = DispatchGroup()
                    var errorOccurred = false
                    for detail in draftDetails {
                        group.enter()
                        SupabaseManager.shared.insertBookDetail(
                            fk_bookjournal: newJournal.id,
                            fk_machine: machineId,
                            fk_article: detail.fk_article,
                            booknbrsarticle: detail.booknbrsarticle,
                            bookdetaildescr: detail.bookdetaildescr
                        ) { detailResult in
                            if case .failure = detailResult {
                                errorOccurred = true
                            }
                            group.leave()
                        }
                    }
                    group.notify(queue: DispatchQueue.main) {
                        isTransactionLoading = false
                        if !errorOccurred {
                            onTransactionComplete?()
                        } else {
                            transactionError = "Mindestens eine Position konnte nicht gespeichert werden."
                        }
                    }
                case .failure(let error):
                    isTransactionLoading = false
                    transactionError = error.localizedDescription
                }
            }
        }
    }
/*
        SupabaseManager.shared.insertBookJournal(
            fk_contract: contract.id,
            fk_machine: machineId,
            bookreference1: nil,
            bookreference2: nil
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newJournal):
                    let group = DispatchGroup()
                    var errorOccurred = false
                    for detail in draftDetails {
                        group.enter()
                        SupabaseManager.shared.insertBookDetail(
                            fk_bookjournal: newJournal.id,
                            fk_machine: machineId,
                            fk_article: detail.fk_article,
                            booknbrsarticle: detail.booknbrsarticle,
                            bookdetaildescr: detail.bookdetaildescr
                        ) { detailResult in
                            if case .failure(_) = detailResult { errorOccurred = true }
                            group.leave()
                        }
                    }
                    group.notify(queue: DispatchQueue.main) {
                        isTransactionLoading = false
                        if !errorOccurred {
                            onTransactionComplete?()
                        } else {
                            transactionError = "Mindestens eine Position konnte nicht gespeichert werden."
                        }
                    }
                case .failure(let error):
                    isTransactionLoading = false
                    transactionError = error.localizedDescription
                }
            }
        }
*/

}

// --- Zusätzliche View für die Artikelgruppen-Karten ---
struct ArticleGroupCard: View {
    let group: ArticleGroup
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack {
                Text(group.groupname ?? "-")
                    .font(Equans.Fonts.roboto(15, weight: .medium))
                    .foregroundColor(isSelected ? .white : Equans.Colors.textPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(isSelected ? Equans.Colors.darkBlue : Equans.Colors.surface)
            .cornerRadius(Equans.Layout.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Equans.Layout.cardRadius)
                    .stroke(isSelected ? Equans.Colors.darkBlue : Equans.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
