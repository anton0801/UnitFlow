import SwiftUI

// MARK: - Daily Reports
struct NewReportView: View {
    var preselectedSiteId: UUID? = nil
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    
    @State private var selectedSiteId: UUID? = nil
    @State private var date = Date()
    @State private var weather: DailyReport.WeatherCondition = .sunny
    @State private var workersPresent = 1
    @State private var workCompleted = ""
    @State private var problems = ""
    @State private var materialsDelivered = ""
    @State private var notes = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Report Info") {
                            // Site picker
                            Menu {
                                ForEach(sitesVM.sites) { site in
                                    Button(site.name) { selectedSiteId = site.id }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "building.2.fill").foregroundColor(UFColors.primary).frame(width: 20)
                                    Text(sitesVM.sites.first(where: { $0.id == selectedSiteId })?.name ?? "Select Site").foregroundColor(selectedSiteId == nil ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                .padding(16).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .font(UFFont.body(14)).accentColor(UFColors.primary)
                                .padding(16).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        FormSection(title: "Weather") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(DailyReport.WeatherCondition.allCases, id: \.self) { w in
                                        Button { withAnimation { weather = w } } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: w.icon).font(.system(size: 22)).foregroundColor(weather == w ? .white : UFColors.primary)
                                                Text(w.rawValue).font(UFFont.caption(10)).foregroundColor(weather == w ? .white : .primary)
                                            }
                                            .frame(width: 70, height: 60)
                                            .background(weather == w ? UFColors.primary : UFColors.primary.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        FormSection(title: "Workers Present") {
                            HStack {
                                Text("\(workersPresent) workers").font(UFFont.body(14)).foregroundColor(.primary)
                                Spacer()
                                Stepper("", value: $workersPresent, in: 0...50).labelsHidden()
                            }
                            .padding(16).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        FormSection(title: "Work Completed *") {
                            ZStack(alignment: .topLeading) {
                                if workCompleted.isEmpty { Text("Describe what was accomplished today...").font(UFFont.body(14)).foregroundColor(.secondary).padding(.horizontal, 4).padding(.top, 8) }
                                TextEditor(text: $workCompleted).font(UFFont.body(14)).frame(minHeight: 80).scrollContentBackground(.hidden)
                            }
                            .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        FormSection(title: "Problems Encountered") {
                            ZStack(alignment: .topLeading) {
                                if problems.isEmpty { Text("Any issues or blockers?").font(UFFont.body(14)).foregroundColor(.secondary).padding(.horizontal, 4).padding(.top, 8) }
                                TextEditor(text: $problems).font(UFFont.body(14)).frame(minHeight: 60).scrollContentBackground(.hidden)
                            }
                            .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        FormSection(title: "Materials Delivered") {
                            UFTextField(icon: "shippingbox.fill", placeholder: "e.g. 50 pcs drywall, 2 bags cement", text: $materialsDelivered)
                        }
                        
                        FormSection(title: "Additional Notes") {
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty { Text("Any other notes...").font(UFFont.body(14)).foregroundColor(.secondary).padding(.horizontal, 4).padding(.top, 8) }
                                TextEditor(text: $notes).font(UFFont.body(14)).frame(minHeight: 60).scrollContentBackground(.hidden)
                            }
                            .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            guard !workCompleted.isEmpty, let siteId = selectedSiteId else { return }
                            let siteName = sitesVM.sites.first(where: { $0.id == siteId })?.name ?? ""
                            let report = DailyReport(siteId: siteId, siteName: siteName, date: date, weather: weather, workersPresent: workersPresent, workCompleted: workCompleted, problems: problems, materialsDelivered: materialsDelivered, notes: notes, photoCount: 0, issueCount: 0)
                            sitesVM.addReport(report)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Report Submitted!" : "Submit Report")
                                .font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(workCompleted.isEmpty || selectedSiteId == nil ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(workCompleted.isEmpty || selectedSiteId == nil)
                        .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Daily Report").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
            .onAppear {
                selectedSiteId = preselectedSiteId ?? sitesVM.sites.first?.id
            }
        }
    }
}

struct ReportCard: View {
    let report: DailyReport
    
    var body: some View {
        UFCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: report.weather.icon).font(.system(size: 14)).foregroundColor(UFColors.primary)
                    Text(DateFormatter.ufFull.string(from: report.date)).font(UFFont.headline(14)).foregroundColor(.primary)
                    Spacer()
                    Text("\(report.workersPresent) workers").font(UFFont.caption(11)).foregroundColor(.secondary)
                }
                Text(report.workCompleted).font(UFFont.caption(12)).foregroundColor(.secondary).lineLimit(2)
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill").font(.system(size: 10)).foregroundColor(.secondary)
                        Text("\(report.photoCount) photos").font(UFFont.caption(11)).foregroundColor(.secondary)
                    }
                    Spacer()
                    if !report.problems.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(UFColors.warning)
                            Text("Issues noted").font(UFFont.caption(11)).foregroundColor(UFColors.warning)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Photos View
struct PhotosView: View {
    let siteId: UUID?
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showAddPhoto = false
    @State private var filterType: SitePhoto.PhotoType? = nil
    
    var photos: [SitePhoto] {
        let all = siteId.map { sitesVM.photos(for: $0) } ?? sitesVM.photos
        if let type = filterType { return all.filter { $0.type == type } }
        return all
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All", isSelected: filterType == nil) { filterType = nil }
                            ForEach(SitePhoto.PhotoType.allCases, id: \.self) { t in
                                FilterPill(title: t.rawValue, isSelected: filterType == t, color: t.color) { filterType = filterType == t ? nil : t }
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 10)
                    }
                    
                    if photos.isEmpty {
                        UFEmptyState(icon: "photo.on.rectangle", title: "No Photos", subtitle: "Document your site progress with photos",
                                     buttonTitle: "Add Photo") { showAddPhoto = true }
                            .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(photos) { photo in
                                    PhotoGridItem(photo: photo)
                                }
                            }
                            .padding(16)
                            Color.clear.frame(height: 80)
                        }
                    }
                }
            }
            .navigationTitle("Photos").navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddPhoto = true } label: {
                        Image(systemName: "camera.fill").font(.system(size: 20)).foregroundColor(UFColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddPhoto) { AddPhotoView(siteId: siteId ?? sitesVM.sites.first?.id ?? UUID()) }
    }
}

