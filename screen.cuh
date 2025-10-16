#pragma once
#define SDL_MAIN_HANDLED
#include <vector>
#include <SDL.h>

class Screen {
private:
    SDL_Event e{};
    SDL_Window* window{};
    SDL_Renderer* renderer{};
    std::vector<SDL_FPoint> points;

public:
    Screen() {
        SDL_Init(SDL_INIT_VIDEO);
        SDL_CreateWindowAndRenderer(960 * 2, 540 * 2, 0, &window, &renderer);
        SDL_RenderSetScale(renderer, 1, 1);
    }

    ~Screen() {
        if (renderer) SDL_DestroyRenderer(renderer);
        if (window) SDL_DestroyWindow(window);
        SDL_Quit();
    }

    void pixel(float x, float y) {
        // SDL_FPoint is a POD; no (x,y) ctor. Use brace init:
        points.push_back(SDL_FPoint{ x, y });
    }

    // Bulk-add for efficiency
    void pixels(const SDL_FPoint* pts, size_t n) {
        points.insert(points.end(), pts, pts + n);
    }

    void clear_points() { points.clear(); }

    void show() {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        SDL_SetRenderDrawColor(renderer, 255, 105, 180, 255); // hot pink
        for (const auto& p : points) {
            SDL_RenderDrawPointF(renderer, p.x, p.y);
        }
        SDL_RenderPresent(renderer);
    }

    bool input() {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) return false;
        }
        return true;
    }
};
