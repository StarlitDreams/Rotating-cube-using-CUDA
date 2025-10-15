#pragma once

#include<vector>
#include <SDL.h>
class Screen
{
	SDL_Event e;
	SDL_Window* window;
	SDL_Renderer* renderer;
	std::vector<SDL_FPoint> points;
	
    // Replace SDL_createWindowAndRenderer with the correct SDL function
    Screen() {
        SDL_Init(SDL_INIT_VIDEO);
		SDL_CreateWindowAndRenderer(960 * 2, 540 * 2, 0, &window, &renderer); //Screen resolution divided by 2, because we are scaling everything by 2
		SDL_RenderSetScale(renderer, 2, 2); //scale factor

    }

	void pixel(float x, float y) {
		points.emplace_back(x, y);


	}

    // Replace SDL_RendererPresent(renderer); with SDL_RenderPresent(renderer);
    void show() {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); //black background - can change to anything
        SDL_RenderClear(renderer); //clear the screen to black

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); //white pixels - can change to anything
        SDL_SetRenderDrawColor(renderer, 255, 105, 180, 255); // hot pink pixels

        for(const auto& p : points) {
            SDL_RenderDrawPointF(renderer, p.x, p.y);
        }
        SDL_RenderPresent(renderer);    
    }



    void input() {
        while(SDL_PollEvent(&e)) {
            if(e.type == SDL_QUIT) {
                
            }
           
		}
    }


};