struct PhotoGridItem: View {
    let photo: SitePhoto
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showDetail = false
    
    var body: some View {
        Button { showDetail = true } label: {
            ZStack(alignment: .bottomLeading) {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 140).clipped()
                } else {
                    Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 140)
                    Image(systemName: "photo").font(.system(size: 30)).foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    StatusBadge(text: photo.type.rawValue, color: photo.type.color, small: true)
                    if !photo.zone.isEmpty {
                        Text(photo.zone).font(UFFont.caption(10)).foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(8)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(role: .destructive) { sitesVM.deletePhoto(photo) } label: { Label("Delete", systemImage: "trash.fill") }
        }
    }
}

struct AddPhotoView: View {
    let siteId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    
    @State private var zone = ""
    @State private var comment = ""
    @State private var photoType: SitePhoto.PhotoType = .progress
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var showConfirmation = false
    
    // Use a placeholder color image if no camera
    func makePlaceholderImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let img = renderer.image { ctx in
            let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed]
            colors.randomElement()?.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 400, height: 300)))
        }
        return img.jpegData(compressionQuality: 0.8) ?? Data()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Image preview / picker
                        Button { showImagePicker = true } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                
                                if let img = selectedImage {
                                    Image(uiImage: img).resizable().scaledToFill().frame(height: 200).clipped().clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.fill").font(.system(size: 36)).foregroundColor(UFColors.primary)
                                        Text("Tap to add photo").font(UFFont.caption(14)).foregroundColor(.secondary)
                                        Text("(Demo: uses placeholder)").font(UFFont.caption(11)).foregroundColor(.secondary.opacity(0.6))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .buttonStyle(ScaleButtonStyle())
                        
                        FormSection(title: "Photo Type") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(SitePhoto.PhotoType.allCases, id: \.self) { t in
                                        Button { withAnimation { photoType = t } } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: t.icon).font(.system(size: 11))
                                                Text(t.rawValue).font(UFFont.caption(12))
                                            }
                                            .foregroundColor(photoType == t ? .white : t.color)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(photoType == t ? t.color : t.color.opacity(0.1))
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        FormSection(title: "Details") {
                            UFTextField(icon: "map.fill", placeholder: "Zone (e.g. Kitchen)", text: $zone)
                            UFTextField(icon: "text.bubble.fill", placeholder: "Comment (optional)", text: $comment)
                        }
                        
                        Button {
                            let imageData = selectedImage?.jpegData(compressionQuality: 0.8) ?? makePlaceholderImageData()
                            let photo = SitePhoto(siteId: siteId, imageData: imageData, zone: zone.isEmpty ? "General" : zone, date: Date(), comment: comment, type: photoType)
                            sitesVM.addPhoto(photo)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Photo Saved!" : "Save Photo").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54).background(UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Add Photo").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}

