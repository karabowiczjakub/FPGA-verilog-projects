
# FPGA Vision Pipeline

This project contains a selected FPGA-based image processing pipeline implemented mainly in Verilog using Xilinx Vivado.

The design was developed during reconfigurable systems / FPGA laboratory classes. The main idea of the project is to process video data as a continuous pixel stream and implement selected image processing operations directly in FPGA logic.

## Project overview

The implemented system processes a video stream pixel by pixel. Each pixel is passed through several processing stages together with synchronization signals:

* `de` – data enable,
* `hsync` – horizontal synchronization,
* `vsync` – vertical synchronization.

The project includes modules responsible for:

* input pixel format conversion,
* RGB to YCbCr conversion,
* thresholding / binary mask generation,
* skin-color segmentation,
* median filtering,
* centroid calculation,
* centroid visualization,
* output pixel format conversion.

The design demonstrates a typical FPGA image processing approach, where data flows through a hardware pipeline and each module performs a specific operation on the stream.

## Main processing pipeline

The general processing path can be described as:

```text
camera/video input
        |
        v
preprocessor
        |
        v
vision_system
        |
        +--> RGB delay path
        |
        +--> RGB to YCbCr conversion
        |
        +--> LUT-based binary mask
        |
        +--> YCbCr skin-color thresholding
        |
        +--> median 5x5 filtering
        |
        +--> centroid calculation
        |
        +--> centroid visualization
        |
        v
postprocess
        |
        v
video output
```

The main module of the image processing part is `vision_system.v`.

## Implemented modules

### `preprocessor.v`

This module converts the input video pixel format before the image is processed by the main vision system.

In this project, the input camera format is treated as:

```text
BRG = {B, R, G}
```

and converted to the internal RGB format:

```text
RGB = {R, G, B}
```

This allows the remaining modules to operate on a consistent RGB pixel representation.

### `vision_system.v`

This is the main image processing module. It connects the individual processing blocks and selects the output image depending on the value of the `sw` input.

The module includes:

* original RGB stream delay,
* synchronization signal delay,
* RGB to YCbCr conversion,
* LUT-based thresholding,
* YCbCr skin-color segmentation,
* median filtering,
* centroid calculation,
* centroid visualization,
* output multiplexer controlled by switches.

The module parameters allow changing image dimensions, for example for full-resolution processing or smaller simulation cases:

```verilog
parameter IMG_W = 1920
parameter IMG_H = 1080
parameter H_SIZE = 2200
```

For simulation, smaller values such as `64 x 64` can be used to reduce simulation time.

### `rgb2ycbcr_0_stub.vhdl`

This file is a Vivado-generated stub for the RGB to YCbCr conversion IP core.

The IP block converts RGB pixel data into the YCbCr color space. The YCbCr representation is then used for skin-color segmentation, where selected ranges of chrominance components are checked.

The main signals are:

* `pixel_in` – RGB input pixel,
* `pixel_out` – YCbCr output pixel,
* `de_in`, `hsync_in`, `vsync_in` – input synchronization signals,
* `de_out`, `hsync_out`, `vsync_out` – output synchronization signals.

### LUT-based thresholding

Inside `vision_system.v`, three LUT blocks are used for the red, green and blue components:

```verilog
LUT lut_r
LUT lut_g
LUT lut_b
```

Each LUT checks whether a given color component is inside a selected range. The binary output is calculated as:

```verilog
bin_out = lut_r_out & lut_g_out & lut_b_out;
```

This creates a simple binary mask based on RGB component ranges.

### YCbCr skin-color thresholding

The project also implements segmentation based on the YCbCr color space.

The chrominance components are extracted as:

```verilog
cb_val = pixel_ycbcr[15:8];
cr_val = pixel_ycbcr[7:0];
```

The skin-color mask is generated using threshold values:

```verilog
Ta = 85
Tb = 135
Tc = 135
Td = 180
```

The pixel is classified as belonging to the selected color range when:

```text
Cb > Ta and Cb < Tb and Cr > Tc and Cr < Td
```

If the condition is true, the output mask value is white:

```text
255
```

otherwise it is black:

```text
0
```

### `median5x5.v`

This module performs median-like filtering on a binary mask using a 5x5 context window.

The module builds a local 5x5 pixel neighborhood using registers and BRAM-based line delays. It then counts active pixels inside the 5x5 window.

The output pixel is set to white when more than 12 pixels in the 5x5 window are active:

```verilog
sum_ones > 12
```

This removes small isolated noise and improves the quality of the binary mask before centroid calculation.

### `centroid.v`

This module calculates the centroid of the detected binary region.

The module scans the image and accumulates image moments:

```text
m00 – number of active mask pixels
m10 – sum of x coordinates of active pixels
m01 – sum of y coordinates of active pixels
```

At the end of the frame, the centroid position is calculated as:

```text
x = m10 / m00
y = m01 / m00
```

If no active pixels are detected, the centroid is reset to zero.

### `accumulator_unsigned.v`

This is a reusable unsigned accumulator module.

