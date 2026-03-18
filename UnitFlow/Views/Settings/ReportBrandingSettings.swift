import SwiftUI
import PhotosUI

struct ReportBrandingSettings: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @State private var companyName: String      = ""
    @State private var footerText: String       = ""
    @State private var accentColorHex: String   = "#1E40AF"
    @State private var showPoweredBy: Bool      = true
    @State private var logoData: Data?          = nil

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showSavedToast = false
    @State private var showColorPicker = false

    // Preset accent colours for the picker
    private let presetColors: [String] = [
        "#1E40AF", "#0891B2", "#047857", "#7C3AED",
        "#DC2626", "#D97706", "#FF6B35", "#374151"
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Logo
                    FormSection(title: "Company Logo") {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 72, height: 72)
                                if let data = logoData, let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: accentColorHex))
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Text("Upload Logo")
                                        .font(UFFont.headline(14))
                                        .foregroundColor(UFColors.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(UFColors.primary.opacity(0.1))
                                        .clipShape(Capsule())
                                }

                                if logoData != nil {
                                    Button("Remove") {
                                        logoData = nil
                                    }
                                    .font(UFFont.caption(12))
                                    .foregroundColor(UFColors.danger)
                                }
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Company name
                    FormSection(title: "Company Name") {
                        UFTextField(icon: "building.2", placeholder: "Your company name", text: $companyName)
                    }

                    // Accent colour
                    FormSection(title: "Accent Color") {
                        VStack(spacing: 12) {
                            // Preset swatches
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(presetColors, id: \.self) { hex in
                                    Button {
                                        accentColorHex = hex
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 34, height: 34)
                                            if accentColorHex == hex {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }

                            // Hex input
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: accentColorHex))
                                    .frame(width: 28, height: 28)
                                TextField("Hex color e.g. #1E40AF", text: $accentColorHex)
                                    .font(UFFont.mono(14))
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Footer text
                    FormSection(title: "Footer Text") {
                        UFTextField(
                            icon: "text.alignleft",
                            placeholder: "Confidential — for client use only",
                            text: $footerText
                        )
                    }

                    // Toggles
                    FormSection(title: "Options") {
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 14))
                                .foregroundColor(UFColors.primary)
                                .frame(width: 24)
                            Text("Show \"Powered by Site Flow\"")
                                .font(UFFont.body(14))
                            Spacer()
                            Toggle("", isOn: $showPoweredBy)
                                .labelsHidden()
                                .tint(UFColors.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Preview card
                    FormSection(title: "Preview") {
                        HStack(spacing: 12) {
                            if let data = logoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(companyName.isEmpty ? "Your Company" : companyName)
                                    .font(UFFont.headline(14))
                                Text("Site Progress Report")
                                    .font(UFFont.caption(12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: accentColorHex))
                                .frame(width: 24, height: 24)
                        }
                        .padding(14)
                        .background(colorScheme == .dark ? Color(hex: "#2A2A3E") : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: accentColorHex).opacity(0.4), lineWidth: 1.5)
                        )
                    }

                    // Save button
                    Button {
                        saveBranding()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Branding")
                                .font(UFFont.headline(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(UFColors.gradientOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 4)

                    Color.clear.frame(height: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Report Branding")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadBranding() }
        .onChange(of: selectedPhoto) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    logoData = data
                }
            }
        }
        .overlay(
            Group {
                if showSavedToast {
                    ConfirmationToast(message: "Branding saved!")
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            },
            alignment: .bottom
        )
    }

    private func loadBranding() {
        let b = ReportBranding.load()
        companyName    = b.companyName
        footerText     = b.footerText
        accentColorHex = b.accentColorHex
        showPoweredBy  = b.showPoweredBy
        logoData       = b.logoData
    }

    private func saveBranding() {
        let b = ReportBranding(
            companyName:    companyName,
            accentColorHex: accentColorHex,
            footerText:     footerText,
            showPoweredBy:  showPoweredBy,
            logoData:       logoData
        )
        b.save()
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedToast = false }
        }
    }
}
