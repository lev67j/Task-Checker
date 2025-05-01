//
//  ContentView.swift
//  Task Checker
//
//  Created by Lev Vlasov on 2025-04-30.
//

import SwiftUI
import CoreData
import BackgroundTasks
import ActivityKit

@main
struct Task_CheckerApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .background(Color(red: 0.92, green: 0.95, blue: 0.95))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                scheduleBackgroundTask()
            default:
                break
            }
        }
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourcompany.TaskChecker.timerUpdate", using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourcompany.TaskChecker.timerUpdate")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Schedule for 15 minutes later
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        scheduleBackgroundTask() // Schedule next task
        
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<Task_Model> = Task_Model.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timerState == %@", "running")
        
        do {
            let runningTasks = try context.fetch(fetchRequest)
            for task in runningTasks {
                if let startDate = task.timerStartDate {
                    task.timerDuration += Int64(Date().timeIntervalSince(startDate))
                    task.timerStartDate = Date()
                    task.lastSavedDate = Date()
                }
            }
            try context.save()
            
            // Update Dynamic Island for running tasks
            if let activeTask = runningTasks.first {
                Task {
                    await DynamicIslandManager.shared.updateDynamicIsland(
                        taskName: activeTask.name ?? "Task",
                        duration: activeTask.timerDuration
                    )
                }
            }
            
            task.setTaskCompleted(success: true)
        } catch {
            print("Background task error: \(error)")
            task.setTaskCompleted(success: false)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                   .tag(0)
                
                Text("Card View")
                    .tag(1)
                
                Text("Chart View")
                    .tag(2)
                
                Text("Settings View")
                    .tag(3)
            }
            
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Task_Model.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Task_Model.create_date, ascending: true)]
    ) private var tasks: FetchedResults<Task_Model>
    
    @State private var showingAddTaskSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header (not scroll)
                header
                
                // Day Progress (not scroll)
                day_progress
                
                // Task List (scroll)
                task_list
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    var header: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
            
            Text("Lev Vlasov")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            Image(systemName: "plus")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    var day_progress: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 1.0, green: 0.65, blue: 0.5))
            
            HStack {
                ZStack {
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 20))
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("49")
                            .foregroundColor(.black)
                            .font(.system(size: 32, weight: .bold))
                    }
                }
                
                Spacer(minLength: 30)
                
                ZStack {
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 20))
                    
                    VStack {
                        Text("Growth Time")
                            .font(.system(size: 17, weight: .bold))
                        
                        Text("10d 17h")
                            .font(.system(size: 20, weight: .bold))
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .frame(height: 100)
        .padding(.vertical, 10)
    }
    
    var task_list: some View {
        VStack(alignment: .leading, spacing: 20) {
            // All Task Section
            HStack {
                Text("All Targets")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button(action: {
                    showingAddTaskSheet = true
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray.opacity(0.2))
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .padding([.horizontal, .top])
            
            // Cells Task List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(tasks, id: \.self) { task in
                        TaskCellView(task: task)
                    }
                }
            }
        }
    }
}

struct TaskCellView: View {
    @ObservedObject var task: Task_Model
    @StateObject private var timerManager = TimerManager()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(task.name == "Netflix" ? Color(red: 0.7, green: 0.8, blue: 0.9) : Color(red: 1.0, green: 0.9, blue: 0.5))
                .frame(height: 60)
            
            HStack {
                Image(task.name ?? "")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .padding(.leading, 10)
                
                Text(task.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                Spacer()
                
                // Timer Display
                Text(timerManager.formattedTime(task.timerDuration))
                    .font(.system(size: 14, weight: .medium))
                    .padding(.trailing, 10)
                
                // Start/Stop Button
                Button(action: {
                    timerManager.toggleTimer(for: task)
                    saveTaskState()
                    updateDynamicIsland()
                }) {
                    Image(systemName: task.timerState == "running" ? "stop.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .background(Circle().fill(task.timerState == "running" ? .red : .green))
                }
                .padding(.trailing, 10)
            }
            .padding(.vertical, 5)
        }
        .padding(.horizontal)
        .onReceive(timerManager.timer) { _ in
            if task.timerState == "running" {
                task.timerDuration += 1
                saveTaskState()
                updateDynamicIsland()
            }
        }
        .onAppear {
            timerManager.initializeTimer(for: task)
        }
    }
    
    private func saveTaskState() {
        task.lastSavedDate = Date()
        do {
            try viewContext.save()
        } catch {
            print("Error saving task state: \(error)")
        }
    }
    
    private func updateDynamicIsland() {
        if task.timerState == "running" {
            Task {
                await DynamicIslandManager.shared.updateDynamicIsland(
                    taskName: task.name ?? "Task",
                    duration: task.timerDuration
                )
            }
        } else {
            Task {
                await DynamicIslandManager.shared.endDynamicIsland()
            }
        }
    }
}

class TimerManager: ObservableObject {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    func formattedTime(_ seconds: Int64) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func toggleTimer(for task: Task_Model) {
        if task.timerState == "running" {
            task.timerState = "stopped"
            task.timerStartDate = nil
        } else {
            task.timerState = "running"
            task.timerStartDate = Date()
        }
    }
    
    func initializeTimer(for task: Task_Model) {
        if task.timerState == "running", let startDate = task.timerStartDate {
            let elapsed = Int64(Date().timeIntervalSince(startDate))
            task.timerDuration += elapsed
            task.timerStartDate = Date()
        }
    }
}

class DynamicIslandManager {
    static let shared = DynamicIslandManager()
    private var currentActivity: Activity<TaskActivityAttributes>?
    
    private init() {}
    
    func updateDynamicIsland(taskName: String, duration: Int64) async {
        let attributes = TaskActivityAttributes(taskName: taskName)
        let contentState = TaskActivityAttributes.ContentState(duration: duration)
        
        do {
            if currentActivity == nil {
                currentActivity = try Activity<TaskActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            } else {
                await currentActivity?.update(using: contentState)
            }
        } catch {
            print("Error updating Dynamic Island: \(error)")
        }
    }
    
    func endDynamicIsland() async {
        await currentActivity?.end(using: nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}

struct TaskActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var duration: Int64
    }
    
    var taskName: String
}

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Target")) {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("Add Target")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        saveTask()
                        dismiss()
                    }) {
                        Text("Create")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    private func saveTask() {
        let newTask = Task_Model(context: viewContext)
        newTask.name = name
        newTask.create_date = Date()
        newTask.timerDuration = 0
        newTask.timerState = "stopped"
        newTask.lastSavedDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving target: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Добавляем тестовые данные
        let task1 = Task_Model(context: viewContext)
        task1.name = "Netflix"
        task1.create_date = Date()
        
        let task2 = Task_Model(context: viewContext)
        task2.name = "Spotify"
        task2.create_date = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Task_Checker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
