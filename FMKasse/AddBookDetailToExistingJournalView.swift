import SwiftUI

struct AddBookDetailToExistingJournalView: View {
    let journalId: Int64
    let contractId: Int64
    let machineId: Int64
    var onComplete: () -> Void
    var onCancel: () -> Void
    
    @State private var articleGroups: [ArticleGroup] = []
    @State private var selectedGroup: ArticleGroup? = nil
    @State private var articles: [Article] = []
    @State private var isLoadingGroups = true
    @State private var isLoadingArticles = false
    @State private var error: String? = nil
    @State private var selectedArticle: Article? = nil
    @State private var isSaving = false
    @State private var saveError: String? = nil
    
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
                // Artikelgruppen-Kacheln
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
                
                // Artikelliste
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
            
            // Abbrechen-Button
            HStack {
                Button(action: { onCancel() }) {
                    Label("Abbrechen", systemImage: "xmark")
                        .font(Equans.Fonts.roboto(15, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(Equans.Colors.textSecondary)
            }
            .padding(.bottom, 24)
            .alert(isPresented: .init(get: { saveError != nil }, set: { _ in saveError = nil })) {
                Alert(title: Text("Fehler"), message: Text(saveError ?? ""), dismissButton: .default(Text("OK")))
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
                    saveBookDetail(article: article, amount: amount, description: description)
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
                    let filteredGroups = groups.filter { $0.fk_contract == contractId }
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
        SupabaseManager.shared.fetchArticles { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let articles):
                    self.articles = articles.filter { $0.fk_articlegroup == group.id }
                case .failure(let err):
                    self.articles = []
                    self.error = err.localizedDescription
                }
                self.isLoadingArticles = false
            }
        }
    }
    
    private func saveBookDetail(article: Article, amount: Double, description: String) {
        guard !isSaving else { return }
        isSaving = true
        saveError = nil
        
        SupabaseManager.shared.insertBookDetail(
            fk_bookjournal: journalId,
            fk_machine: machineId,
            fk_article: article.id,
            booknbrsarticle: amount,
            bookdetaildescr: description.isEmpty ? nil : description
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    onComplete()
                case .failure(let error):
                    saveError = error.localizedDescription
                }
            }
        }
    }
}