// MARK: - Materials
struct NewMaterialView: View {
    let siteId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var materialName = ""; @State private var quantity = ""
    @State private var unit = "pcs"; @State private var urgency: MaterialRequest.Urgency = .normal
    @State private var zone = ""; @State private var neededDate = Date()
    @State private var showConfirmation = false
    
    let units = ["pcs", "m", "m²", "m³", "kg", "L", "bags", "rolls", "sets"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Material Info") {
                            UFTextField(icon: "cube.fill", placeholder: "Material Name", text: $materialName)
                            HStack(spacing: 10) {
                                UFTextField(icon: "number.circle.fill", placeholder: "Quantity", text: $quantity, keyboardType: .decimalPad)
                                Picker("Unit", selection: $unit) {
                                    ForEach(units, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu).accentColor(UFColors.primary)
                                .padding(16).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            UFTextField(icon: "map.fill", placeholder: "Zone", text: $zone)
                        }
                        
                        FormSection(title: "Urgency") {
                            HStack(spacing: 8) {
                                ForEach(MaterialRequest.Urgency.allCases, id: \.self) { u in
                                    Button { withAnimation { urgency = u } } label: {
                                        Text(u.rawValue).font(UFFont.caption(12)).foregroundColor(urgency == u ? .white : u.color)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(urgency == u ? u.color : u.color.opacity(0.12)).clipShape(Capsule())
                                    }.buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        
                        FormSection(title: "Needed By") {
                            DatePicker("", selection: $neededDate, in: Date()..., displayedComponents: .date)
                                .labelsHidden().accentColor(UFColors.primary)
                        }
                        
                        Button {
                            guard !materialName.isEmpty else { return }
                            let req = MaterialRequest(siteId: siteId, materialName: materialName, quantity: Double(quantity) ?? 1, unit: unit, urgency: urgency, zone: zone.isEmpty ? "General" : zone, requestedBy: authVM.currentUser?.fullName ?? "Me", neededDate: neededDate, status: .requested, createdAt: Date())
                            sitesVM.addMaterialRequest(req)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Request Submitted!" : "Submit Request").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(materialName.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(materialName.isEmpty).buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Request Material").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}

// MARK: - Delivery View
struct NewDeliveryView: View {
    let siteId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var supplier = ""; @State private var items = ""; @State private var notes = ""
    @State private var deliveryDate = Date(); @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Delivery Details") {
                            UFTextField(icon: "building.2.fill", placeholder: "Supplier Name", text: $supplier)
                            DatePicker("Delivery Date", selection: $deliveryDate, displayedComponents: .date)
                                .font(UFFont.body(14)).accentColor(UFColors.primary)
                                .padding(16).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        FormSection(title: "Items Delivered") {
                            ZStack(alignment: .topLeading) {
                                if items.isEmpty { Text("List all items delivered...").font(UFFont.body(14)).foregroundColor(.secondary).padding(.horizontal, 4).padding(.top, 8) }
                                TextEditor(text: $items).font(UFFont.body(14)).frame(minHeight: 80).scrollContentBackground(.hidden)
                            }.padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        FormSection(title: "Notes") {
                            UFTextField(icon: "text.bubble.fill", placeholder: "Additional notes...", text: $notes)
                        }
                        
                        Button {
                            guard !supplier.isEmpty else { return }
                            let delivery = Delivery(siteId: siteId, supplier: supplier, deliveryDate: deliveryDate, items: items, notes: notes, acceptedBy: authVM.currentUser?.fullName ?? "Me")
                            sitesVM.addDelivery(delivery)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Delivery Logged!" : "Log Delivery").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(supplier.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(supplier.isEmpty).buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Log Delivery").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}

// MARK: - Task View
struct NewTaskView: View {
    let siteId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    @EnvironmentObject var workersVM: WorkersViewModel
    
    @State private var title = ""; @State private var zone = ""; @State private var stage = "General"
    @State private var assignedWorker = ""; @State private var dueDate = Date()
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Task Details") {
                            UFTextField(icon: "checkmark.circle.fill", placeholder: "Task Title", text: $title)
                            UFTextField(icon: "map.fill", placeholder: "Zone", text: $zone)
                        }
                        
                        FormSection(title: "Stage") {
                            let stages = sitesVM.sites.first(where: { $0.id == siteId })?.stages ?? WorkStage.defaultStages()
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(stages) { s in
                                        FilterPill(title: s.name, isSelected: stage == s.name) { stage = s.name }
                                    }
                                }
                            }
                        }
                        
                        FormSection(title: "Assign to Worker") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterPill(title: "Unassigned", isSelected: assignedWorker.isEmpty) { assignedWorker = "" }
                                    ForEach(workersVM.workers) { w in
                                        FilterPill(title: w.name, isSelected: assignedWorker == w.name) { assignedWorker = w.name }
                                    }
                                }
                            }
                        }
                        