It is used in the centroid calculation to accumulate coordinate sums for active mask pixels. The module adds the input value to the output register when `ce` is active.

### `vis_centroid.v`

This module visualizes the calculated centroid on the output image.

It tracks the current pixel position and draws a red cross at the calculated centroid coordinates:

```text
vertical line: current x position equals centroid x
horizontal line: current y position equals centroid y
```

The output pixel is changed to red when the current pixel belongs to the cross.

### `postprocess.v`

This module converts the internal RGB pixel format back to the output video format.

The internal format is:

```text
RGB = {R, G, B}
```

The output format is arranged as:

```text
BRG = {B, R, G}
```

The output is extended to 36 bits by adding zero padding to each color component.

## Switch-controlled output modes

The `vision_system.v` module uses the `sw` input to select which processing stage is displayed at the output.

Example output modes:

| Switch value | Output mode                             |
| ------------ | --------------------------------------- |
| `0`          | Original delayed RGB image              |
| `1`          | YCbCr output image                      |
| `2`          | RGB LUT-based binary mask               |
| `3`          | YCbCr skin-color binary mask            |
| `4`          | Median-filtered binary mask             |
| `5`          | Median mask with centroid visualization |

This makes it possible to observe intermediate processing stages without changing the HDL code.

## Repository structure

Recommended structure of this project:

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
│   ├── vision_system.v
│   └── rgb2ycbcr_0_stub.vhdl
│
├── sim/
│   ├── tb_hdmi.tcl
│   ├── tb_hdmi_vhdl.prj
│   └── tb_hdmi_vlog.prj
│
├── docs/
│   └── screenshots/
│
└── generated/
    └── tb_hdmi_behav.wdb
```

## Uploaded / included files

The currently documented source files are:

| File                     | Suggested location  | Description                                            |
| ------------------------ | ------------------- | ------------------------------------------------------ |
| `preprocessor.v`         | `src/`              | Converts input BRG pixel format to internal RGB format |
| `postprocess.v`          | `src/`              | Converts internal RGB format to output BRG-like format |
| `vision_system.v`        | `src/`              | Main image processing pipeline                         |
| `median5x5.v`            | `src/`              | 5x5 binary mask filtering                              |
| `centroid.v`             | `src/`              | Centroid calculation from binary mask                  |
| `accumulator_unsigned.v` | `src/`              | Unsigned accumulator used by centroid logic            |
| `vis_centroid.v`         | `src/`              | Draws centroid marker on the output image              |
| `rgb2ycbcr_0_stub.vhdl`  | `src/ip/` or `src/` | Stub declaration for Vivado RGB to YCbCr IP            |
| `tb_hdmi.tcl`            | `sim/`              | Simulation TCL script                                  |
| `tb_hdmi_vhdl.prj`       | `sim/`              | Vivado simulator VHDL project file                     |
| `tb_hdmi_vlog.prj`       | `sim/`              | Vivado simulator Verilog project file                  |
| `tb_hdmi_behav.wdb`      | `generated/`        | Vivado waveform database from behavioral simulation    |

## Notes about generated files

Some files are generated by Vivado and may depend on the original local project structure.

In particular:

* `tb_hdmi_behav.wdb` is a waveform database file,
* `tb_hdmi_vhdl.prj` and `tb_hdmi_vlog.prj` contain simulation compile paths,
* `rgb2ycbcr_0_stub.vhdl` is an IP stub, not the full implementation of the IP core.

For a clean GitHub repository, the most important files are the HDL source files in `src/`. Generated files can be kept separately in `generated/` or omitted if they are not needed to understand the design.

## External / generated dependencies

The project may require additional Vivado IP or helper modules that are not fully included in this folder, for example:

* RGB to YCbCr Vivado IP,
* LUT IP,
* divider IP,
* delay line modules,
* BRAM-based delay line module,
* HDMI/video testbench files.

If the project is recreated in Vivado, these blocks may need to be regenerated or copied from the original Vivado project.

## How to recreate the project in Vivado

A typical reconstruction flow is:

1. Create a new Vivado RTL project.
2. Add Verilog/VHDL files from the `src/` directory.
3. Regenerate or add required Vivado IP blocks.
4. Add simulation files from the `sim/` directory if available.
5. Set the correct top-level module depending on the project structure.
6. Run behavioral simulation.
7. Run synthesis and implementation.
8. Generate bitstream if the target board project is complete.

## What this project demonstrates

This project demonstrates practical FPGA concepts such as:

* stream-based image processing,
* pipelined hardware design,
* synchronization of video data and control signals,
* binary image segmentation,
* color-space based thresholding,
* contextual filtering using a 5x5 window,
* moment-based centroid calculation,
* visualization of processing results,
* integration of custom Verilog modules with Vivado-generated IP.

## Status

This repository folder is intended as documentation and source-code organization for the FPGA vision pipeline laboratory project.

The code is preserved as a selected laboratory implementation and may require the original Vivado IP configuration or additional generated files to be rebuilt exactly.
