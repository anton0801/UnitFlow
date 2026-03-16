import SwiftUI

// MARK: - Materials List View
struct MaterialsListView: View {
    let siteId: UUID
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showNewMaterial = false
    @State private var filterStatus: MaterialRequest.RequestStatus? = nil

    var filteredMaterials: [MaterialRequest] {
        let all = sitesVM.materials(for: siteId)
        if let st = filterStatus { return all.filter { $0.status == st } }
        return all
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                        ForEach(MaterialRequest.RequestStatus.allCases, id: \.self) { st in
                            FilterPill(title: st.rawValue, isSelected: filterStatus == st, color: st.color) {
                                filterStatus = filterStatus == st ? nil : st
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                }

                if filteredMaterials.isEmpty {
                    UFEmptyState(
                        icon: "cube.box",
                        title: "No Material Requests",
                        subtitle: "Request materials for this site",
                        buttonTitle: "Request Material"
                    ) { showNewMaterial = true }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredMaterials) { req in
                            MaterialCard(req: req)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        sitesVM.deleteMaterialRequest(req)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if req.status == .requested {
                                        Button {
                                            var updated = req
                                            updated.status = .approved
                                            sitesVM.updateMaterialRequest(updated)
                                        } label: {
                                            Label("Approve", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(UFColors.success)
                                    }
                                }
                        }
                        Color.clear.frame(height: 80)
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Materials")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNewMaterial = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(UFColors.primary)
                }
            }
        }
        .sheet(isPresented: $showNewMaterial) {
            NewMaterialView(siteId: siteId)
        }
    }
}

struct MaterialCard: View {
    let req: MaterialRequest
    @EnvironmentObject var sitesVM: SitesViewModel

