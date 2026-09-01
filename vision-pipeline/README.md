# FPGA Vision Pipeline

This folder contains selected files from an FPGA-based vision processing project implemented mainly in Verilog using Xilinx Vivado.

The project was developed during reconfigurable systems / FPGA laboratory classes. The main goal was to implement a simple real-time image processing pipeline in FPGA logic. The system processes a video stream pixel by pixel and applies several operations such as color conversion, segmentation, filtering and centroid calculation.

## Project overview

The design is based on stream processing. Pixel data is processed together with video synchronization signals:

* `de` – data enable,
* `hsync` – horizontal synchronization,
* `vsync` – vertical synchronization.

The main processing module is `vision_system.v`. It receives an RGB pixel stream, processes it through several stages and outputs one of the selected intermediate or final results depending on the value of the `sw` input.

The project demonstrates a typical FPGA image processing approach, where data flows through a hardware pipeline and each module performs a specific operation on the stream.

## Main processing pipeline

The general structure of the project is:

```text
video input / testbench input
        |
        v
preprocessor
        |
        v
vision_system
        |
        +--> delayed original RGB path
        |
        +--> RGB to YCbCr conversion
        |
        +--> RGB LUT-based binary mask
        |
        +--> YCbCr skin-color thresholding
        |
        +--> 5x5 median-like filtering
        |
        +--> centroid calculation
        |
        +--> centroid visualization
        |
        v
postprocess / simulation output
```

## Implemented modules

### `vision_system.v`

This is the main image processing module.

It connects the individual stages of the pipeline:

* original RGB delay path,
* synchronization signal delay path,
* RGB to YCbCr conversion IP,
* RGB LUT-based thresholding,
* YCbCr skin-color segmentation,
* 5x5 median-like filtering,
* centroid calculation,
* centroid visualization,
* switch-controlled output multiplexer.

The module has configurable image parameters:

```verilog
parameter IMG_W = 1920
parameter IMG_H = 1080
parameter H_SIZE = 2200
```

For simulation, smaller values are used, for example:

```verilog
IMG_W = 64
IMG_H = 64
H_SIZE = 83
```

This reduces simulation time.

### `preprocessor.v`

This module converts the input video pixel order before the data enters the main vision system.

The input format is treated as:

```text
BRG = {B, R, G}
```

The output format used inside the vision system is:

```text
RGB = {R, G, B}
```

This keeps the internal pixel representation consistent for the rest of the pipeline.

### `postprocess.v`

This module converts the internal RGB pixel format back to the output format.

The input format is:

```text
RGB = {R, G, B}
```

The output format is arranged as:

```text
BRG = {B, R, G}
```

The output pixel is extended to 36 bits by adding zero padding to each color component.

### `rgb2ycbcr_0_stub.vhdl`

This file is a Vivado-generated stub for the RGB to YCbCr conversion IP core.

The IP block converts RGB pixels into the YCbCr color space. The YCbCr representation is useful for color-based segmentation because chrominance components can be thresholded independently from brightness.

The main signals are:

* `pixel_in` – RGB input pixel,
* `pixel_out` – YCbCr output pixel,
* `de_in`, `hsync_in`, `vsync_in` – input synchronization signals,
* `de_out`, `hsync_out`, `vsync_out` – output synchronization signals.

This file is only a stub declaration. The actual IP core must be generated or included in the Vivado project.

### RGB LUT-based thresholding

Inside `vision_system.v`, three LUT blocks are used:

```verilog
LUT lut_r
LUT lut_g
LUT lut_b
```

Each LUT checks one RGB component. The final binary mask is calculated as:

```verilog
bin_out = lut_r_out & lut_g_out & lut_b_out;
```

If all three component conditions are true, the pixel is classified as belonging to the selected range.

### YCbCr skin-color segmentation

The project also implements segmentation in the YCbCr color space.

The chrominance components are extracted from the converted pixel:

