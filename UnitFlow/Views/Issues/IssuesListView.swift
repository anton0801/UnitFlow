import SwiftUI
import WebKit

struct IssuesListView: View {
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showNewIssue = false
    @State private var filterSeverity: Issue.Severity? = nil
    @State private var filterStatus: Issue.IssueStatus? = nil
    @State private var searchText = ""
    
    var filteredIssues: [Issue] {
        var result = sitesVM.issues
        if let sev = filterSeverity { result = result.filter { $0.severity == sev } }
        if let st = filterStatus { result = result.filter { $0.status == st } }
        if !searchText.isEmpty { result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) } }
        return result.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All", isSelected: filterSeverity == nil && filterStatus == nil) {
                                filterSeverity = nil; filterStatus = nil
                            }
                            ForEach(Issue.Severity.allCases, id: \.self) { s in
                                FilterPill(title: s.rawValue, isSelected: filterSeverity == s, color: s.color) {
                                    filterSeverity = filterSeverity == s ? nil : s
                                }
                            }
                            Divider().frame(height: 20)
                            ForEach(Issue.IssueStatus.allCases, id: \.self) { s in
                                FilterPill(title: s.rawValue, isSelected: filterStatus == s, color: s.color) {
                                    filterStatus = filterStatus == s ? nil : s
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 10)
                    }
                    
                    if filteredIssues.isEmpty {
                        UFEmptyState(icon: "checkmark.shield.fill", title: "No Issues",
                                     subtitle: filterSeverity != nil || filterStatus != nil ? "No issues match your filters" : "No issues reported. That's great!",
                                     buttonTitle: filteredIssues.isEmpty && sitesVM.issues.isEmpty ? "Report Issue" : nil) {
                            showNewIssue = true
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredIssues) { issue in
                                NavigationLink {
                                    IssueDetailView(issue: issue)
                                } label: {
                                    IssueCard(issue: issue)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { sitesVM.deleteIssue(issue) } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                            Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .searchable(text: $searchText, prompt: "Search issues...")
                    }
                }
            }
            .navigationTitle("Issues")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewIssue = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(UFColors.danger)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewIssue) { NewIssueView(preselectedSiteId: sitesVM.sites.first?.id) }
    }
}

struct IssueCard: View {
    let issue: Issue
    
    var body: some View {
        UFCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: issue.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(issue.severity.color)
                        .padding(8)
                        .background(issue.severity.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(issue.title).font(UFFont.headline(14)).foregroundColor(.primary).lineLimit(1)
                        Text(issue.zone + " • " + issue.category.rawValue)
                            .font(UFFont.caption(11)).foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: issue.severity.rawValue, color: issue.severity.color, small: true)
                }
                
                Text(issue.description)
                    .font(UFFont.caption(12)).foregroundColor(.secondary).lineLimit(2)
                
                HStack {
                    StatusBadge(text: issue.status.rawValue, color: issue.status.color, small: true)
                    Spacer()
                    if !issue.assignedWorker.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill").font(.system(size: 10)).foregroundColor(.secondary)
                            Text(issue.assignedWorker).font(UFFont.caption(11)).foregroundColor(.secondary)
                        }
                    }
                    if let deadline = issue.deadline {
                        Text(DateFormatter.ufShort.string(from: deadline)).font(UFFont.caption(11)).foregroundColor(deadline < Date() ? UFColors.danger : .secondary)
                    }
                }
            }
        }
    }
}

struct IssueDetailView: View {
    let issue: Issue
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showEdit = false
    @Environment(\.presentationMode) var presentationMode
    
