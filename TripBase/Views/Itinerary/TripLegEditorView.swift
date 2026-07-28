import SwiftData
import SwiftUI

struct TripLegEditorView: View {
    let trip: Trip
    let existingLeg: TripLeg?
    let nextOrderIndex: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var countryCode: String
    @State private var cityName: String
    @State private var arrivalDate: Date
    @State private var departureDate: Date
    @State private var hotelName: String
    @State private var hotelAddress: String
    @State private var hotelBookingReference: String
    @State private var hotelNotes: String
    @State private var visaStatus: VisaStatus
    @State private var visaNotes: String
    @State private var transportNote: String
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented = false

    init(trip: Trip, existingLeg: TripLeg?, nextOrderIndex: Int) {
        self.trip = trip
        self.existingLeg = existingLeg
        self.nextOrderIndex = nextOrderIndex

        _countryCode = State(initialValue: existingLeg?.countryCode ?? "")
        _cityName = State(initialValue: existingLeg?.cityName ?? "")
        _arrivalDate = State(initialValue: existingLeg?.arrivalDate ?? .now)
        _departureDate = State(initialValue: existingLeg?.departureDate ?? .now)
        _hotelName = State(initialValue: existingLeg?.hotelName ?? "")
        _hotelAddress = State(initialValue: existingLeg?.hotelAddress ?? "")
        _hotelBookingReference = State(initialValue: existingLeg?.hotelBookingReference ?? "")
        _hotelNotes = State(initialValue: existingLeg?.hotelNotes ?? "")
        _visaStatus = State(initialValue: existingLeg?.visaStatus ?? .notRequired)
        _visaNotes = State(initialValue: existingLeg?.visaNotes ?? "")
        _transportNote = State(initialValue: existingLeg?.transportNote ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("目的地") {
                    TextField("都市名（必須）", text: $cityName)
                        .accessibilityIdentifier("leg.city")
                    TextField("国コード（例: JP, US, FR）", text: $countryCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("leg.countryCode")
                    DatePicker("到着日", selection: $arrivalDate, displayedComponents: .date)
                    DatePicker("出発日", selection: $departureDate, displayedComponents: .date)
                }

                Section("宿泊") {
                    TextField("ホテル名", text: $hotelName)
                    TextField("住所", text: $hotelAddress, axis: .vertical)
                    TextField("予約番号", text: $hotelBookingReference)
                    TextField("メモ", text: $hotelNotes, axis: .vertical)
                }

                Section("ビザ") {
                    Picker("状況", selection: $visaStatus) {
                        ForEach(VisaStatus.allCases) { status in
                            Label(status.title, systemImage: status.systemImage).tag(status)
                        }
                    }
                    TextField("メモ", text: $visaNotes, axis: .vertical)
                }

                Section("移動") {
                    TextField("フライト・新幹線などの予定（メモ）", text: $transportNote, axis: .vertical)
                }

                Section {
                    Button(existingLeg == nil ? "追加する" : "変更を保存", action: save)
                        .accessibilityIdentifier("leg.save")
                        .buttonStyle(LargeActionButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .disabled(isSaveDisabled)
                }

                if existingLeg != nil {
                    Section {
                        Button("この行程を削除", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(AppTheme.danger) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existingLeg == nil ? "行程を追加" : "行程を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("この行程を削除しますか？", isPresented: $isDeleteConfirmationPresented) {
                Button("削除", role: .destructive, action: deleteLeg)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("削除した内容は元に戻せません。")
            }
        }
    }

    private var isSaveDisabled: Bool {
        cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || countryCode.trimmingCharacters(in: .whitespacesAndNewlines).count != 2
    }

    private func save() {
        let leg = existingLeg ?? TripLeg(
            countryCode: "",
            cityName: "",
            arrivalDate: arrivalDate,
            departureDate: departureDate,
            orderIndex: nextOrderIndex,
            trip: trip
        )
        leg.countryCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        leg.cityName = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.arrivalDate = arrivalDate
        leg.departureDate = max(departureDate, arrivalDate)
        leg.hotelName = hotelName.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.hotelAddress = hotelAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.hotelBookingReference = hotelBookingReference.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.hotelNotes = hotelNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.visaStatus = visaStatus
        leg.visaNotes = visaNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.transportNote = transportNote.trimmingCharacters(in: .whitespacesAndNewlines)
        leg.updatedAt = .now

        if existingLeg == nil {
            trip.legs.append(leg)
        }
        trip.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteLeg() {
        guard let existingLeg else { return }
        trip.legs.removeAll(where: { $0 === existingLeg })
        modelContext.delete(existingLeg)
        trip.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
