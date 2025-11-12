#!/usr/bin/env python3
"""
Pygame visualization matching actual game_core_v8.v hardware
Shows 1 dog with exact physics from Verilog implementation
"""

import pygame
import sys

# Initialize pygame
pygame.init()

# Screen dimensions (matching Verilog)
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
BOX_W = 48
BOX_H = 32

# Colors (RGB) - matching Verilog color_idx
COLORS = [
    (255, 0, 0),      # Red
    (0, 255, 0),      # Green
    (0, 0, 255),      # Blue
    (255, 255, 0),    # Yellow
    (255, 0, 255),    # Magenta
    (0, 255, 255),    # Cyan
    (255, 128, 0),    # Orange
    (128, 0, 255),    # Purple
]

class Dog:
    """Simulates exact Verilog game_core_v8.v behavior"""
    def __init__(self, posx, posy, velx, vely, color_idx):
        # Position in pixels (matching Verilog 10-bit posx, 9-bit posy)
        self.posx = posx
        self.posy = posy
        # Velocity scaled by 256 (matching Verilog fixed-point)
        self.velx = velx
        self.vely = vely
        self.color_idx = color_idx
        self.hits = 0
    
    def update(self):
        """Update physics - constant velocity screensaver"""
        # Move: add velocity (scaled down from 256x fixed point)
        self.posx += self.velx / 256.0
        self.posy += self.vely / 256.0
        
        # Boundary bounce (just invert velocity, no damping for screensaver effect)
        if self.posx <= 0:
            self.posx = 0
            self.velx = -self.velx
        elif self.posx + BOX_W >= SCREEN_WIDTH:
            self.posx = SCREEN_WIDTH - BOX_W
            self.velx = -self.velx
        
        if self.posy <= 0:
            self.posy = 0
            self.vely = -self.vely
        elif self.posy + BOX_H >= SCREEN_HEIGHT:
            self.posy = SCREEN_HEIGHT - BOX_H
            self.vely = -self.vely
    
    def draw(self, screen):
        """Draw the dog box"""
        color = COLORS[self.color_idx % len(COLORS)]
        rect = pygame.Rect(int(self.posx), int(self.posy), BOX_W, BOX_H)
        pygame.draw.rect(screen, color, rect)
        pygame.draw.rect(screen, (255, 255, 255), rect, 2)  # White border

def main():
    # Create screen
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Dog Battle Game - Hardware Accurate (1 Dog)")
    
    # Create clock for FPS (60 fps ~ frame_tick rate)
    clock = pygame.time.Clock()
    FPS = 60
    
    # Initialize dog with exact Verilog reset values
    # posx0 <= 10'd100; posy0 <= 9'd100;
    # velx0 <= 10'sd256; vely0 <= 10'sd128;
    dog = Dog(posx=100, posy=100, velx=256, vely=128, color_idx=1)
    
    running = True
    frame_count = 0
    
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
        
        # Update game state (simulating frame_tick)
        dog.update()
        
        # Draw
        screen.fill((0, 0, 0))  # Black background
        dog.draw(screen)
        
        pygame.display.flip()
        clock.tick(FPS)
        frame_count += 1
    
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
