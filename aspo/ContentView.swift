//
//  ContentView.swift
//  aspo
//
//  Created by kurt on 10.12.24.
//

import SwiftUI

//I have no fucking idea what I am doing, but this supposedly updates the overlay
class SensorViewModel: ObservableObject {
    @Published var cpuTemperature: Double = 0.0
    @Published var cpuVoltage: Double = 0.0
    @Published var cpuCurrent: Double = 0.0

    @Published var gpuTemperature: Double = 0.0
    @Published var gpuVoltage: Double = 0.0
    @Published var gpuCurrent: Double = 0.0

    @Published var ramTemperature: Double = 0.0
    @Published var ramVoltage: Double = 0.0
    @Published var ramCurrent: Double = 0.0

    private var timer: Timer?

    init() {
        startUpdating()
    }

    deinit {
        timer?.invalidate()
    }

    func startUpdating(interval: TimeInterval = 5.0) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateSensorData()
        }
    }

    private func updateSensorData() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Call Objective-C functions and update properties
            let cpuTemp = getCPUThermal()
            let cpuVolt = getCPUVoltage()
            let cpuCurr = getCPUCurrent()
            
            let gpuTemp = getGPUThermal()
            let gpuVolt = getGPUVoltage()
            let gpuCurr = getGPUCurrent()
            
            let ramTemp = getRAMThermal()
            let ramVolt = getRAMVoltage()
            let ramCurr = getRAMCurrent()
            
            DispatchQueue.main.async {
                // Update published properties to trigger UI updates
                self.cpuTemperature = cpuTemp
                self.cpuVoltage = cpuVolt
                self.cpuCurrent = cpuCurr

                self.gpuTemperature = gpuTemp
                self.gpuVoltage = gpuVolt
                self.gpuCurrent = gpuCurr

                self.ramTemperature = ramTemp
                self.ramVoltage = ramVolt
                self.ramCurrent = ramCurr
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = SensorViewModel()
    
    var body: some View {
        HStack {
            Image(systemName: "cpu")
                .font(.largeTitle)
            Text("CPU")
                .font(.largeTitle)
                .bold()
        }
        VStack {
            Text("Temperature: \(viewModel.cpuTemperature, specifier: "%.2f")°C")
            Text("Voltage: \(viewModel.cpuVoltage, specifier: "%.2f") V")
            Text("Current: \(viewModel.cpuCurrent, specifier: "%.2f") A")
        }
        HStack {
            Image(systemName: "cpu")
                .font(.largeTitle)
            Text("GPU")
                .font(.largeTitle)
                .bold()
        }
        VStack {
            Text("Temperature: \(viewModel.gpuTemperature, specifier: "%.2f")°C")
            Text("Voltage: \(viewModel.gpuVoltage, specifier: "%.2f") V")
            Text("Current: \(viewModel.gpuCurrent, specifier: "%.2f") A")
        }
        HStack {
            Image(systemName: "memorychip")
                .font(.largeTitle)
            Text("RAM")
                .font(.largeTitle)
                .bold()
        }
        VStack {
            Text("Temperature: \(viewModel.ramTemperature, specifier: "%.2f")°C")
            Text("Voltage: \(viewModel.ramVoltage, specifier: "%.2f") V")
            Text("Current: \(viewModel.ramCurrent, specifier: "%.2f") A")
        }
    }
}

var timer = Timer()

#Preview {
    ContentView()
}