```verilog
cb_val = pixel_ycbcr[15:8];
cr_val = pixel_ycbcr[7:0];
```

The threshold values used in the code are:

```verilog
Ta = 85
Tb = 135
Tc = 135
Td = 180
```

The binary mask is generated using the condition:

```text
Cb > Ta and Cb < Tb and Cr > Tc and Cr < Td
```

If the condition is true, the output value is white:

```text
255
```

Otherwise, the output value is black:

```text
0
```

### `median5x5.v`

This module performs 5x5 context filtering on a binary mask.

It builds a 5x5 neighborhood around the currently processed pixel using registers and BRAM-based line delays. Then it counts how many pixels in the 5x5 window are active.

The output is set to white when more than 12 pixels in the 5x5 window are active:

```verilog
sum_ones > 12
```

This removes small isolated noise from the binary mask and improves the input for centroid calculation.

The module also delays synchronization signals so that the output mask remains aligned with `de`, `hsync` and `vsync`.

### `centroid.v`

This module calculates the centroid of the detected binary region.

It scans the image and accumulates image moments:

```text
m00 – number of active pixels
m10 – sum of x coordinates of active pixels
m01 – sum of y coordinates of active pixels
```

At the end of the frame, the centroid position is calculated as:

```text
x = m10 / m00
y = m01 / m00
```

The division is performed using a divider IP block:

```verilog
divider_32_21_0
```

If no active pixels are detected in the frame, the centroid coordinates are reset to zero.

### `accumulator_unsigned.v`

This is a reusable unsigned accumulator module.

It is used by `centroid.v` to accumulate coordinate sums. When the `ce` signal is active, the module adds the input value to the current accumulated value.

### `vis_centroid.v`

This module visualizes the calculated centroid.

It tracks the current pixel position and draws a red cross at the calculated centroid coordinates. The red marker is generated when:

```text
current x position equals centroid x
or
current y position equals centroid y
```

The output pixel is changed to red for the marker position.

### `tb_hdmi.v`

This is the main Verilog testbench for simulation.

It connects:

* `hdmi_in.v` – simulated video input,
* `vision_system.v` – tested vision pipeline,
* `hdmi_out.v` – simulated video output.

In the testbench, the image size is reduced to 64x64 pixels:

```verilog
vision_system #(
    .IMG_W(64),
    .IMG_H(64),
    .H_SIZE(83)
)
```

This makes simulation faster and easier to run.

### `hdmi_in.v`

This file simulates a video input source.

It generates:

* pixel clock,
* `de`,
* `hsync`,
* `vsync`,
* RGB pixel data.

The simulation resolution used in this file is 64x64 pixels.

### `hdmi_out.v`

This file logs the simulated output video stream to `.ppm` image files.

It receives processed RGB data from the testbench and saves output frames in PPM format, for example:

```text
out_00.ppm
out_01.ppm
...
```

This allows the result of the FPGA image processing pipeline to be checked as image files after simulation.

## Switch-controlled output modes

The `sw` input in `vision_system.v` selects which processing result is sent to the output.

| Switch value | Output image                                     |
| ------------ | ------------------------------------------------ |
| `0`          | delayed original RGB image                       |
| `1`          | RGB to YCbCr conversion result                   |
| `2`          | RGB LUT-based binary mask                        |
| `3`          | YCbCr threshold binary mask                      |
| `4`          | median-filtered binary mask                      |
| `5`          | median-filtered mask with centroid visualization |

This makes it possible to observe intermediate stages of the pipeline without modifying the HDL code.

## Recommended repository structure

