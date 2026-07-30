import SwiftData
import SwiftUI

struct TripTaskListView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var newTaskTitle = ""
    @State private var newTaskPhase: TaskPhase = .beforeTrip
    @State private var taskPendingDelete: TripTask?

    private var sortedTasks: [TripTask] {
        trip.tasks.sorted { $0.orderIndex < $1.orderIndex }
    }

    private func tasks(in phase: TaskPhase) -> [TripTask] {
        sortedTasks.filter { $0.phase == phase }
    }

    var body: some View {
        List {
            ForEach(TaskPhase.allCases) { phase in
                let items = tasks(in: phase)
                if !items.isEmpty {
                    Section(phase.title) {
                        ForEach(items) { task in
                            Button {
                                toggle(task)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.isDone ? AppTheme.accent : .secondary)
                                    Text(task.title)
                                        .foregroundStyle(task.isDone ? .secondary : .primary)
                                    Spacer()
                                }
                                .opacity(task.isDone ? 0.55 : 1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("削除", role: .destructive) {
                                    taskPendingDelete = task
                                }
                            }
                        }
                    }
                }
            }

            Section {
                HStack {
                    TextField("タスクを追加", text: $newTaskTitle)
                    Picker("時期", selection: $newTaskPhase) {
                        ForEach(TaskPhase.allCases) { phase in
                            Text(phase.title).tag(phase)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    Button {
                        addTask()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("タスクを追加する")
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("追加")
            }

            if trip.tasks.isEmpty {
                Section {
                    Text("出張前後にやることをリストで管理できます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .contentMargins(.bottom, 90, for: .scrollContent)
        .navigationTitle("タスク")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "このタスクを削除しますか？",
            isPresented: Binding(
                get: { taskPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { taskPendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let task = taskPendingDelete {
                    modelContext.delete(task)
                }
                taskPendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                taskPendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func toggle(_ task: TripTask) {
        task.isDone.toggle()
        task.updatedAt = .now
        HapticsService.lightImpact()
        try? modelContext.save()
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let task = TripTask(trip: trip, title: title, phase: newTaskPhase, orderIndex: trip.tasks.count)
        trip.tasks.append(task)
        newTaskTitle = ""
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        TripTaskListView(trip: Trip(name: "Preview"))
    }
}
