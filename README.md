# CUBE — CUDA Rotating 3D Cube (SDL2 + Visual Studio)

CUDA-accelerated demo that rotates a wireframe 3D cube and rasterizes its edges in parallel, then draws with SDL2. Built with **Visual Studio on Windows**, tested on **NVIDIA RTX 3050 Ti**.


## Features
- Per-vertex **XYZ rotation** on the GPU via a CUDA kernel
- Parallel **DDA-style line rasterization** (one thread per pixel)
- **SDL2** renderer for fast point/line drawing
- Minimal, **source-only repo** (`.cu`, `.cuh`) — no IDE/project files committed



## Requirements
- **NVIDIA GPU** + recent drivers (tested on **RTX 3050 Ti**)
- **CUDA Toolkit 12.x** (or compatible): <https://developer.nvidia.com/cuda-downloads>
- **Visual Studio 2022** (Desktop C++ workload + CUDA integration)
- **SDL2** (headers + `SDL2.lib` + `SDL2.dll`)


## Pre-compiled version
A prebuilt **.exe installer** (bundled with required runtime DLLs) is available under **Releases**:  
<https://github.com/StarlitDreams/Rotating-cube-using-CUDA/releases/tag/v1.0>

## Example
![2025-10-1616-00-33-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/8a1c2caa-3cc1-47d2-9a7c-49124920c27e)

## Quick Start (Build from Source)

1. **Clone** the repo and open/create a **CUDA** project in Visual Studio (project files are kept local by design).
2. **Add sources** to your project:
   - `main.cu`
   - `screen.cuh`
3. **Project settings** (recommended):
   - **C/C++ → Code Generation → Runtime Library:** `/MD` (Release) or `/MDd` (Debug)
   - **CUDA C/C++ → Host → Runtime Library:** match above (`/MD` or `/MDd`)
   - **CUDA C/C++ → Device → Code Generation:** set to your GPU (e.g., `compute_86,sm_86` for Ampere)
   - **Preprocessor Definitions:** ensure `SDL_MAIN_HANDLED` is defined (already in `screen.cuh`)
4. **Install SDL2** (see next section).
5. **Build** `Release | x64`.
6. Ensure the following **DLLs** sit next to your `.exe`:
   - `SDL2.dll`
   - `cudart64_12.dll` (from `%CUDA_PATH%\bin\`)



## SDL2 Setup in Visual Studio

**Easiest (NuGet):**
1. `Project → Manage NuGet Packages… → Browse`
2. Search **`sdl2`** (e.g., `sdl2.nuget`) and install for **x64**.
3. Confirm it linked **`SDL2.lib`** (NuGet usually wires this).
4. Copy **`SDL2.dll`** from the package (`bin\win-x64\`) into your build output (e.g., `x64\Release\`).

> Alternative: download the SDL2 dev package, add Include/Lib paths in Project Properties, link `SDL2.lib`, and place `SDL2.dll` beside the built `.exe`.


## Run
Launch the `.exe` from a folder that **also contains** `SDL2.dll` and `cudart64_12.dll`. You should see a hot-pink wireframe cube rotating smoothly.

## How It Works (High Level)
- **Rotation kernel:** each vertex is rotated around X, Y, Z using `cosf/sinf` (one thread per vertex).
- **Line rasterization kernel:** edges are interpolated parametrically (one thread per pixel) to produce point samples.
- **Presentation:** sampled points are sent back to host and drawn with **SDL2**.

I learned the basic cube modeling/rotation approach here:  
<https://youtu.be/kdRJgYO1BJM?si=u6W_oN7rvthjK__7>


## Notes & Troubleshooting
- If Windows reports missing MSVC runtime, install the **Microsoft Visual C++ Redistributable (x64)**.
- SmartScreen warnings are typical for unsigned executables/first-time downloads.
- If the app runs on your dev box but not elsewhere, verify:
  - Matching **NVIDIA driver** is installed on the target machine
  - `cudart64_12.dll` and `SDL2.dll` are present next to the `.exe`

## License
See `LICENSE.txt`.
