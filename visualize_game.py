#!/usr/bin/env python3
"""
Simple pygame visualization of the dog battle game
Reads from simulation and shows the boxes moving and colliding
"""

import pygame
import sys
import random
import math

# Initialize pygame
pygame.init()

# Screen dimensions
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
BOX_W = 48
BOX_H = 32

# Colors (RGB)
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
    def __init__(self, x, y, vx, vy, color_idx, name="Dog", mass=1.0):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color_idx = color_idx
        self.hits = 0
        self.name = name
        self.mass = mass  # Different mass for each dog
        self.power_up_timer = 0  # For power-up effects
        self.is_powered = False
        self.trail = []  # List of (x, y, age) tuples for trail effect
        self.max_trail_length = 30  # Max trail points to keep
    
    def update(self):
        # Update position
        self.x += self.vx
        self.y += self.vy
        
        # Add current position to trail
        center_x = self.x + BOX_W // 2
        center_y = self.y + BOX_H // 2
        self.trail.append((center_x, center_y, 0))  # age=0 (fresh)
        
        # Remove old trail points
        if len(self.trail) > self.max_trail_length:
            self.trail.pop(0)
        
        # Age all trail points
        for i in range(len(self.trail)):
            self.trail[i] = (self.trail[i][0], self.trail[i][1], self.trail[i][2] + 1)
        
        # Apply friction to slow down over time (less friction now)
        friction = 0.99  # Only 1% friction per frame (was 3%)
        self.vx *= friction
        self.vy *= friction
        
        # Check if speed is too low and trigger power-up
        speed = (self.vx**2 + self.vy**2) ** 0.5
        if speed < 0.5 and not self.is_powered:  # Too slow
            # Random chance for power-up
            if random.random() < 0.3:  # 30% chance per frame when slow
                # Give massive boost in random direction
                angle = random.uniform(0, 2 * math.pi)
                boost_speed = 15.0
                self.vx = boost_speed * math.cos(angle)
                self.vy = boost_speed * math.sin(angle)
                self.is_powered = True
                self.power_up_timer = 60  # Power-up lasts 60 frames
        
        # Countdown power-up timer
        if self.is_powered:
            self.power_up_timer -= 1
            if self.power_up_timer <= 0:
                self.is_powered = False
        
        # Bounce on walls
        if self.x <= 0:
            self.x = 0
            self.vx = -self.vx * 0.8  # Lose energy on bounce
        elif self.x + BOX_W >= SCREEN_WIDTH:
            self.x = SCREEN_WIDTH - BOX_W
            self.vx = -self.vx * 0.8
        
        if self.y <= 0:
            self.y = 0
            self.vy = -self.vy * 0.8
        elif self.y + BOX_H >= SCREEN_HEIGHT:
            self.y = SCREEN_HEIGHT - BOX_H
            self.vy = -self.vy * 0.8
    
    def collides_with(self, other):
        """Check if this dog collides with another"""
        return (self.x < other.x + BOX_W and 
                self.x + BOX_W > other.x and
                self.y < other.y + BOX_H and 
                self.y + BOX_H > other.y)
    
    def elastic_collision(self, other):
        """Calculate velocities after elastic collision based on mass"""
        # Conservation of momentum for 1D collisions (simplified, assuming horizontal)
        # v1' = ((m1 - m2) * v1 + 2 * m2 * v2) / (m1 + m2)
        # v2' = ((m2 - m1) * v2 + 2 * m1 * v1) / (m1 + m2)
        
        total_mass = self.mass + other.mass
        
        # X-axis collision
        new_vx1 = ((self.mass - other.mass) * self.vx + 2 * other.mass * other.vx) / total_mass
        new_vx2 = ((other.mass - self.mass) * other.vx + 2 * self.mass * self.vx) / total_mass
        
        # Y-axis collision
        new_vy1 = ((self.mass - other.mass) * self.vy + 2 * other.mass * other.vy) / total_mass
        new_vy2 = ((other.mass - self.mass) * other.vy + 2 * self.mass * self.vy) / total_mass
        
        self.vx = new_vx1
        self.vy = new_vy1
        other.vx = new_vx2
        other.vy = new_vy2
    
    def draw(self, screen):
        """Draw the dog box and trail"""
        # Draw trail first (behind the dog)
        color = COLORS[self.color_idx % len(COLORS)]
        for i, (tx, ty, age) in enumerate(self.trail):
            # Fade out older trail points
            alpha = int(255 * (1 - (age / self.max_trail_length)))
            # Create a surface with alpha for the trail point
            trail_surface = pygame.Surface((4, 4), pygame.SRCALPHA)
            trail_color = (*color, alpha)
            pygame.draw.circle(trail_surface, trail_color, (2, 2), 2)
            screen.blit(trail_surface, (int(tx) - 2, int(ty) - 2))
        
        # Draw the dog box
        rect = pygame.Rect(self.x, self.y, BOX_W, BOX_H)
        pygame.draw.rect(screen, color, rect)
        
        # Draw thicker border if powered up
        border_width = 4 if self.is_powered else 2
        border_color = (255, 215, 0) if self.is_powered else (255, 255, 255)  # Gold if powered
        pygame.draw.rect(screen, border_color, rect, border_width)
        
        # Draw different patterns for each dog based on name
        center_x = self.x + BOX_W // 2
        center_y = self.y + BOX_H // 2
        
        # Draw different patterns for each dog based on name
        if self.name == "Sophus dog":
            # Draw a cross
            pygame.draw.line(screen, (255, 255, 255), (center_x - 8, center_y), (center_x + 8, center_y), 2)
            pygame.draw.line(screen, (255, 255, 255), (center_x, center_y - 8), (center_x, center_y + 8), 2)
        elif self.name == "Lauge dog":
            # Draw a circle
            pygame.draw.circle(screen, (255, 255, 255), (center_x, center_y), 6)
        elif self.name == "Oskar dog":
            # Draw a square
            pygame.draw.rect(screen, (255, 255, 255), (center_x - 6, center_y - 6, 12, 12), 2)
        elif self.name == "Emil dog":
            # Draw a triangle (simplified)
            points = [(center_x, center_y - 8), (center_x + 8, center_y + 8), (center_x - 8, center_y + 8)]
            pygame.draw.polygon(screen, (255, 255, 255), points, 2)
        
        # Draw power-up aura if powered
        if self.is_powered:
            pygame.draw.circle(screen, (255, 215, 0), (center_x, center_y), 15, 2)

