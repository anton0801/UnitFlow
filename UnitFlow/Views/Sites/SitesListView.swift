import SwiftUI

struct SitesListView: View {
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showNewSite = false
    @State private var searchText = ""
    @State private var filterStatus: ConstructionSite.SiteStatus? = nil
    
    var filteredSites: [ConstructionSite] {
        var result = sitesVM.sites
        if let status = filterStatus { result = result.filter { $0.status == status } }
        if !searchText.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                            ForEach(ConstructionSite.SiteStatus.allCases, id: \.self) { s in
                                FilterPill(title: s.rawValue, isSelected: filterStatus == s, color: s.color) { filterStatus = filterStatus == s ? nil : s }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    if filteredSites.isEmpty {
                        UFEmptyState(icon: "building.2", title: "No Sites Found",
                                     subtitle: "Add your first construction site to get started",
                                     buttonTitle: "+ New Site") { showNewSite = true }
                            .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredSites) { site in
                                NavigationLink {
                                    SiteDetailView(site: site)
                                } label: {
                                    SiteListRow(site: site, issueCount: sitesVM.openIssues(for: site.id))
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        sitesVM.deleteSite(site)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                            Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .searchable(text: $searchText, prompt: "Search sites...")
                    }
                }
            }
            .navigationTitle("Sites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewSite = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(UFColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewSite) { NewSiteView() }
    }
}

struct SiteListRow: View {
    let site: ConstructionSite
    let issueCount: Int
    
    var body: some View {
        UFCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: site.siteType.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(UFColors.primary)
                        .padding(8)
                        .background(UFColors.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(site.name).font(UFFont.headline(15)).foregroundColor(.primary).lineLimit(1)
                        Text(site.address).font(UFFont.caption(12)).foregroundColor(.secondary).lineLimit(1)
                    }
                    Spacer()
                    StatusBadge(text: site.status.rawValue, color: site.status.color, small: true)
                }
                
                HStack(spacing: 4) {
                    Text("\(Int(site.progressPercent))%")
                        .font(UFFont.headline(12))
                        .foregroundColor(UFColors.primary)
                    UFProgressBar(progress: site.progressPercent)
                }
                
                HStack {
                    Text(site.clientName).font(UFFont.caption(11)).foregroundColor(.secondary)
                    Spacer()
                    if issueCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(UFColors.danger)
                            Text("\(issueCount)").font(UFFont.caption(11)).foregroundColor(UFColors.danger)
                        }
                    }
                    Text(DateFormatter.ufShort.string(from: site.plannedEndDate)).font(UFFont.caption(11)).foregroundColor(.secondary)
                }
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = UFColors.primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UFFont.caption(13))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color.gray.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Site Detail
struct SiteDetailView: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var selectedTab = 0
    @State private var showEdit = false
    @State private var showNewIssue = false
    @State private var showNewReport = false
    @State private var showNewTask = false
    @State private var showNewMaterial = false
    @State private var showDelivery = false
    @State private var showDocument = false
    
    private var currentSite: ConstructionSite {
        sitesVM.sites.first(where: { $0.id == site.id }) ?? site
    }
    
    let tabs = ["Overview", "Stages", "Issues", "Photos", "Team", "Reports"]
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Header card
                SiteHeaderCard(site: currentSite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                // Tab selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = i }
                            } label: {
                                Text(tabs[i])
                                    .font(UFFont.caption(13))
                                    .foregroundColor(selectedTab == i ? .white : .secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == i ? UFColors.primary : Color.gray.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: SiteOverviewTab(site: currentSite)
                        case 1: SiteStagesTab(site: currentSite)
                        case 2: SiteIssuesTab(site: currentSite, showNewIssue: $showNewIssue)
                        case 3: SitePhotosTab(site: currentSite)
                        case 4: SiteTeamTab(site: currentSite)
                        case 5: SiteReportsTab(site: currentSite, showNewReport: $showNewReport)
                        default: EmptyView()
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(currentSite.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit Site", systemImage: "pencil") }
                    Button { showNewReport = true } label: { Label("New Report", systemImage: "doc.text") }
                    Button { showNewTask = true } label: { Label("New Task", systemImage: "checkmark.circle") }
                    Button { showNewMaterial = true } label: { Label("Request Material", systemImage: "cube") }
                    Button { showDelivery = true } label: { Label("Log Delivery", systemImage: "shippingbox") }
                    Button { showDocument = true } label: { Label("Add Document", systemImage: "doc.badge.plus") }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(UFColors.primary)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditSiteView(site: currentSite) }
        .sheet(isPresented: $showNewIssue) { NewIssueView(preselectedSiteId: site.id) }
        .sheet(isPresented: $showNewReport) { NewReportView(preselectedSiteId: site.id) }
        .sheet(isPresented: $showNewTask) { NewTaskView(siteId: site.id) }
        .sheet(isPresented: $showNewMaterial) { NewMaterialView(siteId: site.id) }
        .sheet(isPresented: $showDelivery) { NewDeliveryView(siteId: site.id) }
        .sheet(isPresented: $showDocument) { NewDocumentView(siteId: site.id) }
    }
}

struct SiteHeaderCard: View {
    let site: ConstructionSite
    