    var body: some View {
        UFCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(req.urgency.color)
                        .padding(8)
                        .background(req.urgency.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(req.materialName)
                            .font(UFFont.headline(14))
                            .foregroundColor(.primary)
                        Text("\(String(format: "%.1f", req.quantity)) \(req.unit) · \(req.zone)")
                            .font(UFFont.caption(12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: req.urgency.rawValue, color: req.urgency.color, small: true)
                }

                HStack {
                    StatusBadge(text: req.status.rawValue, color: req.status.color, small: true)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(req.requestedBy)
                            .font(UFFont.caption(11))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(DateFormatter.ufShort.string(from: req.neededDate))
                            .font(UFFont.caption(11))
                            .foregroundColor(req.neededDate < Date() && req.status != .delivered ? UFColors.danger : .secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Before/After Comparison View
struct BeforeAfterView: View {
    let siteId: UUID
    @EnvironmentObject var sitesVM: SitesViewModel

    @State private var beforePhoto: SitePhoto? = nil
    @State private var afterPhoto: SitePhoto? = nil
    @State private var sliderPosition: CGFloat = 0.5
    @State private var showBeforePicker = false
    @State private var showAfterPicker = false

    var beforePhotos: [SitePhoto] {
        sitesVM.photos(for: siteId).filter { $0.type == .before || $0.type == .progress }
    }

    var afterPhotos: [SitePhoto] {
        sitesVM.photos(for: siteId).filter { $0.type == .after || $0.type == .finishedResult }
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                // Instructions
                Text("Select before and after photos to compare side-by-side")
                    .font(UFFont.caption(14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Comparison Area
                if let before = beforePhoto, let after = afterPhoto,
                   let beforeImg = UIImage(data: before.imageData),
                   let afterImg = UIImage(data: after.imageData) {
                    GeometryReader { geo in
                        ZStack {
                            // After image (full)
                            Image(uiImage: afterImg)
                                .resizable().scaledToFill()
                                .frame(width: geo.size.width, height: 280)
                                .clipped()

                            // Before image (clipped by slider)
                            Image(uiImage: beforeImg)
                                .resizable().scaledToFill()
                                .frame(width: geo.size.width, height: 280)
                                .clipped()
                                .mask(
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .frame(width: geo.size.width * sliderPosition)
                                        Spacer(minLength: 0)
                                    }
                                )

                            // Slider handle
                            HStack {
                                Spacer(minLength: geo.size.width * sliderPosition - 1)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 2, height: 280)
                                    .overlay(
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 32, height: 32)
                                                .shadow(radius: 4)
                                            HStack(spacing: 2) {
                                                Image(systemName: "chevron.left").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                            }
                                        }
                                    )
                                Spacer(minLength: 0)
                            }

                            // Labels
                            HStack {
                                Text("BEFORE")
                                    .font(UFFont.caption(11))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                                    .padding(8)
                                Spacer()
                                Text("AFTER")
                                    .font(UFFont.caption(11))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                                    .padding(8)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    let newPos = v.location.x / geo.size.width
                                    sliderPosition = min(max(newPos, 0.05), 0.95)
                                }
                        )
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Slider(value: $sliderPosition, in: 0.05...0.95)
                        .accentColor(UFColors.primary)
                        .padding(.horizontal, 20)

                } else {
                    // Placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Select photos to compare")
                                    .font(UFFont.caption(14))
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding(.horizontal, 20)
                }

                // Photo selectors
                HStack(spacing: 12) {
                    PhotoSelectorButton(
                        title: "Before Photo",
                        photo: beforePhoto,
                        action: { showBeforePicker = true }
                    )
                    PhotoSelectorButton(
                        title: "After Photo",
                        photo: afterPhoto,
                        action: { showAfterPicker = true }
                    )
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationTitle("Before / After")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBeforePicker) {
            PhotoPickerSheet(photos: beforePhotos) { photo in
                beforePhoto = photo
            }
        }
        .sheet(isPresented: $showAfterPicker) {
            PhotoPickerSheet(photos: afterPhotos) { photo in
                afterPhoto = photo
            }
        }
    }
}

struct PhotoSelectorButton: View {
    let title: String
    let photo: SitePhoto?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let p = photo, let img = UIImage(data: p.imageData) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(height: 80).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        )
                }
                Text(title)
                    .font(UFFont.caption(12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PhotoPickerSheet: View {
    let photos: [SitePhoto]
    let onSelect: (SitePhoto) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                if photos.isEmpty {
                    UFEmptyState(
                        icon: "photo.on.rectangle",
                        title: "No Photos Available",
                        subtitle: "Add photos to this site first"
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(photos) { photo in
                            Button {
                                onSelect(photo)
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                if let img = UIImage(data: photo.imageData) {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(height: 110).clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(UFColors.primary)
                }
            }
        }
    }
}

// MARK: - Documents List View
struct DocumentsListView: View {
    let siteId: UUID
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showNewDocument = false
    @State private var filterCategory: SiteDocument.DocumentCategory? = nil

    var filteredDocs: [SiteDocument] {
        let all = sitesVM.documents(for: siteId)
        if let cat = filterCategory { return all.filter { $0.category == cat } }
        return all
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: "All", isSelected: filterCategory == nil) { filterCategory = nil }
                        ForEach(SiteDocument.DocumentCategory.allCases, id: \.self) { cat in
                            FilterPill(title: cat.rawValue, isSelected: filterCategory == cat) {
                                filterCategory = filterCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                }

                if filteredDocs.isEmpty {
                    UFEmptyState(
                        icon: "doc.fill",
                        title: "No Documents",
                        subtitle: "Add contracts, plans and receipts to this site",
                        buttonTitle: "Add Document"
                    ) { showNewDocument = true }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredDocs) { doc in
                            DocumentCard(doc: doc)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        sitesVM.deleteDocument(doc)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                        }
                        Color.clear.frame(height: 80)
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNewDocument = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(UFColors.primary)
                }
            }
        }
        .sheet(isPresented: $showNewDocument) {
            NewDocumentView(siteId: siteId)
        }
    }
}

struct DocumentCard: View {
    let doc: SiteDocument

    var body: some View {
        UFCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(UFColors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: doc.category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(UFColors.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.title)
                        .font(UFFont.headline(14))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(doc.category.rawValue)
                        .font(UFFont.caption(12))
                        .foregroundColor(.secondary)
                    if !doc.notes.isEmpty {
                        Text(doc.notes)
                            .font(UFFont.caption(11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(DateFormatter.ufShort.string(from: doc.createdAt))
                        .font(UFFont.caption(11))
                        .foregroundColor(.secondary)
                    Text(doc.fileName)
                        .font(UFFont.mono(10))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Deliveries List View
struct DeliveriesListView: View {
    let siteId: UUID
    @EnvironmentObject var sitesVM: SitesViewModel
    @State private var showNewDelivery = false

    var deliveries: [Delivery] {
        sitesVM.deliveries(for: siteId)
    }

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                if deliveries.isEmpty {
                    UFEmptyState(
                        icon: "shippingbox",
                        title: "No Deliveries",
                        subtitle: "Log material deliveries to track what's arrived on site",
                        buttonTitle: "Log Delivery"
                    ) { showNewDelivery = true }
                } else {
                    List {
                        ForEach(deliveries) { delivery in
                            DeliveryCard(delivery: delivery)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        sitesVM.deleteDelivery(delivery)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                        }
                        Color.clear.frame(height: 80)
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Deliveries")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNewDelivery = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(UFColors.primary)
                }
            }
        }
        .sheet(isPresented: $showNewDelivery) {
            NewDeliveryView(siteId: siteId)
        }
    }
}

struct DeliveryCard: View {
    let delivery: Delivery

    var body: some View {
        UFCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(UFColors.info)
                        .padding(8)
                        .background(UFColors.info.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(delivery.supplier)
                            .font(UFFont.headline(14))
                            .foregroundColor(.primary)
                        Text(DateFormatter.ufDate.string(from: delivery.deliveryDate))
                            .font(UFFont.caption(12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: "Delivered", color: UFColors.success, small: true)
                }

                Text(delivery.items)
                    .font(UFFont.caption(13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill").font(.system(size: 10)).foregroundColor(.secondary)
                        Text("Accepted by \(delivery.acceptedBy)")
                            .font(UFFont.caption(11)).foregroundColor(.secondary)
                    }
                    Spacer()
                    if !delivery.notes.isEmpty {
                        Text(delivery.notes)
                            .font(UFFont.caption(11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
