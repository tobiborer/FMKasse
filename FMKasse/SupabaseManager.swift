import Foundation
import Supabase

// MARK: - Datenmodelle

struct Article: Codable, Identifiable {
    let id: Int64
    let created_at: String
    let fk_articlegroup: Int64?
    let articletitle: String?
    let articledescr: String?
    let articleunit: String?
    let articlerate: Double?
    let articletax: Double?
}

struct ArticleGroup: Codable, Identifiable {
    let id: Int64
    let groupname: String?
    let fk_contract: Int64?
}

struct Contract: Codable, Identifiable, Hashable {
    let id: Int64
    let created_at: String
    let clientname: String?
    let contractname: String?
    let contractdate: String?
    let contractvalid: String?
    let contractlogo: String?
    let contractreference_1: String?
    let contractreference_2: String?
    let contractreference_3: String?
    let contractreference_4: String?
    let contractclientno: String?
    let contractshortname: String?
    let contractclientdep: String?
    let contractclientadress_1: String?
    let contractclientadress_2: String?
    let contractclientadress_zip: String?
    let contractclientadress_city: String?
    let contractclienttaxid: String?
    let contractstandardcostcenter: String?
    let needobjectdefinition: Bool?
    let needplanonrderdefinition: Bool?
    let contractplanonref: String?
    let contractplanonreference_syscode: String?
    let contractsapobjectlink: String?
    let contractowner: String?

    enum CodingKeys: String, CodingKey {
        case id, created_at, clientname, contractname, contractdate, contractvalid, contractlogo, contractreference_1, contractreference_2, contractreference_3, contractreference_4, contractclientno, contractshortname, contractclientdep, contractclientadress_1, contractclientadress_2, contractclientadress_zip, contractclientadress_city, contractclienttaxid, contractstandardcostcenter, needobjectdefinition, needplanonrderdefinition, contractplanonref, contractplanonreference_syscode, contractsapobjectlink, contractowner
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        created_at = try container.decode(String.self, forKey: .created_at)
        clientname = try? container.decode(String.self, forKey: .clientname)
        contractname = try? container.decode(String.self, forKey: .contractname)
        contractdate = try? container.decode(String.self, forKey: .contractdate)
        if let str = try? container.decode(String.self, forKey: .contractvalid) {
            contractvalid = str
        } else if let bool = try? container.decode(Bool.self, forKey: .contractvalid) {
            contractvalid = bool ? "true" : "false"
        } else {
            contractvalid = nil
        }
        contractlogo = try? container.decode(String.self, forKey: .contractlogo)
        contractreference_1 = try? container.decode(String.self, forKey: .contractreference_1)
        contractreference_2 = try? container.decode(String.self, forKey: .contractreference_2)
        contractreference_3 = try? container.decode(String.self, forKey: .contractreference_3)
        contractreference_4 = try? container.decode(String.self, forKey: .contractreference_4)
        contractclientno = try? container.decode(String.self, forKey: .contractclientno)
        contractshortname = try? container.decode(String.self, forKey: .contractshortname)
        contractclientdep = try? container.decode(String.self, forKey: .contractclientdep)
        contractclientadress_1 = try? container.decode(String.self, forKey: .contractclientadress_1)
        contractclientadress_2 = try? container.decode(String.self, forKey: .contractclientadress_2)
        contractclientadress_zip = try? container.decode(String.self, forKey: .contractclientadress_zip)
        contractclientadress_city = try? container.decode(String.self, forKey: .contractclientadress_city)
        contractclienttaxid = try? container.decode(String.self, forKey: .contractclienttaxid)
        contractstandardcostcenter = try? container.decode(String.self, forKey: .contractstandardcostcenter)
        needobjectdefinition = try? container.decode(Bool.self, forKey: .needobjectdefinition)
        needplanonrderdefinition = try? container.decode(Bool.self, forKey: .needplanonrderdefinition)
        contractplanonref = try? container.decode(String.self, forKey: .contractplanonref)
        contractplanonreference_syscode = try? container.decode(String.self, forKey: .contractplanonreference_syscode)
        contractsapobjectlink = try? container.decode(String.self, forKey: .contractsapobjectlink)
        contractowner = try? container.decode(String.self, forKey: .contractowner)
    }

