// =============================================================================
// Module      : tb_heart_monitor
// Description : Behavioural testbench for heart_rate_top.
//               Simulates realistic ECG P-QRS-T waveforms at three fixed rates:
//                 - 60  BPM  → R-R interval = 100,000,000 cycles (1.000 s)
//                 - 75  BPM  → R-R interval =  80,000,000 cycles (0.800 s)
//                 - 90  BPM  → R-R interval =  66,666,667 cycles (0.667 s)
//
//               The ECG pattern is injected sample-by-sample with a controlled
//               inter-sample delay, which sets the actual heart rate.
//
//               Expected BPM outputs (after 2nd beat):
//                 60 BPM  → bpm = 8'd60
//                 75 BPM  → bpm = 8'd75
//                 90 BPM  → bpm = 8'd90  (±1 due to integer rounding)
//
// Usage       : Simulate in Vivado Simulator or ModelSim.
//               Run for at least 8 seconds of simulated time to see all phases.
// =============================================================================

`timescale 1ns / 1ps

module tb_heart_monitor();

    // =========================================================================
    // DUT Signals
    // =========================================================================
    reg         clk;
    reg         rst;
    reg  [11:0] adc_raw;
    wire [7:0]  bpm;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    heart_rate_top #(
        .CLK_FREQ          (100_000_000),
        .THRESHOLD         (12'h800),
        .REFRACTORY_CYCLES ( 300_000),
        .BPM_MIN           (8'd40),
        .BPM_MAX           (8'd180)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .adc_raw (adc_raw),
        .bpm     (bpm)
    );

    // =========================================================================
    // Clock Generation: 100 MHz → period = 10 ns → half-period = 5 ns
    // =========================================================================
    initial clk = 1'b0;
    always  #5 clk = ~clk;   // Toggle every 5 ns

    // =========================================================================
    // ECG Waveform Memory: 11-sample P-QRS-T morphology (normalised to 12-bit)
    //
    // Index  Hex    Decimal  Waveform Region
    // -----  -----  -------  ---------------
    //   0    0x200   512     Isoelectric baseline
    //   1    0x220   544     P-wave onset (atrial depolarisation)
    //   2    0x280   640     P-wave peak
    //   3    0x220   544     P-wave descent
    //   4    0x1E0   480     PR segment (slight dip)
    //   5    0xFFF  4095     R-peak (ventricular depolarisation - maximum!)
    //   6    0x100   256     S-wave (post-R dip below baseline)
    //   7    0x200   512     ST segment return to baseline
    //   8    0x280   640     T-wave peak (ventricular repolarisation)
    //   9    0x220   544     T-wave descent
    //  10    0x200   512     Return to isoelectric baseline
    //
    // Note: Only index 5 (0xFFF) crosses the 0x800 threshold → one beat/cycle.
    // =========================================================================
    reg [11:0] ecg_mem [0:10];

    initial begin
        ecg_mem[0]  = 12'h200;   // Baseline
        ecg_mem[1]  = 12'h220;   // P-wave onset
        ecg_mem[2]  = 12'h280;   // P-wave peak
        ecg_mem[3]  = 12'h220;   // P-wave descent
        ecg_mem[4]  = 12'h1E0;   // PR segment
        ecg_mem[5]  = 12'hFFF;   // *** R-PEAK - triggers beat_pulse ***
        ecg_mem[6]  = 12'h100;   // S-wave
        ecg_mem[7]  = 12'h200;   // ST segment
        ecg_mem[8]  = 12'h280;   // T-wave peak
        ecg_mem[9]  = 12'h220;   // T-wave descent
        ecg_mem[10] = 12'h200;   // Return to baseline
    end

    // =========================================================================
    // Task: inject_ecg_beats
    //   Injects 'num_beats' complete P-QRS-T cycles at a rate set by rr_cycles.
    //   rr_cycles = R-R interval in clock cycles = sets the heart rate.
    //
    //   Inter-sample delay = rr_cycles / 11 (11 samples per beat).
    //   This evenly distributes samples across one cardiac cycle.
    //
    //   Parameters:
    //     num_beats  : how many complete beats to inject
    //     rr_cycles  : R-R interval in clock cycles
    //     label      : string label printed in $display for the test phase
    // =========================================================================
    task inject_ecg_beats;
        input integer num_beats;
        input integer rr_cycles;
        input [63:0]  bpm_expected;

        integer beat_idx;
        integer sample_idx;
        integer sample_delay;   // cycles between samples = rr_cycles / 11
        integer delay_count;

        begin
            sample_delay = rr_cycles / 11;   // Integer divide - acceptable approximation

            $display("─────────────────────────────────────────────────────────");
            $display("[TB] Phase start | Expected BPM = %0d | RR = %0d cycles | Sample delay = %0d cycles",
                      bpm_expected, rr_cycles, sample_delay);
            $display("─────────────────────────────────────────────────────────");

            for (beat_idx = 0; beat_idx < num_beats; beat_idx = beat_idx + 1) begin
                // Drive each of the 11 samples with the correct inter-sample gap
                for (sample_idx = 0; sample_idx <= 10; sample_idx = sample_idx + 1) begin
                    @(posedge clk);
                    adc_raw = ecg_mem[sample_idx];    // Drive new sample

                    // Wait sample_delay cycles before the next sample
                    repeat (sample_delay - 1) @(posedge clk);
                end

                // After 2nd beat, BPM output should stabilise - print it
                if (beat_idx >= 1) begin
                    $display("[TB] Beat %0d complete | BPM output = %0d | Expected = %0d | %s",
                              beat_idx + 1, bpm, bpm_expected,
                              (bpm == bpm_expected) ? "PASS ✓" : "MISMATCH ✗");
                end
            end

            // Return adc to baseline between test phases
            adc_raw = 12'h200;
            // Allow refractory period to expire before next phase
            repeat (350_000) @(posedge clk);   // 350 ms gap
        end
    endtask

    // =========================================================================
    // Main Stimulus
    // =========================================================================
    initial begin
        // VCD waveform dump (for GTKWave or Vivado waveform viewer)
        $dumpfile("tb_heart_monitor.vcd");
        $dumpvars(0, tb_heart_monitor);

        // ----- Reset -------------------------------------------------------
        rst     = 1'b1;
        adc_raw = 12'h200;
        repeat (20) @(posedge clk);   // Hold reset for 20 cycles
        rst = 1'b0;
        repeat (10) @(posedge clk);   // Short post-reset settle
        $display("[TB] Reset released at time %0t ns", $time);

        // =================================================================
        // TEST PHASE 1: 60 BPM
        //   RR interval = (60 s / 60 beats) * 100 MHz = 100,000,000 cycles
        // =================================================================
        inject_ecg_beats(
    .num_beats   (3),
    .rr_cycles   (1_000_000),
    .bpm_expected(64'd60)
);

        // =================================================================
        // TEST PHASE 2: 75 BPM
        //   RR interval = (60 s / 75 beats) * 100 MHz = 80,000,000 cycles
        // =================================================================
     inject_ecg_beats(
    .num_beats   (3),
    .rr_cycles   (800_000),
    .bpm_expected(64'd75)
);

        // =================================================================
        // TEST PHASE 3: 90 BPM
        //   RR interval = (60 s / 90 beats) * 100 MHz = 66,666,667 cycles
        //   Integer rounding → bpm_raw = 6,000,000 / 66,666 = 90 ✓
        // =================================================================
        inject_ecg_beats(
    .num_beats   (3),
    .rr_cycles   (666_667),
    .bpm_expected(64'd90)
);
        $display("─────────────────────────────────────────────────────────");
        $display("[TB] All test phases complete. Simulation finished.");
        $display("─────────────────────────────────────────────────────────");
        $finish;
    end

    // =========================================================================
    // Beat Pulse Monitor: Logs every beat_pulse for verification
    // =========================================================================
    wire beat_pulse_mon;
    assign beat_pulse_mon = dut.beat_pulse;

    always @(posedge clk) begin
        if (beat_pulse_mon) begin
            $display("[TB] beat_pulse detected at t=%0t ns | adc_raw=0x%03X",
                      $time, adc_raw);
        end
    end
always @(posedge clk) begin
    if (beat_pulse_mon) begin
        $display("Beat detected | rr_counter=%0d | bpm=%0d | time=%0t",
                  dut.u_bpm_calculator.rr_counter,
                  bpm,
                  $time);
    end
end
    // =========================================================================
    // BPM Change Monitor: Logs whenever BPM output changes
    // =========================================================================
    reg [7:0] bpm_prev = 8'd0;
    always @(posedge clk) begin
        if (bpm !== bpm_prev) begin
            $display("[TB] BPM updated: %0d → %0d at t=%0t ns", bpm_prev, bpm, $time);
            bpm_prev <= bpm;
        end
    end

    // =========================================================================
    // Timeout Watchdog: Kills simulation if it runs too long (safety net)
    // =========================================================================
    initial begin
      #200_000_000;
        $display("[TB] TIMEOUT: Simulation exceeded 8.5 s. Forcing finish.");
        $finish;
    end

endmodule
