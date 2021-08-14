# IC-Compiler-Block-Level-Implementation

# *Overview*
In this hands-on workshop, I learn to use IC Compiler to perform placement, clock tree synthesis (CTS), routing, and design-for-manufacturability (DFM) on non-UPF block-level designs with an existing floorplan. The covered flows are aimed at achieving design closure for designs with moderate congestion, and multi-corner multi-mode (MCMM) timing and power challenges.

*Day 1:* introduces the GUI, then covers data setup for concurrent MCMM optimization, including on-chip variation (OCV) effects, followed by a high-level overview of floorplanning.

*Day 2:* The Placement Unit covers; control setup, placement with recommended optimizations, and incremental post-placement optimization. The CTS Unit covers; control setup, clock tree synthesis, post-CTS optimizations, and clock tree analysis.

*Day 3:*  The Routing Unit covers; control setup, clock and signal routing, post-route optimization, DRC fixing, and functional ECOs. The workshop concludes with DFM and data generation for final validation.

The workshop is based on Synopsys' Reference Methodology (RM) flow. Every lecture is accompanied by a comprehensive hands-on lab.
 
 
# *Objectives*
At the end of this workshop you should be able to use IC Compiler to:

Use the GUI to analyze the layout during the various design phases

Perform and debug data setup to create an initial design cell which is ready for design planning and placement; This includes loading required files and libraries, creating a Milkyway design library, and applying common timing and optimization controls

Create scenarios for concurrent MCMM optimization during placement, CTS, and routing

Account for on-chip variation during timing analysis and optimization

Apply timing and optimization controls which apply to the entire P&R flow

Describe some key block-level floorplanning steps

Perform pre-placement control setup and checks

Perform setup for integrated clock-gating (ICG) cell optimization

Perform concurrent MCMM standard cell placement and related optimizations to minimize timing violations, congestion, and power; Includes magnet placement, inserting spare cells, creating move bounds, and placement-aware clock gating

Perform incremental post-placement optimizations to improve congestion and timing

Analyze congestion maps and timing reports

Apply pre-CTS setup steps to define CTS scenarios, constraints/targets, controls and NDR rules

Execute the recommend clock tree synthesis and optimization flow to build a skew-balanced clock tree network

Perform post-CTS logic optimization, including hold time fixing

Invoke incremental CTS and logic optimization techniques as needed

Analyze clock tree and timing results post-CTS

Perform routing setup to control DRC fixing, delay calculation, via optimization, antenna fixing, and crosstalk reduction

Route the clock nets

Route the signal nets and perform post-route optimization

Analyze and fix physical DRC violations, using IC Validator from within IC Compiler

Perform functional ECOs

Execute design-for-manufacturability steps to improve yield and reliability, including diode insertion, filler cell insertion, incremental via optimization, and signoff metal 

filling using IC Validator

Generate output files required for final validation/verification

Convert the completed block-level design into a soft macro
 
# *Course Outline*

*Day 1*

Workshop Introduction & GUI (Lecture + Lab + Optional Lab)
MCMM Data Setup (Lecture + Lab)
Overview of Floorplanning (Lecture)

![Placement](https://user-images.githubusercontent.com/58098260/128783109-3ac2d543-aad2-4199-9d14-9c0ca5b04c9f.jpeg)

*Day 2*

Overview of Floorplanning (Lab)
Placement (Lecture + Lab)
Clock Tree Synthesis (Lecture)

![Block_implematation](https://user-images.githubusercontent.com/58098260/129451309-a8e123fb-7242-40d8-87e7-81c9047090ff.png)

*Day 3*

Clock Tree Synthesis (Lecture + Lab)
Routing (Lecture + Lab)
Design for Manufacturability (Lecture + Optional Lab)
Customer Support (Lecture)
 
# *Synopsys Tools Used*
*IC Compiler - Version 2016.03-SP1*