    init(
        id: Int64,
        created_at: String,
        clientname: String? = nil,
        contractname: String? = nil,
        contractdate: String? = nil,
        contractvalid: String? = nil,
        contractlogo: String? = nil,
        contractreference_1: String? = nil,
        contractreference_2: String? = nil,
        contractreference_3: String? = nil,
        contractreference_4: String? = nil,
        contractclientno: String? = nil,
        contractshortname: String? = nil,
        contractclientdep: String? = nil,
        contractclientadress_1: String? = nil,
        contractclientadress_2: String? = nil,
        contractclientadress_zip: String? = nil,
        contractclientadress_city: String? = nil,
        contractclienttaxid: String? = nil,
        contractstandardcostcenter: String? = nil,
        needobjectdefinition: Bool? = nil,
        needplanonrderdefinition: Bool? = nil,
        contractplanonref: String? = nil,
        contractplanonreference_syscode: String? = nil,
        contractsapobjectlink: String? = nil,
        contractowner: String? = nil
    ) {
        self.id = id
        self.created_at = created_at
        self.clientname = clientname
        self.contractname = contractname
        self.contractdate = contractdate
        self.contractvalid = contractvalid
        self.contractlogo = contractlogo
        self.contractreference_1 = contractreference_1
        self.contractreference_2 = contractreference_2
        self.contractreference_3 = contractreference_3
        self.contractreference_4 = contractreference_4
        self.contractclientno = contractclientno
        self.contractshortname = contractshortname
        self.contractclientdep = contractclientdep
        self.contractclientadress_1 = contractclientadress_1
        self.contractclientadress_2 = contractclientadress_2
        self.contractclientadress_zip = contractclientadress_zip
        self.contractclientadress_city = contractclientadress_city
        self.contractclienttaxid = contractclienttaxid
        self.contractstandardcostcenter = contractstandardcostcenter
        self.needobjectdefinition = needobjectdefinition
        self.needplanonrderdefinition = needplanonrderdefinition
        self.contractplanonref = contractplanonref
        self.contractplanonreference_syscode = contractplanonreference_syscode
        self.contractsapobjectlink = contractsapobjectlink
        self.contractowner = contractowner
    }
}

struct Machine: Codable, Identifiable, Hashable {
    let id: Int64
    let machinename: String?
    let machinelocation: String?
}

struct MachineConfig: Codable, Identifiable {
    let id: Int64
    let fk_machine: Int64?
    let fk_articlegroup: Int64?
}

struct BookDetail: Codable, Identifiable {
    let id: Int64
    let fk_bookjournal: Int64?
    let fk_machine: Int64?
    let fk_article: Int64?
    let booknbrsarticle: Double?
    let bookdetaildescr: String?
}

struct BookJournal: Codable, Identifiable {
    let id: Int64
    let created_at: String
    let fk_machine: Int64?
    let fk_contract: Int64?
    let bookreference1: String?
    let bookreference2: String?
    let fk_objectorigin: Int64?
    let fk_objectdestination: Int64?
    let fk_order: Int64?

    enum CodingKeys: String, CodingKey {
        case id, created_at, fk_machine, fk_contract, bookreference1, bookreference2, fk_objectorigin, fk_objectdestination, fk_order
    }

