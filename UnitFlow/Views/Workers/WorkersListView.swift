import SwiftUI

struct WorkersListView: View {
    @EnvironmentObject var workersVM: WorkersViewModel
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showNewWorker = false
    @State private var filterStatus: Worker.WorkerStatus? = nil
    @State private var searchText = ""
    @State private var showAttendance = false
    
    var filteredWorkers: [Worker] {
        var result = workersVM.workers
        if let status = filterStatus { result = result.filter { $0.status == status } }
        if !searchText.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.role.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    // Stats row
                    HStack(spacing: 12) {
                        WorkerStatChip(value: "\(workersVM.workers.filter{$0.status == .onSite}.count)", label: "On Site", color: UFColors.success)
                        WorkerStatChip(value: "\(workersVM.workers.filter{$0.status == .offSite}.count)", label: "Off Site", color: .secondary)
                        WorkerStatChip(value: "\(workersVM.workers.filter{$0.status == .sick}.count)", label: "Sick", color: UFColors.danger)
                        WorkerStatChip(value: "\(workersVM.workers.filter{$0.status == .vacation}.count)", label: "Vacation", color: UFColors.info)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    
                    // Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                            ForEach(Worker.WorkerStatus.allCases, id: \.self) { s in
                                FilterPill(title: s.rawValue, isSelected: filterStatus == s, color: s.color) {
                                    filterStatus = filterStatus == s ? nil : s
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
                    
                    if filteredWorkers.isEmpty {
                        UFEmptyState(icon: "person.3", title: "No Workers Found",
                                     subtitle: "Add team members to track attendance and assignments",
                                     buttonTitle: "+ Add Worker") { showNewWorker = true }
                            .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredWorkers) { worker in
                                NavigationLink {
                                    WorkerDetailView(worker: worker)
                                } label: {
                                    WorkerCard(worker: worker)
                                }
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { workersVM.deleteWorker(worker) } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                            Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .searchable(text: $searchText, prompt: "Search workers...")
                    }
                }
            }
            .navigationTitle("Team")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showAttendance = true } label: {
                        Image(systemName: "calendar.badge.checkmark").foregroundColor(UFColors.primary)
                    }
                    Button { showNewWorker = true } label: {
                        Image(systemName: "person.badge.plus.fill").font(.system(size: 20)).foregroundColor(UFColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewWorker) { NewWorkerView() }
        .sheet(isPresented: $showAttendance) { AttendanceView() }
    }
}

