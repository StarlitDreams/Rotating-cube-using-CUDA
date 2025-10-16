#include "screen.cuh"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cmath>
#include <iostream>

/**
 * CUDA error checking macro
 * Wraps CUDA API calls and checks for errors
 */
#define cudaCheck(ans) { gpuAssert((ans), __FILE__, __LINE__); }

/**
 * Helper function for CUDA error checking
 * Reports errors to stderr and optionally aborts execution
 */
inline void gpuAssert(cudaError_t code, const char* file, int line, bool abort = true) { 
    if (code != cudaSuccess) {
        fprintf(stderr, "CUDA Error: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

/**
 * Plain POD structure for device/host transfer
 * Avoids including SDL types in device code
 */
struct PointF { 
    float x, y; 
};

/**
 * 3D vector structure for representing points in 3D space
 */
struct vec3 {
    float x, y, z;
};

/**
 * Edge connection structure defining relationships between vertices
 */
struct connection {
    int a, b;
};

/**
 * CUDA kernel for 3D rotation transformations
 * Applies sequential rotations around X, Y, and Z axes
 * 
 * @param outVec Output array of rotated vectors
 * @param inVec Input array of vectors to rotate
 * @param n Number of vectors
 * @param x Rotation angle around X axis (radians)
 * @param y Rotation angle around Y axis (radians)
 * @param z Rotation angle around Z axis (radians)
 */
__global__ void rotate(vec3* outVec, const vec3* inVec, int n, float x, float y, float z) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n) return;

    float px = inVec[idx].x;
    float py = inVec[idx].y;
    float pz = inVec[idx].z;

    float rad = x;
    float temp_y = cosf(rad) * py - sinf(rad) * pz;
    float temp_z = sinf(rad) * py + cosf(rad) * pz;
    py = temp_y;
    pz = temp_z;

    rad = y;
    float temp_x = cosf(rad) * px + sinf(rad) * pz;
    temp_z = -sinf(rad) * px + cosf(rad) * pz;
    px = temp_x;
    pz = temp_z;

    rad = z;
    temp_x = cosf(rad) * px - sinf(rad) * py;
    temp_y = sinf(rad) * px + cosf(rad) * py;
    px = temp_x;
    py = temp_y;

    outVec[idx].x = px;
    outVec[idx].y = py;
    outVec[idx].z = pz;
}

/**
 * CUDA kernel for parallel line rasterization
 * Uses DDA-style parametric interpolation with one thread per pixel
 * 
 * @param outPts Output array of rasterized points
 * @param n Number of points to generate
 * @param x0 Starting X coordinate
 * @param y0 Starting Y coordinate
 * @param x1 Ending X coordinate
 * @param y1 Ending Y coordinate
 */
__global__ void rasterizeLine(PointF* outPts, int n, float x0, float y0, float x1, float y1) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;

    float t = (n > 1) ? (float)i / (float)(n - 1) : 0.0f;
    outPts[i].x = x0 + t * (x1 - x0);
    outPts[i].y = y0 + t * (y1 - y0);
}

/**
 * Main application entry point
 * Renders a rotating 3D cube using CUDA-accelerated transformations and line rasterization
 */
int main() {
    Screen screen;
    
    std::vector<vec3> points = {
        {810, 390, -150},
        {1110, 390, -150},
        {1110, 690, -150},
        {810, 690, -150},
        {810, 390, 150},
        {1110, 390, 150},
        {1110, 690, 150},
        {810, 690, 150}
    };

    std::vector<connection> connections = {
        {0, 1}, {1, 2}, {2, 3}, {3, 0},
        {4, 5}, {5, 6}, {6, 7}, {7, 4},
        {0, 4}, {1, 5}, {2, 6}, {3, 7}
    };
    
    vec3 c{0, 0, 0};
    for (auto p : points) {
        c.x += p.x;
        c.y += p.y;
        c.z += p.z;
    }
    c.x /= points.size();
    c.y /= points.size();
    c.z /= points.size();

    std::vector<vec3> centeredPoints(points.size());
    for (size_t i = 0; i < points.size(); i++) {
        centeredPoints[i].x = points[i].x - c.x;
        centeredPoints[i].y = points[i].y - c.y;
        centeredPoints[i].z = points[i].z - c.z;
    }

    vec3* d_inPoints = nullptr, * d_outPoints = nullptr;
    const int numPoints = static_cast<int>(points.size());
    cudaCheck(cudaMalloc(&d_inPoints, numPoints * sizeof(vec3)));
    cudaCheck(cudaMalloc(&d_outPoints, numPoints * sizeof(vec3)));

    cudaCheck(cudaMemcpy(d_inPoints, centeredPoints.data(), numPoints * sizeof(vec3), cudaMemcpyHostToDevice));

    const int TPB = 128;
    int blocks = (numPoints + TPB - 1) / TPB;

    float rotX = 0.0f, rotY = 0.0f, rotZ = 0.0f;

    while (screen.input()) {
        screen.clear_points();

        rotX += 0.01f;
        rotY += 0.02f;
        rotZ += 0.005f;

        rotate<<<blocks, TPB>>>(d_outPoints, d_inPoints, numPoints, rotX, rotY, rotZ);
        cudaCheck(cudaGetLastError());
        cudaCheck(cudaDeviceSynchronize());

        std::vector<vec3> rotatedPoints(numPoints);
        cudaCheck(cudaMemcpy(rotatedPoints.data(), d_outPoints, numPoints * sizeof(vec3), cudaMemcpyDeviceToHost));

        std::vector<SDL_FPoint> displayPoints;
        displayPoints.reserve(numPoints);
        for (int i = 0; i < numPoints; i++) {
            displayPoints.push_back(SDL_FPoint{
                rotatedPoints[i].x + c.x,
                rotatedPoints[i].y + c.y
            });
        }

        screen.pixels(displayPoints.data(), displayPoints.size());

        for (const auto& conn : connections) {
            float x0 = displayPoints[conn.a].x;
            float y0 = displayPoints[conn.a].y;
            float x1 = displayPoints[conn.b].x;
            float y1 = displayPoints[conn.b].y;
            
            float dx = fabsf(x1 - x0), dy = fabsf(y1 - y0);
            int n = (int)fmaxf(dx, dy) + 1;
            if (n < 2) n = 2;

            PointF* d_pts = nullptr;
            cudaCheck(cudaMalloc(&d_pts, n * sizeof(PointF)));
            
            int lineBlocks = (n + TPB - 1) / TPB;
            
            rasterizeLine<<<lineBlocks, TPB>>>(d_pts, n, x0, y0, x1, y1);
            cudaCheck(cudaGetLastError());
            cudaCheck(cudaDeviceSynchronize());

            std::vector<PointF> h_pts(n);
            cudaCheck(cudaMemcpy(h_pts.data(), d_pts, n * sizeof(PointF), cudaMemcpyDeviceToHost));
            cudaCheck(cudaFree(d_pts));

            std::vector<SDL_FPoint> sdlPts;
            sdlPts.reserve(h_pts.size());
            for (const auto& p : h_pts) {
                sdlPts.push_back(SDL_FPoint{p.x, p.y});
            }
            screen.pixels(sdlPts.data(), sdlPts.size());
        }

        screen.show();
        SDL_Delay(7);
    }

    cudaCheck(cudaFree(d_inPoints));
    cudaCheck(cudaFree(d_outPoints));

    return 0;
}