    init(
        id: Int64,
        created_at: String,
        fk_machine: Int64? = nil,
        fk_contract: Int64? = nil,
        bookreference1: String? = nil,
        bookreference2: String? = nil,
        fk_objectorigin: Int64? = nil,
        fk_objectdestination: Int64? = nil,
        fk_order: Int64? = nil
    ) {
        self.id = id
        self.created_at = created_at
        self.fk_machine = fk_machine
        self.fk_contract = fk_contract
        self.bookreference1 = bookreference1
        self.bookreference2 = bookreference2
        self.fk_objectorigin = fk_objectorigin
        self.fk_objectdestination = fk_objectdestination
        self.fk_order = fk_order
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int64.self, forKey: .id)
        created_at = try c.decode(String.self, forKey: .created_at)
        fk_machine = try? c.decodeIfPresent(Int64.self, forKey: .fk_machine)
        fk_contract = try? c.decodeIfPresent(Int64.self, forKey: .fk_contract)
        bookreference1 = try? c.decodeIfPresent(String.self, forKey: .bookreference1)
        bookreference2 = try? c.decodeIfPresent(String.self, forKey: .bookreference2)
        fk_objectorigin = BookJournal.decodeInt64Flexible(from: c, forKey: .fk_objectorigin)
        fk_objectdestination = BookJournal.decodeInt64Flexible(from: c, forKey: .fk_objectdestination)
        fk_order = BookJournal.decodeInt64Flexible(from: c, forKey: .fk_order)
    }

    static func decodeInt64Flexible(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int64? {
        if let intVal = try? container.decodeIfPresent(Int64.self, forKey: key) {
            return intVal
        }
        if let strVal = try? container.decodeIfPresent(String.self, forKey: key), let intVal = Int64(strVal) {
            return intVal
        }
        return nil
    }
}

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    
    init(from authUser: Auth.User) {
        self.id = authUser.id.uuidString
        self.email = authUser.email
    }
}

struct BookDetailInsert: Encodable {
    let fk_bookjournal: Int64
    let fk_machine: Int64?
    let fk_article: Int64?
    let booknbrsarticle: Double?
    let bookdetaildescr: String?
}

struct BookJournalInsert: Codable {
    let fk_contract: Int64
    let fk_machine: Int64?
    let bookreference1: String?
    let bookreference2: String?
    let fk_objectorigin: Int64?
    let fk_objectdestination: Int64?
    let fk_order: Int64?
}

