import SwiftUI

struct ArticleGroupDetailView: View {
    let group: ArticleGroup
    var onChange: () -> Void

    @State private var groupName: String
    @State private var isSavingName = false
    @State private var nameSaveMessage: String?

    @State private var articles: [Article] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var editingArticle: Article? = nil
    @State private var showAddArticle = false
    @State private var articleToDelete: Article? = nil
    @State private var searchText = ""

    init(group: ArticleGroup, onChange: @escaping () -> Void) {
        self.group = group
        self.onChange = onChange
        _groupName = State(initialValue: group.groupname ?? "")
    }

    // MARK: - Filtered & Grouped

    private var filteredArticles: [Article] {
        guard !searchText.isEmpty else { return articles }
        return articles.filter {
            ($0.articletitle ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.articledescr ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedArticles: [(letter: String, articles: [Article])] {
        let dict = Dictionary(grouping: filteredArticles) { article -> String in
            let first = String((article.articletitle ?? "#").prefix(1)).uppercased()
            return first.first?.isLetter == true ? first : "#"
        }
        return dict.keys.sorted().map { key in
            (letter: key, articles: dict[key]!.sorted { ($0.articletitle ?? "") < ($1.articletitle ?? "") })
        }
    }

    private var indexLetters: [String] {
        groupedArticles.map { $0.letter }
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            List {
                // Gruppenname-Sektion
                Section("Gruppenname") {
                    HStack {
                        TextField("Name", text: $groupName)
                            .font(Equans.Fonts.body)
                            .foregroundColor(Equans.Colors.textPrimary)
                        Button(action: saveName) {
                            if isSavingName {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Equans.Colors.darkGreen)
                            }
                        }
                        .disabled(isSavingName)
                    }
                    if let msg = nameSaveMessage {
                        Text(msg)
                            .font(Equans.Fonts.caption)
                            .foregroundColor(msg.hasPrefix("Fehler") ? Equans.Colors.danger : Equans.Colors.darkGreen)
                    }
                }

                // Artikel-Sektionen
                if isLoading {
                    Section {
                        ProgressView("Lade Artikel...")
                    }
                } else if let error = error {
                    Section {
                        Text("Fehler: \(error)").foregroundColor(Equans.Colors.danger)
                    }
                } else if filteredArticles.isEmpty {
                    Section {
                        Text(searchText.isEmpty ? "Keine Artikel in dieser Gruppe." : "Keine Treffer für \"\(searchText)\".")
                            .foregroundColor(Equans.Colors.textSecondary)
                            .font(Equans.Fonts.callout)
                    }
                } else {
                    ForEach(groupedArticles, id: \.letter) { section in
                        Section(header: Text(section.letter)
                            .font(Equans.Fonts.roboto(13, weight: .bold))
                            .foregroundColor(Equans.Colors.darkBlue)
                            .id(section.letter)
                        ) {
                            ForEach(section.articles) { article in
                                Button(action: { editingArticle = article }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(article.articletitle ?? "(kein Titel)")
                                                .font(Equans.Fonts.body)
                                                .foregroundColor(Equans.Colors.textPrimary)
                                            if let descr = article.articledescr, !descr.isEmpty {
                                                Text(descr)
                                                    .font(Equans.Fonts.caption)
                                                    .foregroundColor(Equans.Colors.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        if let rate = article.articlerate {
                                            Text(String(format: "%.2f CHF", rate))
                                                .font(Equans.Fonts.roboto(14, weight: .bold))
                                                .foregroundColor(Equans.Colors.darkGreen)
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        articleToDelete = article
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Equans.Colors.background.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Artikel suchen…")
            // Alphabet-Index rechts (nur ohne aktive Suche)
            .overlay(alignment: .trailing) {
                if searchText.isEmpty && !indexLetters.isEmpty {
                    AlphabetIndexView(letters: indexLetters) { letter in
                        withAnimation { proxy.scrollTo(letter, anchor: .top) }
                    }
                    .padding(.trailing, 4)
                }
            }
        }
        .navigationTitle(group.groupname ?? "Gruppe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddArticle = true }) {
                    Image(systemName: "plus")
                }
                .foregroundColor(Equans.Colors.darkBlue)
            }
        }
        .onAppear(perform: loadArticles)
        .sheet(isPresented: $showAddArticle, onDismiss: loadArticles) {
            ArticleEditView(article: nil, groupId: group.id) {
                showAddArticle = false
            } onCancel: {
                showAddArticle = false
            }
        }
        .sheet(item: $editingArticle, onDismiss: loadArticles) { article in
            ArticleEditView(article: article, groupId: group.id) {
                editingArticle = nil
            } onCancel: {
                editingArticle = nil
            }
        }
        .alert("Artikel löschen?", isPresented: Binding(
            get: { articleToDelete != nil },
            set: { if !$0 { articleToDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) { articleToDelete = nil }
            Button("Löschen", role: .destructive) {
                if let article = articleToDelete { deleteArticle(article) }
                articleToDelete = nil
            }
        } message: {
            Text("Möchten Sie diesen Artikel wirklich löschen?")
        }
    }

    // MARK: - Logic

    private func saveName() {
        isSavingName = true
        nameSaveMessage = nil
        SupabaseManager.shared.updateArticleGroup(id: group.id, groupname: groupName.nilIfEmpty) { result in
            DispatchQueue.main.async {
                isSavingName = false
                switch result {
                case .success:
                    nameSaveMessage = "Gespeichert."
                    onChange()
                case .failure(let err):
                    nameSaveMessage = "Fehler: \(err.localizedDescription)"
                }
            }
        }
    }

    private func loadArticles() {
        isLoading = true
        error = nil
        SupabaseManager.shared.fetchArticles(forGroup: group.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let articles):
                    self.articles = articles.sorted { ($0.articletitle ?? "") < ($1.articletitle ?? "") }
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }

    private func deleteArticle(_ article: Article) {
        SupabaseManager.shared.deleteArticle(id: article.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: loadArticles()
                case .failure(let err): self.error = err.localizedDescription
                }
            }
        }
    }
}

// MARK: - Alphabet Index Scrubber

private struct AlphabetIndexView: View {
    let letters: [String]
    let onSelect: (String) -> Void

    @GestureState private var dragLetter: String? = nil

    var body: some View {
        VStack(spacing: 2) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(dragLetter == letter ? .white : Equans.Colors.darkBlue)
                    .frame(width: 20, height: 20)
                    .background(dragLetter == letter ? Equans.Colors.darkBlue : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(Equans.Colors.surface.opacity(0.85))
        .cornerRadius(10)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($dragLetter) { value, state, _ in
                    let letterHeight: CGFloat = 22
                    let index = Int(value.location.y / letterHeight)
                    if index >= 0 && index < letters.count {
                        let letter = letters[index]
                        if state != letter {
                            state = letter
                            onSelect(letter)
                        }
                    }
                }
        )
        .onTapGesture { } // Verhindert, dass Taps durchfallen
    }
}