    var body: some View {
        UFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(site.address).font(UFFont.caption(12)).foregroundColor(.secondary)
                        Text("Client: \(site.clientName)").font(UFFont.caption(12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: site.status.rawValue, color: site.status.color)
                }
                
                VStack(spacing: 6) {
                    HStack {
                        Text("Progress").font(UFFont.caption(12)).foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(site.progressPercent))%").font(UFFont.headline(13)).foregroundColor(UFColors.primary)
                    }
                    UFProgressBar(progress: site.progressPercent, height: 10)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Started").font(UFFont.caption(10)).foregroundColor(.secondary)
                        Text(DateFormatter.ufShort.string(from: site.startDate)).font(UFFont.headline(12))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Due").font(UFFont.caption(10)).foregroundColor(.secondary)
                        Text(DateFormatter.ufShort.string(from: site.plannedEndDate)).font(UFFont.headline(12))
                    }
                }
            }
        }
    }
}

// MARK: - Overview Tab
struct SiteOverviewTab: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    
    var body: some View {
        VStack(spacing: 14) {
            // Zones
            VStack(alignment: .leading, spacing: 10) {
                UFSectionHeader(title: "Zones").padding(.horizontal, 16)
                ForEach(site.zones) { zone in
                    HStack {
                        Text(zone.name).font(UFFont.body(14)).foregroundColor(.primary)
                        Spacer()
                        StatusBadge(text: zone.status.rawValue, color: zone.status.color, small: true)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
            }
            
            // Timeline
            VStack(alignment: .leading, spacing: 10) {
                UFSectionHeader(title: "Recent Activity").padding(.horizontal, 16)
                ForEach(sitesVM.timeline(for: site.id).prefix(5)) { event in
                    TimelineRow(event: event)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct TimelineRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(event.type.color.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: event.type.icon).font(.system(size: 13, weight: .semibold)).foregroundColor(event.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(UFFont.headline(13)).foregroundColor(.primary)
                Text(event.description).font(UFFont.caption(12)).foregroundColor(.secondary).lineLimit(2)
            }
            Spacer()
            Text(DateFormatter.ufShort.string(from: event.date)).font(UFFont.caption(10)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Stages Tab
struct SiteStagesTab: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    
    var currentSite: ConstructionSite {
        sitesVM.sites.first(where: { $0.id == site.id }) ?? site
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(currentSite.stages.sorted(by: { $0.order < $1.order })) { stage in
                StageRow(stage: stage, siteId: site.id)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct StageRow: View {
    let stage: WorkStage
    let siteId: UUID
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showPicker = false
    
    var body: some View {
        UFCard(padding: 14) {
            HStack {
                Image(systemName: stage.status.icon)
                    .font(.system(size: 20))
                    .foregroundColor(stage.status.color)
                    .frame(width: 28)
                
                Text(stage.name)
                    .font(UFFont.headline(14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    ForEach(WorkStage.StageStatus.allCases, id: \.self) { s in
                        Button {
                            sitesVM.updateStageStatus(siteId: siteId, stageId: stage.id, status: s)
                        } label: {
                            HStack {
                                Text(s.rawValue)
                                if stage.status == s { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    StatusBadge(text: stage.status.rawValue, color: stage.status.color, small: true)
                }
            }
        }
    }
}

// MARK: - Issues Tab
struct SiteIssuesTab: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    @Binding var showNewIssue: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button { showNewIssue = true } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16))
                    Text("Report Issue").font(UFFont.headline(15))
                }
                .foregroundColor(UFColors.danger)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(UFColors.danger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 16)
            
            let issues = sitesVM.issues(for: site.id)
            if issues.isEmpty {
                UFEmptyState(icon: "checkmark.shield.fill", title: "No Issues", subtitle: "Great! No issues reported on this site")
            } else {
                ForEach(issues) { issue in
                    IssueCard(issue: issue)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Photos Tab
struct SitePhotosTab: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showAddPhoto = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button { showAddPhoto = true } label: {
                HStack {
                    Image(systemName: "camera.fill").font(.system(size: 16))
                    Text("Add Photo").font(UFFont.headline(15))
                }
                .foregroundColor(UFColors.primary)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(UFColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 16)
            
            let photos = sitesVM.photos(for: site.id)
            if photos.isEmpty {
                UFEmptyState(icon: "photo.on.rectangle", title: "No Photos", subtitle: "Add photos to document progress")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(photos) { photo in
                        if let uiImage = UIImage(data: photo.imageData) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(height: 100).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoView(siteId: site.id)
        }
    }
}

// MARK: - Team Tab
struct SiteTeamTab: View {
    let site: ConstructionSite
    @EnvironmentObject var workersVM: WorkersViewModel
    
    var siteWorkers: [Worker] {
        workersVM.workers.filter { $0.activeSite == site.name }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if siteWorkers.isEmpty {
                UFEmptyState(icon: "person.3", title: "No Workers Assigned", subtitle: "Workers assigned to this site will appear here")
            } else {
                ForEach(siteWorkers) { worker in
                    WorkerCard(worker: worker)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Reports Tab
struct SiteReportsTab: View {
    let site: ConstructionSite
    @EnvironmentObject var sitesVM: SitesViewModel
    @Binding var showNewReport: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button { showNewReport = true } label: {
                HStack {
                    Image(systemName: "doc.text.fill").font(.system(size: 16))
                    Text("New Report").font(UFFont.headline(15))
                }
                .foregroundColor(UFColors.primary)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(UFColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 16)
            
            let reports = sitesVM.reports(for: site.id)
            if reports.isEmpty {
                UFEmptyState(icon: "doc.text", title: "No Reports", subtitle: "Daily reports will appear here")
            } else {
                ForEach(reports) { report in
                    ReportCard(report: report)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}
