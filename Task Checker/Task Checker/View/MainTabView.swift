//
//  ContentView.swift
//  Task Checker
//
//  Created by Lev Vlasov on 2025-04-30.
//

import SwiftUI
import CoreData

@main
struct Task_CheckerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .background(Color(red: 0.92, green: 0.95, blue: 0.95))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
    let task: Task_Model
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(task.name == "Netflix" ? Color(red: 0.7, green: 0.8, blue: 0.9) : Color(red: 1.0, green: 0.9, blue: 0.5))
                .frame(height: 60)
            
            HStack {
                // Icon
                Image(task.name ?? "")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .padding(.leading, 10)
                
                // Name
                Text(task.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                Spacer()
            }
            .padding(.vertical, 5)
        }
        .padding(.horizontal)
    }
}


// Sheet для добавления новой задачи
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
