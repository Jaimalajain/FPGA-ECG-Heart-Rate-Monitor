# ❤️ FPGA-Based ECG Heart Rate Monitor

A real-time ECG Heart Rate Monitoring System designed in Verilog HDL that detects R-peaks from ECG signals and calculates Beats Per Minute (BPM) using digital hardware logic.

This project demonstrates practical FPGA design concepts including signal processing, edge detection, timing analysis, counters, state-based control, and hardware-oriented arithmetic.

---

## 🚀 Project Highlights

✔ ECG R-Peak Detection

✔ Real-Time BPM Calculation

✔ Refractory Period Protection

✔ Synthesizable Verilog HDL Design

✔ Vivado Simulation Verified

✔ FPGA Deployment Ready

---

## 🏗️ System Architecture

```text
ECG Samples
     │
     ▼
┌────────────────┐
│ Peak Detector  │
└────────────────┘
         │
         ▼
    beat_pulse
         │
         ▼
┌────────────────┐
│ BPM Calculator │
└────────────────┘
         │
         ▼
      BPM Output
```

---

## 📂 Project Structure

```text
FPGA-ECG-Heart-Rate-Monitor
│
├── heart_rate_top.v
├── peak_detector.v
├── bpm_calculator.v
├── tb_heart_monitor.v
│
└── Simulation Waveforms
```

---

## ⚙️ Design Methodology

### Peak Detection

The R-wave is identified using threshold crossing logic.

```verilog
(adc_prev <= THRESHOLD) &&
(adc_raw > THRESHOLD)
```

A beat is registered only when the ECG signal crosses the threshold from below.

---

### Refractory Period

To prevent multiple detections from a single heartbeat, a refractory timer is introduced.

This ensures:

- Noise immunity
- Single beat registration
- Stable BPM calculation

---

### BPM Calculation

Heart Rate is computed using the measured RR interval.

```text
BPM = (60 × Clock Frequency) / RR Interval
```

The implementation uses integer arithmetic for FPGA compatibility.

---

## 📈 Simulation Results

The ECG waveform was modeled using a simplified P-QRS-T morphology.

The design was verified for:

| Target BPM | Result |
|------------|---------|
| 60 BPM | ✅ PASS |
| 75 BPM | ✅ PASS |
| 90 BPM | ✅ PASS |

Observed outputs:

| Hex | BPM |
|------|------|
| 3C | 60 |
| 4B | 75 |
| 5A | 90 |

---

## 🔬 Verification

Simulation performed using:

- Xilinx Vivado Simulator
- Behavioral Simulation
- Functional Verification

Waveforms confirmed:

- Accurate R-Peak Detection
- Correct Beat Pulse Generation
- Proper BPM Calculation

---

## 🛠 Technologies Used

- Verilog HDL
- FPGA Design Flow
- Digital Logic Design
- Xilinx Vivado
- RTL Design & Verification

---

## 🌱 Future Enhancements

- Adaptive Threshold Detection
- Digital ECG Filtering
- Heart Rate Variability (HRV)
- Arrhythmia Detection
- UART Communication Interface
- Real ECG Sensor Integration

---

## 👩‍💻 Author

### Jaimala Jain

B.Tech Electronics & Communication Engineering

Interested in:
- VLSI Design
- Physical Design
- RTL Design
- FPGA Development
- Semiconductor Engineering

---

⭐ If you found this project interesting, feel free to star the repository.
