# ASIC Flow – SDRAM Controller RTL-to-GDSII Implementation

> **Project:** SDRAM Controller ASIC  
> **Document:** ASIC Implementation Flow  
> **Version:** 1.0  
> **Target Technology:** OpenLane / SkyWater SKY130 (or equivalent open-source ASIC flow)  
> **RTL Language:** Verilog HDL

---

# 1. Introduction

## 1.1 Overview

Designing an Application-Specific Integrated Circuit (ASIC) involves transforming a high-level hardware description into a manufacturable integrated circuit. This transformation follows a structured Electronic Design Automation (EDA) flow known as the **RTL-to-GDSII flow**.

For the SDRAM Controller project, the RTL-to-GDSII implementation flow converts synthesizable Verilog modules into a physical silicon layout that satisfies logical correctness, timing, area, and manufacturability constraints.

Each stage in the flow progressively refines the design while preserving its intended functionality.

---

## Objectives

The implementation flow aims to:

- Verify functional correctness
- Generate optimized gate-level logic
- Map logic to standard cells
- Create a manufacturable physical layout
- Verify physical correctness
- Produce the final GDSII tape-out database

---

# 2. RTL Design

## Purpose

RTL (Register Transfer Level) design defines the hardware behavior using Verilog HDL. At this stage, the architecture is translated into synthesizable digital logic.

The SDRAM Controller is divided into independent RTL modules including:

- Address Decoder
- Bank Manager
- SDRAM Initialization
- Command Generator
- Controller Top Module

---

## Inputs

- Architecture specification
- SDRAM protocol
- Verilog HDL

---

## Outputs

- Synthesizable RTL
- Module hierarchy
- RTL netlist

---

## Tool Used

- Visual Studio Code
- Vivado (RTL Analysis)
- Verilator (optional)

---

## Algorithms

- Finite State Machine implementation
- Combinational logic
- Sequential logic
- Address decoding
- Bank state tracking

---

## Expected Output

- Clean synthesizable RTL
- No syntax errors
- Modular design

---

## Actual Project Output

- Five synthesizable Verilog modules
- Hierarchical RTL implementation
- Functional module integration

---

**Placeholder**

```
[Figure 2.1 RTL Module Hierarchy]
```

---

# 3. Functional Simulation

## Purpose

Simulation verifies that the RTL behaves according to the specification before synthesis.

The testbench applies stimulus to the controller and observes generated outputs.

---

## Inputs

- RTL source files
- Testbench
- Simulation vectors

---

## Outputs

- Waveforms
- Console logs
- Functional verification report

---

## Tool Used

- Xilinx Vivado Simulator
- GTKWave (optional)

---

## Algorithms

- Event-driven simulation
- Behavioral modeling
- Clock generation
- Stimulus sequencing

---

## Expected Output

- Correct SDRAM command generation
- Successful read/write transactions
- No functional mismatches

---

## Actual Project Output

- RTL simulation completed
- Functional waveforms generated
- Address decoding verified

---

**Placeholder**

```
[Figure 3.1 RTL Simulation Waveforms]
```

---

# 4. Logic Synthesis

## Purpose

Logic synthesis converts RTL into a gate-level representation composed of technology-independent logic gates.

Optimization is performed for:

- Area
- Timing
- Logic reduction

---

## Inputs

- RTL
- Standard cell libraries
- Timing constraints

---

## Outputs

- Gate-level netlist

---

## Tool Used

- Yosys

---

## Algorithms

- Boolean optimization
- Constant propagation
- Logic minimization
- Register inference
- FSM extraction

---

## Expected Output

- Optimized gate-level design
- Reduced logic complexity

---

## Actual Project Output

- Synthesized gate-level netlist
- Logic statistics generated

---

**Placeholder**

```
[Figure 4.1 RTL to Gate-Level Conversion]
```

---

# 5. Technology Mapping

## Purpose

Technology mapping replaces generic logic gates with actual cells from the target ASIC standard-cell library.

---

## Inputs

- Generic gate netlist
- SKY130 standard cell library

---

## Outputs

- Technology-specific netlist

---

## Tool Used

- ABC (within Yosys)

---

## Algorithms

- Boolean covering
- Cell matching
- Delay optimization
- Area optimization

---

## Expected Output

- Standard-cell netlist

---

## Actual Project Output

- SKY130 mapped design
- Library cell utilization report

---

**Placeholder**

```
[Figure 5.1 Technology Mapping]
```

---

# 6. Floorplanning

## Purpose

Floorplanning determines the overall physical organization of the ASIC.

Major tasks include:

- Core sizing
- IO placement
- Power planning
- Die utilization

---

## Inputs

- Technology netlist
- Standard cell library

---

## Outputs

- Floorplan database

---

## Tool Used

- OpenROAD

---

## Algorithms

- Utilization estimation
- Aspect ratio calculation
- Power grid generation

---

## Expected Output

- Optimized chip floorplan

---

## Actual Project Output

- Core area defined
- IO pins placed
- Power rings generated

---

**Placeholder**

```
[Figure 6.1 Floorplan]
```

---

# 7. Placement

## Purpose

Placement assigns physical locations to every standard cell while minimizing wirelength and congestion.

---

## Inputs

- Floorplan
- Standard-cell netlist

---

## Outputs

- Placed design

---

## Tool Used

- OpenROAD RePlAce

---

## Algorithms

- Global placement
- Detailed placement
- Wirelength minimization
- Congestion optimization

---

## Expected Output

- Legalized placement
- Optimized cell distribution

---

## Actual Project Output

- Standard cells successfully placed
- Congestion minimized

---

**Placeholder**

```
[Figure 7.1 Cell Placement]
```

---

