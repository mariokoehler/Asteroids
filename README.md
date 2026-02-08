# Godot Asteroids (Alpha)

![Godot 4](https://img.shields.io/badge/Godot-v4.x-%23478cbf?logo=godot-engine&logoColor=white)
![Status](https://img.shields.io/badge/Status-Alpha-orange)

A modern, physics-based interpretation of the classic arcade shooter *Asteroids*, built using **Godot 4**.

This project demonstrates a robust implementation of Newtonian 2D physics, seamless screen wrapping, and decoupled game architecture using Signals and Autoloads.

<!-- [Insert a screenshot or GIF of gameplay here] -->

## 🎮 Gameplay Features

*   **Newtonian Flight Model:** Ships drift and carry momentum. Movement is based on applying forces and torque, not direct position manipulation.
*   **Procedural Destruction:** Large asteroids split into medium fragments, which split into small fragments.
*   **Seamless Screen Wrapping:** Objects (player, asteroids, bullets) wrap around the screen edges smoothly using direct physics state integration.
*   **Combat System:**
    *   Projectile ballistics.
    *   Player health and invulnerability frames (I-frames).
    *   Dynamic particle effects for engine exhaust and asteroid destruction.
*   **UI & State Management:**
    *   Real-time HUD (Score, Lives, Health Bar).
    *   Game Over screen with restart functionality.
    *   Persistent Game Manager to handle state across scene reloads.

## 🕹️ Controls

| Action | Key |
| :--- | :--- |
| **Thrust** | `W` or `Arrow Up` |
| **Rotate Left** | `A` or `Arrow Left` |
| **Rotate Right** | `D` or `Arrow Right` |
| **Fire** | `Spacebar` |

## 🛠️ Technical Architecture

This project was built with a focus on clean, object-oriented design patterns suitable for Godot 4.

### Physics Implementation (`RigidBody2D`)
Unlike many tutorials that use `CharacterBody2D` (Kinematic), this project uses `RigidBody2D` to achieve authentic space drift.
*   **Movement:** Forces are applied in `_physics_process`.
*   **Screen Wrapping:** Performed in `_integrate_forces` to safely modify the physics state transform without breaking the physics engine's internal calculations.
*   **Base Class:** A custom `WrappableBody` class handles the wrapping logic, which `Player`, `Asteroid`, and `Bullet` all inherit from.

### Component Structure
*   **Autoloads (Singletons):** A `GameManager` handles global state (Score, Lives, Scene transitions) to persist data when the scene reloads.
*   **Signals:** The game uses an Event-Driven architecture.
    *   *Example:* The `Player` emits `health_changed` → `GameManager` relays it → `HUD` updates the UI. The Player does not know the HUD exists.
*   **Factory Pattern:** Asteroids spawn smaller variations of themselves dynamically upon destruction, handling their own initialization via `call_deferred` to respect physics locking.

### Visuals
*   **Particle Systems:** `GPUParticles2D` are used for engine exhaust (local coordinates) and dust explosions (global coordinates, self-cleaning).
*   **Theming:** UI components use Godot's Theme Overrides for custom fonts and styles.

## 🚀 Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/godot-asteroids.git
    ```
2.  **Import into Godot:**
    *   Open Godot 4.x.
    *   Click **Import**.
    *   Navigate to the folder and select the `project.godot` file.
3.  **Run:**
    *   Press `F5` to run the project.

## 📂 Project Structure

```text
res://
├── assets/          # Sprites, Fonts, and Sounds
├── scenes/          # .tscn files (Player, World, Asteroid, UI)
├── scripts/         # .gd files
│   ├── GameManager.gd  (Autoload)
│   ├── WrappableBody.gd (Base Class)
│   └── ...
└── project.godot
```

## 📝 To-Do / Roadmap

*   [ ] Add Sound Effects (Thrust, Shoot, Explode).
*   [ ] Implement High Score saving (File I/O).
*   [ ] Add UFO enemies.
*   [ ] Add Power-ups (Shields, Triple Shot).

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).