def main():
    # Create screen
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Dog Battle Game")
    
    # Create clock for FPS
    clock = pygame.time.Clock()
    FPS = 60
    
    # Initialize dogs with random positions and velocities
    dog_names = ["Sophus dog", "Lauge dog", "Oskar dog", "Emil dog", 
                 "Magnus dog", "Alexander dog", "Victor dog", "Sebastian dog"]
    dog_masses = [1.0, 1.5, 2.0, 0.8, 1.2, 0.9, 1.8, 1.1]  # Different masses for each dog
    dogs = []
    for i in range(8):  # 8 dogs now!
        # Random position on screen (with margin so box fits)
        x = random.randint(0, SCREEN_WIDTH - BOX_W)
        y = random.randint(0, SCREEN_HEIGHT - BOX_H)
        
        # Random velocity (between -3 and 3, but not 0)
        vx = random.choice([-3, -2, -1, 1, 2, 3])
        vy = random.choice([-3, -2, -1, 1, 2, 3])
        
        # Color index
        color_idx = i
        
        dogs.append(Dog(x, y, vx, vy, color_idx, dog_names[i], dog_masses[i]))
    
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
        
        # Update game state
        for dog in dogs:
            dog.update()
        
        # Check collisions
        for i in range(len(dogs)):
            for j in range(i + 1, len(dogs)):
                if dogs[i].collides_with(dogs[j]):
                    # Use elastic collision physics
                    dogs[i].elastic_collision(dogs[j])
                    
                    # Increment hits
                    dogs[i].hits += 1
                    dogs[j].hits += 1
                    
                    # Change colors
                    dogs[i].color_idx += 1
                    dogs[j].color_idx += 1
        
        # Draw
        screen.fill((0, 0, 0))  # Black background
        
        for dog in dogs:
            dog.draw(screen)
        
        # Draw simple title (text rendering disabled due to pygame issues)
        pass
        
        pygame.display.flip()
        clock.tick(FPS)
    
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