                        FormSection(title: "Due Date") {
                            DatePicker("", selection: $dueDate, displayedComponents: .date).labelsHidden().accentColor(UFColors.primary)
                        }
                        
                        Button {
                            guard !title.isEmpty else { return }
                            let task = SiteTask(siteId: siteId, title: title, zone: zone.isEmpty ? "General" : zone, stage: stage, assignedWorker: assignedWorker, dueDate: dueDate, status: .todo, createdAt: Date())
                            sitesVM.addTask(task)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Task Created!" : "Create Task").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(title.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(title.isEmpty).buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}

// MARK: - Document View
struct NewDocumentView: View {
    let siteId: UUID
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var sitesVM: SitesViewModel
    
    @State private var title = ""; @State private var category: SiteDocument.DocumentCategory = .estimate
    @State private var notes = ""; @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Document Info") {
                            UFTextField(icon: "doc.fill", placeholder: "Document Title", text: $title)
                        }
                        FormSection(title: "Category") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(SiteDocument.DocumentCategory.allCases, id: \.self) { cat in
                                    Button { withAnimation { category = cat } } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon).font(.system(size: 14)).foregroundColor(category == cat ? .white : UFColors.primary)
                                            Text(cat.rawValue).font(UFFont.caption(12)).foregroundColor(category == cat ? .white : .primary).lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity).frame(height: 44)
                                        .background(category == cat ? UFColors.primary : UFColors.primary.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
                                    }.buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        FormSection(title: "Notes") {
                            UFTextField(icon: "text.bubble.fill", placeholder: "Notes...", text: $notes)
                        }
                        
                        Button {
                            guard !title.isEmpty else { return }
                            let dummyData = title.data(using: .utf8) ?? Data()
                            let doc = SiteDocument(siteId: siteId, title: title, category: category, fileData: dummyData, fileName: "\(title).pdf", createdAt: Date(), notes: notes)
                            sitesVM.addDocument(doc)
                            showConfirmation = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { presentationMode.wrappedValue.dismiss() }
                        } label: {
                            Text(showConfirmation ? "✓ Document Added!" : "Add Document").font(UFFont.headline(17)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(title.isEmpty ? LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) : UFColors.gradientOrange).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(title.isEmpty).buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20).padding(.bottom, 40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Add Document").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(UFColors.primary) } }
        }
    }
}