// MARK: - SupabaseManager
class SupabaseManager {
    static let shared = SupabaseManager()
    private let supabaseUrl = "https://fpuhsrwfhaekvviuqpcx.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwdWhzcndmaGFla3Z2aXVxcGN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDM2MTAsImV4cCI6MjA2NzYxOTYxMH0.FSh949kAz6cymwAZ3zcNXfmcYbfK5iG1wRnq_uEvBIs"
    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(supabaseURL: URL(string: supabaseUrl)!, supabaseKey: supabaseKey)
    }

    // MARK: - Auth
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                let session = try await client.auth.signIn(email: email, password: password)
                let user = User(from: session.user)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await client.auth.signOut()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func getCurrentUser() -> User? {
        guard let authUser = client.auth.currentUser else { return nil }
        return User(from: authUser)
    }

    /// Startet den Azure-AD (Microsoft Entra ID) OAuth-Login.
    /// Öffnet ein sicheres Web-Auth-Fenster und kehrt per Deep Link zurück.
    @MainActor
    func signInWithAzure() async throws {
        try await client.auth.signInWithOAuth(
            provider: .azure,
            redirectTo: AuthConfig.redirectURL,
            scopes: "openid email profile"
        )
    }

    /// Verarbeitet den OAuth-Rücksprung (Deep Link) und setzt die Session.
    func handleOAuthCallback(url: URL) async throws {
        try await client.auth.session(from: url)
    }

    /// Versendet eine Datei (PDF oder Export) über die Supabase Edge Function "send-invoice".
    /// Die Datei wird base64-kodiert übertragen; der Mailversand läuft im Backend (Resend).
    func sendInvoiceEmail(
        to recipient: String,
        subject: String,
        body: String,
        pdfData: Data,
        fileName: String
    ) async throws {
        struct Payload: Encodable {
            let to: String
            let subject: String
            let body: String
            let fileName: String
            let pdfBase64: String
        }
        struct FunctionResponse: Decodable {
            let success: Bool
            let error: String?
        }
        let payload = Payload(
            to: recipient,
            subject: subject,
            body: body,
            fileName: fileName,
            pdfBase64: pdfData.base64EncodedString()
        )
        let response: FunctionResponse = try await client.functions.invoke(
            "send-invoice",
            options: FunctionInvokeOptions(body: payload)
        )
        if !response.success {
            throw NSError(
                domain: "FMKasse.sendInvoiceEmail",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: response.error ?? "Unbekannter Fehler beim Mailversand."]
            )
        }
    }

    // MARK: - Fetch Methods
    func fetchMachines(completion: @escaping (Result<[Machine], Error>) -> Void) {
        Task {
            do {
                let machines: [Machine] = try await client.from("machine").select().execute().value
                completion(.success(machines))
            } catch {
                completion(.failure(error))
            }
        }
    }
    func fetchArticles(completion: @escaping (Result<[Article], Error>) -> Void) {
        Task {
            do {
                let articles: [Article] = try await client.from("article").select().execute().value
                completion(.success(articles))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchArticles(forGroup groupId: Int64, completion: @escaping (Result<[Article], Error>) -> Void) {
        Task {
            do {
                let articles: [Article] = try await client
                    .from("article")
                    .select()
                    .eq("fk_articlegroup", value: String(groupId))
                    .execute()
                    .value
                completion(.success(articles))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchArticleGroups(completion: @escaping (Result<[ArticleGroup], Error>) -> Void) {
        Task {
            do {
                let groups: [ArticleGroup] = try await client.from("articlegroup").select().execute().value
                completion(.success(groups))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchBookDetails(completion: @escaping (Result<[BookDetail], Error>) -> Void) {
        Task {
            do {
                let details: [BookDetail] = try await client.from("bookdetail").select().execute().value
                completion(.success(details))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchBookJournals(completion: @escaping (Result<[BookJournal], Error>) -> Void) {
        Task {
            do {
                let journals: [BookJournal] = try await client.from("bookjournal").select().execute().value
                completion(.success(journals))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchBookJournalAggs(completion: @escaping (Result<[BookJournalAgg], Error>) -> Void) {
        Task {
            do {
                let aggs: [BookJournalAgg] = try await client.from("v_bookjournal_agg").select().execute().value
                completion(.success(aggs))
            } catch {
                print("[DEBUG] Fehler beim Laden der BookJournal-Aggregate:", error)
                completion(.failure(error))
            }
        }
    }

    func fetchBookJournals(forMachineId machineId: Int64, completion: @escaping (Result<[BookJournal], Error>) -> Void) {
        Task {
            do {
                let journals: [BookJournal] = try await client
                    .from("bookjournal")
                    .select()
                    .eq("fk_machine", value: String(machineId))
                    .execute()
                    .value
                completion(.success(journals))
            } catch {
                print("[DEBUG] Fehler beim Laden der BookJournals für MachineId \(machineId):", error)
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("[DEBUG] Type mismatch:", type, context)
                    case .valueNotFound(let type, let context):
                        print("[DEBUG] Value not found:", type, context)
                    case .keyNotFound(let key, let context):
                        print("[DEBUG] Key not found:", key, context)
                    case .dataCorrupted(let context):
                        print("[DEBUG] Data corrupted:", context)
                    @unknown default:
                        print("[DEBUG] Unknown decoding error")
                    }
                }
                completion(.failure(error))
            }
        }
    }

    func fetchContracts(completion: @escaping (Result<[Contract], Error>) -> Void) {
        Task {
            do {
                let contracts: [Contract] = try await client.from("contract").select().execute().value
                completion(.success(contracts))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchMachineConfigs(completion: @escaping (Result<[MachineConfig], Error>) -> Void) {
        Task {
            do {
                let configs: [MachineConfig] = try await client.from("machineconfig").select().execute().value
                completion(.success(configs))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Insert Methods
    func insertBookDetail(
        fk_bookjournal: Int64,
        fk_machine: Int64?,
        fk_article: Int64?,
        booknbrsarticle: Double?,
        bookdetaildescr: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                let insertPayload = BookDetailInsert(
                    fk_bookjournal: fk_bookjournal,
                    fk_machine: fk_machine,
                    fk_article: fk_article,
                    booknbrsarticle: booknbrsarticle,
                    bookdetaildescr: bookdetaildescr
                )
                let _ = try await client
                    .from("bookdetail")
                    .insert(insertPayload)
                    .execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func insertBookJournal(
        fk_contract: Int64,
        fk_machine: Int64? = nil,
        bookreference1: String? = nil,
        bookreference2: String? = nil,
        fk_objectorigin: Int64? = nil,
        fk_objectdestination: Int64? = nil,
        fk_order: Int64? = nil,
        completion: @escaping (Result<BookJournal, Error>) -> Void
    ) {
        let newJournal = BookJournalInsert(
            fk_contract: fk_contract,
            fk_machine: fk_machine,
            bookreference1: bookreference1,
            bookreference2: bookreference2,
            fk_objectorigin: fk_objectorigin,
            fk_objectdestination: fk_objectdestination,
            fk_order: fk_order
        )
        Task {
            do {
                let inserted: [BookJournal] = try await client.from("bookjournal").insert(newJournal).select().execute().value
                if let first = inserted.first {
                    completion(.success(first))
                } else {
                    completion(.failure(NSError(domain: "Supabase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kein BookJournal zurückgegeben"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete Methods
    func deleteBookJournal(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("bookjournal").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteBookDetails(forJournalId journalId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("bookdetail").delete().eq("fk_bookjournal", value: String(journalId)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteBookDetail(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("bookdetail").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateBookDetail(
        id: Int64,
        booknbrsarticle: Double?,
        bookdetaildescr: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let updatePayload = BookDetailUpdate(
            booknbrsarticle: booknbrsarticle,
            bookdetaildescr: bookdetaildescr
        )
        Task {
            do {
                _ = try await client.from("bookdetail").update(updatePayload).eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Article CRUD
    func insertArticle(
        fk_articlegroup: Int64,
        articletitle: String?,
        articledescr: String?,
        articleunit: String?,
        articlerate: Double?,
        articletax: Double?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload = ArticleInsert(
            fk_articlegroup: fk_articlegroup,
            articletitle: articletitle,
            articledescr: articledescr,
            articleunit: articleunit,
            articlerate: articlerate,
            articletax: articletax
        )
        Task {
            do {
                _ = try await client.from("article").insert(payload).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateArticle(
        id: Int64,
        articletitle: String?,
        articledescr: String?,
        articleunit: String?,
        articlerate: Double?,
        articletax: Double?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload = ArticleUpdate(
            articletitle: articletitle,
            articledescr: articledescr,
            articleunit: articleunit,
            articlerate: articlerate,
            articletax: articletax
        )
        Task {
            do {
                _ = try await client.from("article").update(payload).eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteArticle(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("article").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - ArticleGroup CRUD
    func insertArticleGroup(
        fk_contract: Int64,
        groupname: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload = ArticleGroupInsert(groupname: groupname, fk_contract: fk_contract)
        Task {
            do {
                _ = try await client.from("articlegroup").insert(payload).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateArticleGroup(
        id: Int64,
        groupname: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload = ArticleGroupUpdate(groupname: groupname)
        Task {
            do {
                _ = try await client.from("articlegroup").update(payload).eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteArticleGroup(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("articlegroup").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Contract CRUD
    func insertContract(
        clientname: String?,
        contractname: String?,
        completion: @escaping (Result<Contract, Error>) -> Void
    ) {
        let payload = ContractInsert(clientname: clientname, contractname: contractname)
        Task {
            do {
                let inserted: [Contract] = try await client.from("contract").insert(payload).select().execute().value
                if let first = inserted.first {
                    completion(.success(first))
                } else {
                    completion(.failure(NSError(domain: "Supabase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kein Contract zurückgegeben"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateContract(
        id: Int64,
        fields: ContractUpdate,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                _ = try await client.from("contract").update(fields).eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteContract(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("contract").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Löscht einen Vertrag samt zugehöriger Artikelstruktur (Artikelgruppen, Artikel,
    /// machineconfig-Zuordnungen). Bricht mit einer klaren Meldung ab, wenn der Vertrag
    /// bereits Buchungen hat – so wird keine Buchungshistorie zerstört.
    func deleteContractCascade(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        struct IdRow: Decodable { let id: Int64 }
        Task {
            do {
                // 1. Schutz: keine Löschung, wenn Buchungen auf den Vertrag verweisen.
                let journals: [IdRow] = try await client
                    .from("bookjournal")
                    .select("id")
                    .eq("fk_contract", value: String(id))
                    .limit(1)
                    .execute()
                    .value
                if !journals.isEmpty {
                    throw NSError(domain: "FMKasse", code: 409, userInfo: [NSLocalizedDescriptionKey:
                        "Dieser Vertrag hat bereits Buchungen und kann nicht gelöscht werden."])
                }

                // 2. Artikelgruppen des Vertrags ermitteln.
                let groups: [IdRow] = try await client
                    .from("articlegroup")
                    .select("id")
                    .eq("fk_contract", value: String(id))
                    .execute()
                    .value
                let groupIds = groups.map { String($0.id) }

                // 3. Abhängige Datensätze der Artikelgruppen entfernen.
                if !groupIds.isEmpty {
                    _ = try await client.from("machineconfig").delete().in("fk_articlegroup", values: groupIds).execute()
                    _ = try await client.from("article").delete().in("fk_articlegroup", values: groupIds).execute()
                    _ = try await client.from("articlegroup").delete().eq("fk_contract", value: String(id)).execute()
                }

                // 4. Vertrag löschen.
                _ = try await client.from("contract").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Contract Copy

    func fetchArticleGroups(forContract contractId: Int64, completion: @escaping (Result<[ArticleGroup], Error>) -> Void) {
        Task {
            do {
                let groups: [ArticleGroup] = try await client
                    .from("articlegroup")
                    .select()
                    .eq("fk_contract", value: String(contractId))
                    .execute()
                    .value
                completion(.success(groups))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func copyContract(source: Contract, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                // 1. Neuen Vertrag anlegen
                let newContract: [Contract] = try await client
                    .from("contract")
                    .insert(ContractFullInsert(from: source))
                    .select()
                    .execute()
                    .value
                guard let newContractId = newContract.first?.id else {
                    throw NSError(domain: "Copy", code: 0, userInfo: [NSLocalizedDescriptionKey: "Neuer Vertrag wurde nicht zurückgegeben"])
                }

                // 2. Artikelgruppen des Originals laden
                let groups: [ArticleGroup] = try await client
                    .from("articlegroup")
                    .select()
                    .eq("fk_contract", value: String(source.id))
                    .execute()
                    .value

                // 3. Jede Gruppe + Artikel kopieren
                for group in groups {
                    let newGroups: [ArticleGroup] = try await client
                        .from("articlegroup")
                        .insert(ArticleGroupInsert(groupname: group.groupname, fk_contract: newContractId))
                        .select()
                        .execute()
                        .value
                    guard let newGroupId = newGroups.first?.id else { continue }

                    let articles: [Article] = try await client
                        .from("article")
                        .select()
                        .eq("fk_articlegroup", value: String(group.id))
                        .execute()
                        .value

                    for article in articles {
                        _ = try await client
                            .from("article")
                            .insert(ArticleInsert(
                                fk_articlegroup: newGroupId,
                                articletitle: article.articletitle,
                                articledescr: article.articledescr,
                                articleunit: article.articleunit,
                                articlerate: article.articlerate,
                                articletax: article.articletax
                            ))
                            .execute()
                    }
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func copyArticleGroups(groupIds: [Int64], toContractId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                for groupId in groupIds {
                    let groups: [ArticleGroup] = try await client
                        .from("articlegroup").select().eq("id", value: String(groupId)).execute().value
                    guard let sourceGroup = groups.first else { continue }

                    let newGroups: [ArticleGroup] = try await client
                        .from("articlegroup")
                        .insert(ArticleGroupInsert(groupname: sourceGroup.groupname, fk_contract: toContractId))
                        .select().execute().value
                    guard let newGroupId = newGroups.first?.id else { continue }

                    let articles: [Article] = try await client
                        .from("article").select().eq("fk_articlegroup", value: String(groupId)).execute().value
                    for article in articles {
                        _ = try await client.from("article").insert(ArticleInsert(
                            fk_articlegroup: newGroupId,
                            articletitle: article.articletitle,
                            articledescr: article.articledescr,
                            articleunit: article.articleunit,
                            articlerate: article.articlerate,
                            articletax: article.articletax
                        )).execute()
                    }
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - UserProfile Methods

    func fetchUserProfile(userId: String, completion: @escaping (Result<AppUser?, Error>) -> Void) {
        Task {
            do {
                let users: [AppUser] = try await client
                    .from("userprofile")
                    .select()
                    .eq("id", value: userId)
                    .execute()
                    .value
                completion(.success(users.first))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchAllUserProfiles(completion: @escaping (Result<[AppUser], Error>) -> Void) {
        Task {
            do {
                let users: [AppUser] = try await client
                    .from("userprofile")
                    .select()
                    .order("email")
                    .execute()
                    .value
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func insertUserProfile(userId: String, email: String?, displayname: String?, role: UserRole, completion: @escaping (Result<Void, Error>) -> Void) {
        let payload = AppUserInsert(id: userId, email: email, displayname: displayname, role: role.rawValue)
        Task {
            do {
                _ = try await client.from("userprofile").insert(payload).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateUserProfile(userId: String, role: UserRole, displayname: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let payload = AppUserRoleUpdate(role: role.rawValue, displayname: displayname)
        Task {
            do {
                _ = try await client.from("userprofile").update(payload).eq("id", value: userId).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func deleteUserProfile(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("userprofile").delete().eq("id", value: userId).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // Legt einen Auth-User per Admin-API an und erstellt direkt das Profil.
    // Benötigt einen Supabase Edge Function oder service_role-Key auf dem Server.
    // Fallback: Nur Profil-Vorlage in userprofile speichern (ohne gültige UUID).
    func createAuthUser(email: String, displayname: String?, role: UserRole, completion: @escaping (Result<Void, Error>) -> Void) {
        // Da der service_role Key nicht im Client verfügbar ist, rufen wir eine
        // Edge Function auf, die den User anlegt. Falls noch keine vorhanden:
        // Einfach nur das Profil mit Platzhalter anlegen — beim SSO-Login wird
        // die echte UUID zugewiesen.
        Task {
            do {
                // Versuche Edge Function "create-user" aufzurufen
                struct CreateUserPayload: Encodable {
                    let email: String
                    let displayname: String?
                    let role: String
                }
                _ = try await client.functions.invoke(
                    "create-user",
                    options: .init(body: CreateUserPayload(email: email, displayname: displayname, role: role.rawValue))
                )
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Machine Methods
    func insertMachine(
        name: String,
        location: String?,
        completion: @escaping (Result<Machine, Error>) -> Void
    ) {
        let payload = MachineInsert(
            machinename: name,
            machinelocation: location?.isEmpty == false ? location : nil
        )
        Task {
            do {
                let inserted: [Machine] = try await client.from("machine").insert(payload).select().execute().value
                if let first = inserted.first {
                    completion(.success(first))
                } else {
                    completion(.failure(NSError(domain: "Supabase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Kasse zurückgegeben"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - MachineConfig Methods
    func insertMachineConfig(
        fk_machine: Int64,
        fk_articlegroup: Int64,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload = MachineConfigInsert(fk_machine: fk_machine, fk_articlegroup: fk_articlegroup)
        Task {
            do {
                _ = try await client.from("machineconfig").insert(payload).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteMachineConfig(id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                _ = try await client.from("machineconfig").delete().eq("id", value: String(id)).execute()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

struct MachineInsert: Encodable {
    let machinename: String
    let machinelocation: String?
}

struct MachineConfigInsert: Encodable {
    let fk_machine: Int64
    let fk_articlegroup: Int64
}

struct ArticleInsert: Encodable {
    let fk_articlegroup: Int64
    let articletitle: String?
    let articledescr: String?
    let articleunit: String?
    let articlerate: Double?
    let articletax: Double?
}

struct ArticleUpdate: Encodable {
    let articletitle: String?
    let articledescr: String?
    let articleunit: String?
    let articlerate: Double?
    let articletax: Double?
}

struct ArticleGroupInsert: Encodable {
    let groupname: String?
    let fk_contract: Int64
}

struct ArticleGroupUpdate: Encodable {
    let groupname: String?
}

struct ContractInsert: Encodable {
    let clientname: String?
    let contractname: String?
}

struct ContractFullInsert: Encodable {
    let clientname: String?
    let contractname: String?
    let contractdate: String?
    let contractreference_1: String?
    let contractreference_2: String?
    let contractreference_3: String?
    let contractreference_4: String?
    let contractclientno: String?
    let contractshortname: String?
    let contractclientdep: String?
    let contractclientadress_1: String?
    let contractclientadress_2: String?
    let contractclientadress_zip: String?
    let contractclientadress_city: String?
    let contractclienttaxid: String?
    let contractstandardcostcenter: String?
    let needobjectdefinition: Bool?
    let needplanonrderdefinition: Bool?
    let contractplanonref: String?
    let contractplanonreference_syscode: String?
    let contractsapobjectlink: String?
    let contractowner: String?

    init(from c: Contract) {
        clientname = c.clientname
        contractname = (c.contractname ?? "") + " (Kopie)"
        contractdate = c.contractdate
        contractreference_1 = c.contractreference_1
        contractreference_2 = c.contractreference_2
        contractreference_3 = c.contractreference_3
        contractreference_4 = c.contractreference_4
        contractclientno = c.contractclientno
        contractshortname = c.contractshortname
        contractclientdep = c.contractclientdep
        contractclientadress_1 = c.contractclientadress_1
        contractclientadress_2 = c.contractclientadress_2
        contractclientadress_zip = c.contractclientadress_zip
        contractclientadress_city = c.contractclientadress_city
        contractclienttaxid = c.contractclienttaxid
        contractstandardcostcenter = c.contractstandardcostcenter
        needobjectdefinition = c.needobjectdefinition
        needplanonrderdefinition = c.needplanonrderdefinition
        contractplanonref = c.contractplanonref
        contractplanonreference_syscode = c.contractplanonreference_syscode
        contractsapobjectlink = c.contractsapobjectlink
        contractowner = c.contractowner
    }
}

struct ContractUpdate: Encodable {
    var clientname: String?
    var contractname: String?
    var contractreference_1: String?
    var contractreference_2: String?
    var contractclientno: String?
    var contractshortname: String?
    var contractclientdep: String?
    var contractclientadress_1: String?
    var contractclientadress_2: String?
    var contractclientadress_zip: String?
    var contractclientadress_city: String?
    var contractstandardcostcenter: String?
}

struct BookDetailUpdate: Encodable {
    let booknbrsarticle: Double?
    let bookdetaildescr: String?
}