struct WorkerStatChip: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(UFFont.display(18)).foregroundColor(color)
            Text(label).font(UFFont.caption(10)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct WorkerCard: View {
    let worker: Worker
    
    var body: some View {
        UFCard(padding: 14) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [UFColors.primary, UFColors.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Text(worker.name.components(separatedBy: " ").compactMap { $0.first.map(String.init) }.joined())
                        .font(UFFont.headline(16)).foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(worker.name).font(UFFont.headline(14)).foregroundColor(.primary).lineLimit(1)
                    Text(worker.role).font(UFFont.caption(12)).foregroundColor(.secondary)
                    if !worker.activeSite.isEmpty {
                        Text(worker.activeSite).font(UFFont.caption(11)).foregroundColor(UFColors.primary).lineLimit(1)
                    }
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: worker.status.icon).font(.system(size: 10)).foregroundColor(worker.status.color)
                        Text(worker.status.rawValue).font(UFFont.caption(10)).foregroundColor(worker.status.color)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(worker.status.color.opacity(0.12)).clipShape(Capsule())
                    
                    if !worker.phone.isEmpty {
                        Text(worker.phone).font(UFFont.caption(10)).foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct WorkerDetailView: View {
    let worker: Worker
    @EnvironmentObject var workersVM: WorkersViewModel
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showEdit = false
    
    var currentWorker: Worker {
        workersVM.workers.first(where: { $0.id == worker.id }) ?? worker
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(UFColors.gradientOrange)
                                .frame(width: 80, height: 80)
                                .shadow(color: UFColors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                            Text(currentWorker.name.components(separatedBy: " ").compactMap { $0.first.map(String.init) }.joined())
                                .font(UFFont.display(28)).foregroundColor(.white)
                        }
                        
                        Text(currentWorker.name).font(UFFont.headline(20)).foregroundColor(.primary)
                        Text(currentWorker.role).font(UFFont.body(15)).foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: currentWorker.status.icon).font(.system(size: 12))
                            Text(currentWorker.status.rawValue).font(UFFont.caption(13))
                        }
                        .foregroundColor(currentWorker.status.color)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(currentWorker.status.color.opacity(0.12)).clipShape(Capsule())
                    }
                    .padding(.top, 16)
                    
                    // Details
                    UFCard {
                        VStack(spacing: 14) {
                            if !currentWorker.phone.isEmpty {
                                DetailRow(icon: "phone.fill", label: "Phone", value: currentWorker.phone)
                                Divider()
                            }
                            DetailRow(icon: "building.2.fill", label: "Active Site", value: currentWorker.activeSite.isEmpty ? "None" : currentWorker.activeSite)
                            if !currentWorker.notes.isEmpty {
                                Divider()
                                DetailRow(icon: "note.text", label: "Notes", value: currentWorker.notes)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Update Status
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Update Status").font(UFFont.headline(13)).foregroundColor(.secondary).padding(.horizontal, 16)
                        HStack(spacing: 8) {
                            ForEach(Worker.WorkerStatus.allCases, id: \.self) { s in
                                Button {
                                    var updated = currentWorker; updated.status = s
                                    workersVM.updateWorker(updated)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: s.icon).font(.system(size: 10))
                                        Text(s.rawValue).font(UFFont.caption(11))
                                    }
                                    .foregroundColor(currentWorker.status == s ? .white : s.color)
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(currentWorker.status == s ? s.color : s.color.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Assign to Site
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Assign to Site").font(UFFont.headline(13)).foregroundColor(.secondary).padding(.horizontal, 16)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    var updated = currentWorker; updated.activeSite = ""
                                    workersVM.updateWorker(updated)
                                } label: {
                                    Text("None")
                                        .font(UFFont.caption(12))
                                        .foregroundColor(currentWorker.activeSite.isEmpty ? .white : .secondary)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(currentWorker.activeSite.isEmpty ? Color.gray : Color.gray.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                ForEach(sitesVM.sites.filter { $0.status == .active }) { site in
                                    Button {
                                        var updated = currentWorker; updated.activeSite = site.name
                                        workersVM.updateWorker(updated)
                                    } label: {
                                        Text(site.name)
                                            .font(UFFont.caption(12))
                                            .foregroundColor(currentWorker.activeSite == site.name ? .white : UFColors.primary)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(currentWorker.activeSite == site.name ? UFColors.primary : UFColors.primary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle(currentWorker.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil.circle.fill").foregroundColor(UFColors.primary)
                }
            }
        }
        .sheet(isPresented: $showEdit) { EditWorkerView(worker: currentWorker) }
    }
}

struct NewWorkerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workersVM: WorkersViewModel
    @EnvironmentObject var sitesVM: SitesViewModel
    
    @State private var name = ""; @State private var role = ""; @State private var phone = ""
    @State private var activeSite = ""; @State private var status: Worker.WorkerStatus = .offSite; @State private var notes = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Worker Info") {
                            UFTextField(icon: "person.fill", placeholder: "Full Name", text: $name)
                            UFTextField(icon: "wrench.and.screwdriver.fill", placeholder: "Role (e.g. Carpenter)", text: $role)
                            UFTextField(icon: "phone.fill", placeholder: "Phone Number", text: $phone, keyboardType: .phonePad)
                        }
                        
                        FormSection(title: "Status") {
                            HStack(spacing: 8) {
                                ForEach(Worker.WorkerStatus.allCases, id: \.self) { s in
                                    Button { withAnimation { status = s } } label: {
                                        Text(s.rawValue).font(UFFont.caption(11))
                                            .foregroundColor(status == s ? .white : s.color)
                                            .padding(.horizontal, 10).padding(.vertical, 7)
                                            .background(status == s ? s.color : s.color.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        FormSection(title: "Assign to Site") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterPill(title: "None", isSelected: activeSite.isEmpty) { activeSite = "" }
                                    ForEach(sitesVM.sites.filter { $0.status == .active }) { site in
                                        FilterPill(title: site.name, isSelected: activeSite == site.name) { activeSite = site.name }
                                    }
                                }
                            }
                        }
                        
                        FormSection(title: "Notes") {
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty { Text("Any additional notes...").font(UFFont.body(14)).foregroundColor(.secondary).padding(.horizontal, 4).padding(.top, 8) }
                                TextEditor(text: $notes).font(UFFont.body(14)).frame(minHeight: 60).scrollContentBackground(.hidden)
                            }
                            .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            guard !name.isEmpty else { return }
                            let worker = Worker(name: name, role: role.isEmpty ? "Worker" : role, phone: phone, activeSite: activeSite, status: status, notes: notes)
                            workersVM.addWorker(worker)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Worker Added!" : "Add Worker").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(name.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(name.isEmpty).buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add Worker").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}

struct EditWorkerView: View {
    let worker: Worker
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workersVM: WorkersViewModel
    
    @State private var name: String; @State private var role: String; @State private var phone: String
    @State private var notes: String; @State private var status: Worker.WorkerStatus; @State private var showConfirmation = false
    
    init(worker: Worker) {
        self.worker = worker
        _name = State(initialValue: worker.name); _role = State(initialValue: worker.role)
        _phone = State(initialValue: worker.phone); _notes = State(initialValue: worker.notes); _status = State(initialValue: worker.status)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Worker Info") {
                            UFTextField(icon: "person.fill", placeholder: "Full Name", text: $name)
                            UFTextField(icon: "wrench.and.screwdriver.fill", placeholder: "Role", text: $role)
                            UFTextField(icon: "phone.fill", placeholder: "Phone", text: $phone, keyboardType: .phonePad)
                        }
                        FormSection(title: "Status") {
                            HStack(spacing: 8) {
                                ForEach(Worker.WorkerStatus.allCases, id: \.self) { s in
                                    Button { withAnimation { status = s } } label: {
                                        Text(s.rawValue).font(UFFont.caption(11)).foregroundColor(status == s ? .white : s.color)
                                            .padding(.horizontal, 10).padding(.vertical, 7).background(status == s ? s.color : s.color.opacity(0.1)).clipShape(Capsule())
                                    }.buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        Button {
                            var updated = worker; updated.name = name; updated.role = role; updated.phone = phone; updated.notes = notes; updated.status = status
                            workersVM.updateWorker(updated)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Saved!" : "Save Changes").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54).background(UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Edit Worker").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}

struct AttendanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workersVM: WorkersViewModel
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var selectedSiteId: UUID? = nil
    @State private var selectedDate = Date()
    @State private var showCheckIn = false
    @State private var selectedWorker: Worker? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                VStack(spacing: 16) {
                    // Site selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sitesVM.sites.filter { $0.status == .active }) { site in
                                FilterPill(title: site.name, isSelected: selectedSiteId == site.id) {
                                    selectedSiteId = site.id
                                }
                            }
                        }.padding(.horizontal, 20).padding(.vertical, 10)
                    }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .accentColor(UFColors.primary).padding(.horizontal, 20)
                    
                    List {
                        ForEach(workersVM.workers) { worker in
                            let checkedIn = selectedSiteId.map { siteId in
                                workersVM.todayAttendance(siteId: siteId).contains { $0.workerId == worker.id }
                            } ?? false
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(worker.name).font(UFFont.headline(14))
                                    Text(worker.role).font(UFFont.caption(12)).foregroundColor(.secondary)
                                }
                                Spacer()
                                if checkedIn {
                                    StatusBadge(text: "Present", color: UFColors.success, small: true)
                                    Button {
                                        workersVM.checkOut(workerId: worker.id)
                                    } label: {
                                        Text("Check Out").font(UFFont.caption(12)).foregroundColor(UFColors.danger)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(UFColors.danger.opacity(0.1)).clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                } else {
                                    Button {
                                        if let siteId = selectedSiteId {
                                            workersVM.checkIn(worker: worker, siteId: siteId)
                                        }
                                    } label: {
                                        Text("Check In").font(UFFont.caption(12)).foregroundColor(UFColors.success)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(UFColors.success.opacity(0.1)).clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .disabled(selectedSiteId == nil)
                                }
                            }
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Attendance").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
            .onAppear { selectedSiteId = sitesVM.sites.first(where: { $0.status == .active })?.id }
        }
    }
}