    var currentIssue: Issue {
        sitesVM.issues.first(where: { $0.id == issue.id }) ?? issue
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Status Banner
                    HStack {
                        Image(systemName: currentIssue.severity == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(currentIssue.severity.color)
                        VStack(alignment: .leading) {
                            Text(currentIssue.severity.rawValue + " Severity")
                                .font(UFFont.headline(15))
                                .foregroundColor(currentIssue.severity.color)
                            Text(currentIssue.category.rawValue)
                                .font(UFFont.caption(12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(text: currentIssue.status.rawValue, color: currentIssue.status.color)
                    }
                    .padding(16)
                    .background(currentIssue.severity.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    
                    // Details
                    UFCard {
                        VStack(alignment: .leading, spacing: 14) {
                            DetailRow(icon: "location.fill", label: "Zone", value: currentIssue.zone)
                            Divider()
                            DetailRow(icon: "person.fill", label: "Assigned To", value: currentIssue.assignedWorker.isEmpty ? "Unassigned" : currentIssue.assignedWorker)
                            if let deadline = currentIssue.deadline {
                                Divider()
                                DetailRow(icon: "calendar", label: "Deadline", value: DateFormatter.ufDate.string(from: deadline), valueColor: deadline < Date() ? UFColors.danger : nil)
                            }
                            Divider()
                            DetailRow(icon: "clock.fill", label: "Reported", value: DateFormatter.ufDate.string(from: currentIssue.createdAt))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Description
                    UFCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description").font(UFFont.headline(13)).foregroundColor(.secondary)
                            Text(currentIssue.description).font(UFFont.body(14)).foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    
                    // Update Status
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Update Status").font(UFFont.headline(13)).foregroundColor(.secondary).padding(.horizontal, 16)
                        HStack(spacing: 8) {
                            ForEach(Issue.IssueStatus.allCases, id: \.self) { s in
                                Button {
                                    var updated = currentIssue; updated.status = s
                                    sitesVM.updateIssue(updated)
                                } label: {
                                    Text(s.rawValue).font(UFFont.caption(12))
                                        .foregroundColor(currentIssue.status == s ? .white : s.color)
                                        .padding(.horizontal, 10).padding(.vertical, 7)
                                        .background(currentIssue.status == s ? s.color : s.color.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(currentIssue.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil.circle.fill").foregroundColor(UFColors.primary)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditIssueView(issue: currentIssue) }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(UFColors.primary).frame(width: 20)
            Text(label).font(UFFont.caption(13)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(UFFont.headline(13)).foregroundColor(valueColor ?? .primary)
        }
    }
}

struct NewIssueView: View {
    let preselectedSiteId: UUID?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var category: Issue.IssueCategory = .structural
    @State private var severity: Issue.Severity = .medium
    @State private var zone = ""
    @State private var assignedWorker = ""
    @State private var deadline = Date()
    @State private var hasDeadline = false
    @State private var selectedSiteId: UUID? = nil
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Issue Details") {
                            UFTextField(icon: "exclamationmark.triangle.fill", placeholder: "Issue Title", text: $title)
                            
                            // Site picker
                            if sitesVM.sites.count > 1 {
                                Menu {
                                    ForEach(sitesVM.sites) { site in
                                        Button(site.name) { selectedSiteId = site.id }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "building.2.fill").foregroundColor(UFColors.primary).frame(width: 20)
                                        Text(sitesVM.sites.first(where: { $0.id == selectedSiteId })?.name ?? "Select Site")
                                            .foregroundColor(selectedSiteId == nil ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(.secondary)
                                    }
                                    .padding(16).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                }
                            }
                            
                            UFTextField(icon: "map.fill", placeholder: "Zone (e.g. Kitchen)", text: $zone)
                            UFTextField(icon: "person.fill", placeholder: "Assign to Worker (optional)", text: $assignedWorker)
                        }
                        
                        FormSection(title: "Category") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(Issue.IssueCategory.allCases, id: \.self) { cat in
                                    Button { withAnimation { category = cat } } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon).font(.system(size: 14)).foregroundColor(category == cat ? .white : UFColors.primary)
                                            Text(cat.rawValue).font(UFFont.caption(12)).foregroundColor(category == cat ? .white : .primary).lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity).frame(height: 40)
                                        .background(category == cat ? UFColors.primary : UFColors.primary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        FormSection(title: "Severity") {
                            HStack(spacing: 8) {
                                ForEach(Issue.Severity.allCases, id: \.self) { sev in
                                    Button { withAnimation { severity = sev } } label: {
                                        Text(sev.rawValue).font(UFFont.caption(12))
                                            .foregroundColor(severity == sev ? .white : sev.color)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(severity == sev ? sev.color : sev.color.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        FormSection(title: "Deadline") {
                            Toggle(isOn: $hasDeadline) {
                                Text("Set Deadline").font(UFFont.body(14)).foregroundColor(.primary)
                            }
                            .tint(UFColors.primary)
                            if hasDeadline {
                                DatePicker("", selection: $deadline, in: Date()..., displayedComponents: .date)
                                    .labelsHidden().accentColor(UFColors.primary)
                            }
                        }
                        
                        FormSection(title: "Description") {
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Describe the issue in detail...").font(UFFont.body(14)).foregroundColor(.secondary).padding(.horizontal, 4).padding(.top, 8)
                                }
                                TextEditor(text: $description).font(UFFont.body(14)).frame(minHeight: 80).scrollContentBackground(.hidden)
                            }
                            .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            guard !title.isEmpty else { return }
                            let siteId = selectedSiteId ?? preselectedSiteId ?? sitesVM.sites.first?.id ?? UUID()
                            let issue = Issue(siteId: siteId, title: title, category: category, severity: severity, zone: zone.isEmpty ? "General" : zone, description: description, assignedWorker: assignedWorker, deadline: hasDeadline ? deadline : nil, status: .open, createdAt: Date())
                            sitesVM.addIssue(issue)
                            if severity == .critical {
                                notificationsVM.scheduleCriticalIssueNotification(issueTitle: title)
                            }
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Issue Reported!" : "Report Issue")
                                .font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(title.isEmpty ? LinearGradient(
                                    colors: [Color.gray.opacity(0.4)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ) : UFColors.gradientDanger)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(title.isEmpty)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Report Issue").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary)
                }
            }
            .onAppear { selectedSiteId = preselectedSiteId }
        }
    }
}

struct EditIssueView: View {
    let issue: Issue
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var category: Issue.IssueCategory
    @State private var severity: Issue.Severity
    @State private var zone: String
    @State private var assignedWorker: String
    @State private var status: Issue.IssueStatus
    @State private var showConfirmation = false
    
    init(issue: Issue) {
        self.issue = issue
        _title = State(initialValue: issue.title)
        _description = State(initialValue: issue.description)
        _category = State(initialValue: issue.category)
        _severity = State(initialValue: issue.severity)
        _zone = State(initialValue: issue.zone)
        _assignedWorker = State(initialValue: issue.assignedWorker)
        _status = State(initialValue: issue.status)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Details") {
                            UFTextField(icon: "exclamationmark.triangle.fill", placeholder: "Title", text: $title)
                            UFTextField(icon: "map.fill", placeholder: "Zone", text: $zone)
                            UFTextField(icon: "person.fill", placeholder: "Assigned Worker", text: $assignedWorker)
                        }
                        
                        FormSection(title: "Status") {
                            HStack(spacing: 8) {
                                ForEach(Issue.IssueStatus.allCases, id: \.self) { s in
                                    Button { withAnimation { status = s } } label: {
                                        Text(s.rawValue).font(UFFont.caption(12))
                                            .foregroundColor(status == s ? .white : s.color)
                                            .padding(.horizontal, 10).padding(.vertical, 7)
                                            .background(status == s ? s.color : s.color.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        Button {
                            var updated = issue
                            updated.title = title; updated.description = description; updated.category = category
                            updated.severity = severity; updated.zone = zone; updated.assignedWorker = assignedWorker; updated.status = status
                            sitesVM.updateIssue(updated)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Saved!" : "Save Changes").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54).background(UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Issue").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary)
                }
            }
        }
    }
}

struct UnitWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color.black
                    .ignoresSafeArea()
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "uf_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "unit_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [Unit] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


extension WebCoordinator: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        
        popups.append(popup)
        
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        
        switch recognizer.state {
        case .changed:
            if translation.x > 0 {
                popupView.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
            
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in
                    self?.dismissTopPopup()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    popupView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
        if popups.isEmpty {
        }
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = pan.view else { return false }
        
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
