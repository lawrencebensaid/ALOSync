//
//  StatusView.swift
//  StatusView
//
//  Created by Lawrence Bensaid on 11/09/2021.
//

import SwiftUI

struct StatusView: View {
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var fails = 0
    @State private var updating = false
    @State private var status: ALOStatus?
    
    init() { }
    
    init(status: ALOStatus?) {
        _status = State(initialValue: status)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Status")
                    .font(.title)
                Spacer()
            }
            if let status = status {
                Text("\(status.message)")
                Text("Version: \(status.version)")
                if let orchestrator = status.orchestrator {
                    Text("Orchestrator")
                        .font(.title)
                        .padding(.top)
                    HStack {
                        Text("\(orchestrator.message)")
                        Spacer()
                        Text(orchestrator.status.rawValue.capitalized)
                            .foregroundColor(orchestrator.status.color)
                    }
                    Text("Tasks")
                        .font(.title2)
                        .padding(.top)
                    if orchestrator.tasks.count > 0 {
                        VStack(spacing: 8) {
                            let tasks = orchestrator.tasks.sorted { $0.status.rawValue > $1.status.rawValue }
                            ForEach(tasks) { task in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(task.task)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(task.status.color)
                                    HStack(alignment: .bottom) {
                                        if let progress = task.progress {
                                            Text("\(task.status.rawValue) (\(String(format: "%.2f", progress * 100))%)".capitalized)
                                                .font(.system(size: 12))
                                        }
                                        Spacer()
                                        Text("Started \(task.startedAt)")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(.systemGray))
                                    }
                                    if let progress = task.progress {
                                        ProgressView(value: progress, total: 1)
                                    }
                                }
                                .help(task.message ?? "")
                            }
                        }
                    } else {
                        Text("Currently no tasks are running")
                            .italic()
                            .foregroundColor(Color(.systemGray))
                    }
                    Text("Jobs")
                        .font(.title2)
                        .padding(.top)
                    if orchestrator.jobs.count > 0 {
                        ForEach(orchestrator.jobs.sorted(by: { $0.name.compare($1.name) == .orderedAscending })) { job in
                            VStack(alignment: .leading) {
                                Text(job.name)
                                    .bold()
                                Text(job.message ?? "")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(.systemGray))
                            }
                            .padding(.leading, 4)
                        }
                    } else {
                        Text("Job history unavailable")
                            .italic()
                            .foregroundColor(Color(.systemGray))
                    }
                }
            } else if fails > 1 {
                Text("Service unreachable")
            } else {
                ProgressView()
            }
        }
        .padding()
        .onAppear { update() }
        .onReceive(timer) { _ in update(animate: true) }
        .frame(minWidth: 350)
    }
    
    private func update(animate: Bool = false) {
        guard updating == false else { return }
        let request = URLRequest(url: URL(string: UserDefaults.standard.string(forKey: "mirrorHost") ?? "")!)
        updating = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                updating = false
                if let error = error {
                    fails += 1
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else { return }
                let status = try? JSONDecoder().decode(ALOStatus.self, from: data)
                fails = 0
                if animate {
                    withAnimation(.spring()) { self.status = status }
                } else {
                    self.status = status
                }
            }
        }.resume()
    }
    
}

struct StatusView_Previews: PreviewProvider {
    
    static var previews: some View {
        StatusView(status: .preview)
    }
    
}

