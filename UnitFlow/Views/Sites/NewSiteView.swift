import SwiftUI

struct NewSiteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    
    @State private var name = ""
    @State private var address = ""
    @State private var clientName = ""
    @State private var startDate = Date()
    @State private var plannedEndDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var siteType: ConstructionSite.SiteType = .house
    @State private var status: ConstructionSite.SiteStatus = .planning
    @State private var notes = ""
    @State private var showConfirmation = false
    @State private var selectedZones: Set<String> = Set(SiteZone.defaultZones.prefix(3))
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Basic Info
                        FormSection(title: "Basic Information") {
                            UFTextField(icon: "building.2.fill", placeholder: "Site Name", text: $name)
                            UFTextField(icon: "mappin.circle.fill", placeholder: "Address", text: $address)
                            UFTextField(icon: "person.fill", placeholder: "Client Name", text: $clientName)
                        }
                        
                        // Site Type
                        FormSection(title: "Site Type") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ConstructionSite.SiteType.allCases, id: \.self) { type in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { siteType = type }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 20))
                                                .foregroundColor(siteType == type ? .white : UFColors.primary)
                                            Text(type.rawValue)
                                                .font(UFFont.caption(11))
                                                .foregroundColor(siteType == type ? .white : .primary)
                                        }
                                        .frame(maxWidth: .infinity).frame(height: 60)
                                        .background(siteType == type ? UFColors.primary : UFColors.primary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        // Dates
                        FormSection(title: "Timeline") {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Date").font(UFFont.caption(12)).foregroundColor(.secondary)
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(UFColors.primary)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Planned End").font(UFFont.caption(12)).foregroundColor(.secondary)
                                    DatePicker("", selection: $plannedEndDate, in: startDate..., displayedComponents: .date)
                                        .labelsHidden()
                                        .accentColor(UFColors.primary)
                                }
                            }
                        }
                        
                        // Status
                        FormSection(title: "Initial Status") {
                            HStack(spacing: 8) {
                                ForEach(ConstructionSite.SiteStatus.allCases, id: \.self) { s in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { status = s }
                                    } label: {
                                        Text(s.rawValue)
                                            .font(UFFont.caption(12))
                                            .foregroundColor(status == s ? .white : s.color)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(status == s ? s.color : s.color.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        // Zones
                        FormSection(title: "Zones") {
                            FlowLayout(spacing: 8) {
                                ForEach(SiteZone.defaultZones, id: \.self) { zone in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedZones.contains(zone) { selectedZones.remove(zone) }
                                            else { selectedZones.insert(zone) }
                                        }
                                    } label: {
                                        Text(zone)
                                            .font(UFFont.caption(12))
                                            .foregroundColor(selectedZones.contains(zone) ? .white : .secondary)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(selectedZones.contains(zone) ? UFColors.primary : Color.gray.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        // Notes
                        FormSection(title: "Notes (Optional)") {
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Additional notes about the site...")
                                        .font(UFFont.body(14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.top, 8)
                                }
                                TextEditor(text: $notes)
                                    .font(UFFont.body(14))
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Save Button
                        Button {
                            guard !name.isEmpty, !address.isEmpty else { return }
                            let zones = selectedZones.map { zoneName in
                                SiteZone(name: zoneName, status: .notStarted, notes: "")
                            }
                            let newSite = ConstructionSite(
                                name: name, address: address, clientName: clientName.isEmpty ? "TBD" : clientName,
                                startDate: startDate, plannedEndDate: plannedEndDate, siteType: siteType,
                                status: status, notes: notes, stages: WorkStage.defaultStages(), zones: zones,
                                responsiblePerson: "", progressPercent: 0
                            )
                            sitesVM.addSite(newSite)
                            withAnimation { showConfirmation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } label: {
                            HStack {
                                if showConfirmation {
                                    Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                                    Text("Site Created!")
                                } else {
                                    Text("Create Site")
                                }
                            }
                            .font(UFFont.headline(17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(name.isEmpty || address.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(name.isEmpty || address.isEmpty)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(UFColors.primary)
                }
            }
        }
    }
}

struct EditSiteView: View {
    let site: ConstructionSite
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    
    @State private var name: String
    @State private var address: String
    @State private var clientName: String
    @State private var startDate: Date
    @State private var plannedEndDate: Date
    @State private var siteType: ConstructionSite.SiteType
    @State private var status: ConstructionSite.SiteStatus
    @State private var notes: String
    @State private var showConfirmation = false
    
    init(site: ConstructionSite) {
        self.site = site
        _name = State(initialValue: site.name)
        _address = State(initialValue: site.address)
        _clientName = State(initialValue: site.clientName)
        _startDate = State(initialValue: site.startDate)
        _plannedEndDate = State(initialValue: site.plannedEndDate)
        _siteType = State(initialValue: site.siteType)
        _status = State(initialValue: site.status)
        _notes = State(initialValue: site.notes)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Basic Information") {
                            UFTextField(icon: "building.2.fill", placeholder: "Site Name", text: $name)
                            UFTextField(icon: "mappin.circle.fill", placeholder: "Address", text: $address)
                            UFTextField(icon: "person.fill", placeholder: "Client Name", text: $clientName)
                        }
                        
                        FormSection(title: "Status") {
                            HStack(spacing: 8) {
                                ForEach(ConstructionSite.SiteStatus.allCases, id: \.self) { s in
                                    Button {
                                        withAnimation { status = s }
                                    } label: {
                                        Text(s.rawValue).font(UFFont.caption(12))
                                            .foregroundColor(status == s ? .white : s.color)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(status == s ? s.color : s.color.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        FormSection(title: "Timeline") {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Date").font(UFFont.caption(12)).foregroundColor(.secondary)
                                    DatePicker("", selection: $startDate, displayedComponents: .date).labelsHidden().accentColor(UFColors.primary)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Planned End").font(UFFont.caption(12)).foregroundColor(.secondary)
                                    DatePicker("", selection: $plannedEndDate, in: startDate..., displayedComponents: .date).labelsHidden().accentColor(UFColors.primary)
                                }
                            }
                        }
                        
                        Button {
                            var updated = site
                            updated.name = name; updated.address = address; updated.clientName = clientName
                            updated.startDate = startDate; updated.plannedEndDate = plannedEndDate
                            updated.siteType = siteType; updated.status = status; updated.notes = notes
                            sitesVM.updateSite(updated)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Saved!" : "Save Changes")
                                .font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Site").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary)
                }
            }
        }
    }
}

// MARK: - Form Section
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(UFFont.headline(13))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                content
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(0, height))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > maxWidth && !rows.last!.isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }
        return rows
    }
}
