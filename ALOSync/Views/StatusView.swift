//
//  StatusView.swift
//  StatusView
//
//  Created by Lawrence Bensaid on 11/09/2021.
//

import SwiftUI

struct StatusView: View {
    
    @State private var updating = false
    @State private var listening = false
    @State public var status: ALOStatus?
    
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
                                    Text(task.id)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(task.status.color)
                                    HStack(alignment: .bottom) {
                                        if let progress = task.progress {
                                            Text("\(task.status.rawValue) (\(String(format: "%.2f", progress * 100))%)".capitalized)
                                                .font(.system(size: 12))
                                        }
                                        Spacer()
                                        if let date = task.startedAt {
                                            Text("Started \(date, formatter: .relative())")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(.systemGray))
                                        }
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
                        ForEach(orchestrator.jobs.sorted(by: { $0.id.compare($1.id) == .orderedAscending })) { job in
                            VStack(alignment: .leading) {
                                Text(job.id)
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
            } else {
                ProgressView()
            }
        }
        .padding()
        .onAppear {
            update()
            listen()
        }
        .onDisappear {
            listening = false
        }
        .frame(minWidth: 350)
    }
    
    private func listen() {
        let urlSession = URLSession(configuration: .default)
        let task = urlSession.webSocketTask(with: ALO.standard.wsBaseUrl)
        task.resume()
        self.listening = true
        receive(task)
    }
    
    private func receive(_ task: URLSessionWebSocketTask) {
        task.receive { result in
            guard listening else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let update = try? JSONDecoder().decode(ALOOrchestrator.self, from: data) {
                        var status = self.status
                        status?.orchestrator = update
                        withAnimation(.spring()) {
                            self.status = status
                        }
                    }
                    break
                default: break
                }
                receive(task)
            case .failure(let error):
                print("Error when receiving \(error.localizedDescription)")
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
                    receive(task)
                }
            }
        }
    }

    private func update(animate: Bool = false) {
        guard updating == false else { return }
        let request = URLRequest(url: URL(string: "\(ALO.standard.base)?dataOnly=1")!)
        updating = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                updating = false
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                guard let data = data else { return }
                let status = try? JSONDecoder().decode(ALOStatus.self, from: data)
                self.status = status
            }
        }.resume()
    }
    
}

struct StatusView_Previews: PreviewProvider {
    
    static var previews: some View {
        StatusView()
    }
    
}