```text
vision-pipeline/
├── README.md
├── src/
│   ├── accumulator_unsigned.v
│   ├── centroid.v
│   ├── median5x5.v
│   ├── postprocess.v
│   ├── preprocessor.v
│   ├── vis_centroid.v
│   └── vision_system.v
│
├── src/ip/
│   └── rgb2ycbcr_0_stub.vhdl
│
├── sim/
│   ├── tb_hdmi.v
│   ├── hdmi_in.v
│   ├── hdmi_out.v
│   └── tb_hdmi.tcl
│
├── docs/
│   └── screenshots/
│
└── generated/
    ├── tb_hdmi_vhdl.prj
    ├── tb_hdmi_vlog.prj
    └── tb_hdmi_behav.wdb
```

## File placement

| File                     | Recommended location | Description                                         |
| ------------------------ | -------------------- | --------------------------------------------------- |
| `vision_system.v`        | `src/`               | Main image processing pipeline                      |
| `preprocessor.v`         | `src/`               | Converts input BRG-like pixel order to internal RGB |
| `postprocess.v`          | `src/`               | Converts internal RGB to output format              |
| `median5x5.v`            | `src/`               | 5x5 context filtering of binary mask                |
| `centroid.v`             | `src/`               | Centroid calculation from binary mask               |
| `accumulator_unsigned.v` | `src/`               | Unsigned accumulator used by centroid logic         |
| `vis_centroid.v`         | `src/`               | Draws centroid marker on output image               |
| `rgb2ycbcr_0_stub.vhdl`  | `src/ip/`            | Stub for Vivado RGB to YCbCr IP                     |
| `tb_hdmi.v`              | `sim/`               | Main simulation testbench                           |
| `hdmi_in.v`              | `sim/`               | Simulated HDMI/video input                          |
| `hdmi_out.v`             | `sim/`               | Simulated HDMI/video output writer                  |
| `tb_hdmi.tcl`            | `sim/`               | TCL script for simulation                           |
| `tb_hdmi_vhdl.prj`       | `generated/`         | Vivado-generated simulation project file            |
| `tb_hdmi_vlog.prj`       | `generated/`         | Vivado-generated simulation project file            |
| `tb_hdmi_behav.wdb`      | `generated/`         | Vivado waveform database                            |

## Generated and missing dependencies

Some blocks used in this design are generated by Vivado or come from the original laboratory project structure. They may be required to rebuild the project completely.

Known dependencies include:

```text
rgb2ycbcr_0
LUT
delay_line
delayLineBRAM_WP
divider_32_21_0
```

These modules/IP blocks are referenced by the source code, but not all of them are included as standalone HDL files in this folder.

For this reason, the repository should be treated as a documented source-code archive of the laboratory implementation. To rebuild the project exactly, the missing Vivado IP blocks may need to be regenerated or copied from the original Vivado project.

## How to run / recreate the project

A typical reconstruction flow in Vivado is:

1. Create a new RTL project in Vivado.
2. Add Verilog source files from `src/`.
3. Add VHDL/IP stub files from `src/ip/`.
4. Regenerate or add required Vivado IP blocks:

   * RGB to YCbCr converter,
   * LUT memories,
   * divider IP,
   * delay line modules.
5. Add simulation files from `sim/`.
6. Set `tb_hdmi.v` as the simulation top module.
7. Run behavioral simulation.
8. Check generated `.ppm` output images.
9. If a complete hardware top module and constraints are available, run synthesis, implementation and bitstream generation.

## What this project demonstrates

This project demonstrates the following FPGA and digital design concepts:

* Verilog HDL design,
* stream-based video processing,
* pixel-by-pixel image processing,
* pipeline latency,
* synchronization of data and control signals,
* RGB to YCbCr color conversion,
* color thresholding,
* binary mask generation,
* 5x5 context filtering,
* BRAM-based line buffering,
* image moment accumulation,
* centroid calculation,
* visualization of calculated features,
* simulation using a Verilog testbench,
* integration of custom HDL modules with Vivado-generated IP.

## Status

This folder documents the FPGA vision pipeline laboratory project.

The most important HDL source files and simulation testbench files are included. Some Vivado-generated IP blocks and helper modules may still be required to fully rebuild the original project.