# 8. Clock Tree Synthesis (CTS)

## Purpose

Clock Tree Synthesis distributes the clock signal uniformly to all sequential elements while minimizing skew and insertion delay.

---

## Inputs

- Placed design
- Clock constraints

---

## Outputs

- Buffered clock tree

---

## Tool Used

- OpenROAD CTS

---

## Algorithms

- Clock buffering
- H-tree construction
- Clock balancing
- Skew optimization

---

## Expected Output

- Balanced clock distribution
- Reduced clock skew

---

## Actual Project Output

- Clock tree generated
- Clock buffers inserted

---

**Placeholder**

```
[Figure 8.1 Clock Tree]
```

---

# 9. Routing

## Purpose

Routing creates all physical metal interconnections between placed cells.

---

## Inputs

- Placed design
- Clock tree
- Technology rules

---

## Outputs

- Routed layout

---

## Tool Used

- TritonRoute

---

## Algorithms

- Global routing
- Detailed routing
- Maze routing
- Design rule checking

---

## Expected Output

- Complete metal routing
- Zero routing violations

---

## Actual Project Output

- Routed ASIC layout
- Routing reports generated

---

**Placeholder**

```
[Figure 9.1 Routed Layout]
```

---

# 10. Magic Layout Verification

## Purpose

Magic is used to inspect and verify the generated physical layout.

It provides an interactive view of the fabricated layout while supporting DRC and layout editing.

---

## Inputs

- Routed DEF
- Technology files

---

## Outputs

- Layout database

---

## Tool Used

- Magic VLSI

---

## Algorithms

- Geometry processing
- Layer generation
- Design rule evaluation

---

## Expected Output

- Complete layout visualization

---

## Actual Project Output

- Layout successfully opened
- Layer verification completed

---

**Placeholder**

```
[Figure 10.1 Magic Layout]
```

---

# 11. Design Rule Check (DRC)

## Purpose

DRC verifies that the physical layout complies with semiconductor manufacturing rules.

Typical checks include:

- Minimum spacing
- Minimum width
- Metal overlap
- Via enclosure
- Density rules

---

## Inputs

- Physical layout

---

## Outputs

- DRC report

---

## Tool Used

- Magic
- KLayout (optional)

---

## Algorithms

- Rule-based geometric verification

---

## Expected Output

- Zero DRC errors

---

## Actual Project Output

- DRC verification report generated

---

**Placeholder**

```
[Figure 11.1 DRC Report]
```

---

# 12. Layout Versus Schematic (LVS)

## Purpose

LVS ensures that the fabricated layout is electrically identical to the synthesized schematic.

---

## Inputs

- Layout
- Gate-level netlist

---

## Outputs

- LVS report

---

## Tool Used

- Netgen

---

## Algorithms

- Graph matching
- Netlist comparison
- Connectivity verification

---

## Expected Output

- Layout matches schematic

---

## Actual Project Output

- Successful layout-netlist comparison

---

**Placeholder**

```
[Figure 12.1 LVS Verification]
```

---

# 13. GDSII Generation

## Purpose

GDSII is the industry-standard format used by semiconductor foundries for chip fabrication.

It contains all geometric information required for manufacturing.

---

## Inputs

- Verified layout

---

## Outputs

- `.gds` file

---

## Tool Used

- OpenLane
- Magic

---

## Algorithms

- Geometry export
- Layer mapping

---

## Expected Output

- Fabrication-ready GDSII database

---

## Actual Project Output

- Final GDSII file generated

---

**Placeholder**

```
[Figure 13.1 Final GDSII Layout]
```

---

# 14. KLayout Visualization

## Purpose

KLayout provides a high-performance environment for viewing and analyzing the final GDSII layout.

It is commonly used for:

- Layer inspection
- Measurement
- Hierarchy exploration
- Screenshot generation
- Final visual verification

---

## Inputs

- GDSII file

---

## Outputs

- Visual chip layout
- Layer inspection

---

## Tool Used

- KLayout

---

## Algorithms

- Hierarchical layout rendering
- Polygon visualization
- Layer filtering

---

## Expected Output

- Complete ASIC visualization

---

## Actual Project Output

- Final SDRAM Controller ASIC displayed
- Screenshots captured for documentation

---

**Placeholder**

```
[Figure 14.1 KLayout Visualization]
```

---

# 15. Complete RTL-to-GDSII Flow

The overall implementation flow proceeds through the following sequence:

```
Architecture Specification
            │
            ▼
      RTL Design
            │
            ▼
 Functional Simulation
            │
            ▼
     Logic Synthesis
            │
            ▼
 Technology Mapping
            │
            ▼
      Floorplanning
            │
            ▼
       Placement
            │
            ▼
 Clock Tree Synthesis
            │
            ▼
        Routing
            │
            ▼
     Magic Layout
            │
            ▼
          DRC
            │
            ▼
          LVS
            │
            ▼
      GDSII Export
            │
            ▼
 KLayout Visualization
```

**Placeholder**

```
[Figure 15.1 Complete RTL-to-GDSII ASIC Flow]
```

---

# 16. Summary

The RTL-to-GDSII implementation flow systematically transforms the SDRAM Controller from a behavioral hardware description into a verified physical layout ready for semiconductor fabrication. Beginning with RTL design and functional verification, the flow progresses through synthesis, technology mapping, floorplanning, placement, clock tree synthesis, and routing to create an optimized physical implementation. Verification stages such as DRC and LVS ensure manufacturability and logical equivalence before generating the final GDSII database. Visualization in KLayout provides the final inspection of the completed ASIC. This structured methodology ensures correctness, performance, scalability, and fabrication readiness while following industry-standard digital ASIC design practices.