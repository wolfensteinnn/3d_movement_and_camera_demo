# DucksGame

A polished **3D movement and camera demo** built in Godot 4. You play a duck who can run, sprint, jump, mantle and **climb up walls PEAK-style**, with a first-person camera that reacts to almost everything you do: breathing, bobbing, tilting, shaking, dipping and punching in and out.

The goal is the feel of a premium 3D platformer: movement that is forgiving and responsive, and a camera that sells every action without getting in the way.

<!-- Add a GIF or screenshots here: climbing, ragdoll recovery, emote wheel, 2-player session -->

## Highlights

- **Wall climbing** up almost any surface, with stamina, hanging, wall lunges, wall jumps and mantling
- **Premium camera work**: layered bobbing, FOV shaping, tilts, springs, landing dips, climb tremor and screen effects
- **Wobbly animations**: wiggle-bone head physics, blinking, idle eye tracking, ragdoll falls with a dramatic recovery
- **Simple multiplayer**: runs two clients straight from the Godot editor
- **Emotes** on `T` with an emote wheel and animated duck poses

## The camera

Most of the effort in this project went into the camera, and it is all layered on top of a single `CameraMount` node that follows the duck. Every effect below is smoothed, blended and individually tunable through constants at the top of `player.gd`.

### Smoothed follow
The camera does not sit rigidly on the player. A separate `camera_smooth_pos` chases the eye position with different speeds per axis and per situation:

- **Attach smoothing**: when you grab a wall, the follow speed starts slow and eases (cubic) back to normal over about 0.7s, which gives the grab a soft, weighty feel.
- **Terminal-velocity catch-up**: the vertical follow speed ramps up as you fall faster, so the camera never lags behind a long drop.
- **Moving platforms**: platform velocity is added to the smoothed position so the camera does not drift on ships.
- **Floor safety**: the camera can never dip below the floor, even during heavy dips.

### Bobbing, one layer per state
Each state has its own frequency and amplitude, and states are blended in and out instead of switched:

| Layer | What it does |
|---|---|
| **Walk bob** | Gentle vertical bob with a half-frequency side sway |
| **Sprint bob** | Faster and larger, also used for sprint-jumps |
| **Idle breathing** | Kicks in after being still for a moment. Asymmetric breath (slow inhale, quick exhale) with a tiny forward lean and side drift |
| **Uphill bob** | Slower, heavier bob with a forward nod when the slope gets steep |
| **Climb bob** | Reach-and-pull rhythm with alternating hand sway, scaled by how fast you are actually climbing |
| **Climb stamina tremor** | High-frequency muscle shake that grows as stamina runs low (two phases offset by the golden ratio so it never feels metronomic) |
| **Freefall drift** | Slow, layered sine drift that fades in the further you fall |

### FOV shaping
FOV is computed every frame from a base value plus several additive effects, then smoothed:

- Base: **68** default, **63** sprinting (tunnel-vision speed feel), **80** climbing
- Fall bonus that widens with fall distance
- **Wall lunge punch** (+8) and **wall jump punch** (+11) that decay quickly
- Landing dip and ragdoll recovery dip (a big, slow-easing squeeze)
- Climb shake narrows FOV slightly as you tire

### Tilts and leans
All of these are summed into the camera mount's rotation:

- **Strafe tilt** based on real velocity (not input), so it feels physical
- **Sprint lean** that is stronger when sprint-jumping
- **Crouch tilt** driven by a critically-tuned **spring** (stiffness and damping), so it settles with a small overshoot
- **Climb tilt** from horizontal input, plus an upward pitch with overshoot when attaching
- **Mantle tilt** with a slight overshoot
- **Wall lunge** tilt, pitch and sideways nudge, direction-aware
- **Fall lean** during freefall
- **Landing dip** on impact

### Camera collision
`_update_camera_clip()` casts five rays (center, left, right, up, down) from the eye to the intended camera position and pulls the camera in front of the nearest hit, so it never clips into walls while climbing. Entering a clip snaps to the safe point, while moving along it is lerped, and the camera eases back out smoothly afterwards.

### Ragdoll camera and recovery
Hard landings send the duck ragdolling. The camera follows the ragdoll body, slerps its rotation to it, and layers a landing dip on top. When you recover, the camera plays a staged sequence: a sharp dip, a struggling wobble that decays, and an eased follow-speed curve with a long linger phase, so standing back up feels like getting your bearings.

### Screen effects
A screen shader is driven live from gameplay state:

- Chromatic aberration, vignette and shake scale with climb stamina strain
- Vignette on ragdoll that fades out during recovery
- A fast, short shake used for small "error" feedback

### Standalone camera script
`main_camera.gd` is a separate smoothed third-person style camera. It has exported sensitivity, smoothing and pitch limits, a default offset from the pivot, and a **sphere-sweep collision check** (`cast_motion`) that shortens the offset when something is in the way.

## The movement controller

The whole controller lives in `player.gd` (a `CharacterBody3D`).

### Ground and air
- Separate acceleration and deceleration, with air control and air friction
- **Coyote time** (0.07s) and **jump buffering** (0.12s)
- **Momentum-boosted jumps**, larger when sprinting
- Asymmetric gravity (lighter going up, heavier coming down) with a terminal velocity
- Slope handling: uphill slows you down, blocks sprinting when too steep, and feeds the uphill walk animation and bob
- Crouching with a separate collision shape and a safe "can I stand up here?" ceiling check

### Wall climbing
- **Probe-based wall detection**: multiple probes spread around the player build a wall manifold and reject walls whose normals diverge too much
- **Surface-relative climbing**: you stick to the surface's local space, so you stay attached to moving or rotating objects
- Attach phase with a small boost and its own camera treatment, plus attach and reacquire cooldowns
- Climb speed and stamina drain depend on the situation
- **Hanging** has its own meter, draining faster on steeper surfaces
- **Wall lunges** (burst up the wall) and **wall jumps** (camera direction steers the jump, with lateral input boost) cost stamina
- **Mantling** over ledges, including jump mantles, with its own timing and cooldown
- Bottom-edge detection and a nudge away from walls to avoid awkward sticking

### Stamina
Sprinting, jumping, climbing, lunging and wall jumping all draw from one stamina pool, with a regen delay and regen rate. Stamina strain feeds directly back into the camera as tremor, FOV and vignette.

### Interactions and physics
- Grab and **throw other players** with a charged throw
- Pick up and carry interactable objects
- Ride moving platforms (ships), including angular velocity
- Ragdoll with settle detection, minimum duration and recovery

## Animation and wobble

- `AnimationTree` state machine driven every frame from movement state: run, sprint, directional run, crouch, climb, hang, lunge, mantle, freefall, ragdoll recovery and emotes
- **Wiggle-bone modifier** on the head for wobbly secondary motion, tilted by your turning
- Idle turn: the body turns once you look past a threshold, while the eyes track within it
- Random blinking via blend shapes
- Climb animation time scale follows climb speed

## Emotes

Hold **`T`** to open the emote wheel, move to choose an emote and release to play it. Emotes are cancelled by jumping, and are blocked while climbing, hanging, falling, ragdolling or holding another player.

## Multiplayer

A simple authority-based setup:

- Each player node is named after its peer ID and owned by that peer
- Remote players are smoothed with a `TickInterpolator`
- Ragdoll starts and stops, grabbing, holding and throwing are synced with RPCs
- Held players receive hold positions and throws from the holder

### Running two clients
Two clients are enabled by default when you launch from the Godot editor, so just press **Play**. If you ever need to change it, use **Debug > Customize Run Instances**.

## Controls

| Input | Action |
|---|---|
| Mouse | Look |
| Move keys | Move (`move_left`, `move_right`, forward/back) |
| `Jump` | Jump, wall jump, jump-mantle |
| `Climb` | Grab walls |
| `T` | Emote wheel (hold, then release) |
| `R` | Reset position |
| `Esc` | Release or capture the mouse |

Check **Project > Project Settings > Input Map** for the exact key bindings of sprint, crouch, grab and throw.

## Project layout

| File | What it does |
|---|---|
| `player.gd` | Player controller: movement, climbing, stamina, camera, bobbing, effects, animation, multiplayer |
| `main_camera.gd` | Standalone smoothed camera with sphere-sweep collision |

## Tuning guide

Almost everything is a constant at the top of `player.gd`, grouped by system. A few good starting points:

| Want to change | Look at |
|---|---|
| How floaty or snappy the camera follow is | `CAMERA_DEFAULT_SMOOTH_SPEED`, `CAMERA_ATTACH_SMOOTH_SPEED`, `LOOK_SMOOTHING` |
| Bob strength per state | `WALK_BOB_*`, `SPRINT_BOB_*`, `CLIMB_BOB_*`, `IDLE_BREATHE_*`, `UPHILL_BOB_*` |
| FOV feel | `FOV_DEFAULT`, `FOV_SPRINT`, `FOV_CLIMB`, `WALL_LUNGE_FOV_PUNCH`, `WALL_JUMP_FOV_PUNCH` |
| Stamina tremor | `CLIMB_SHAKE_*` |
| Landing and fall feel | `LANDING_DIP_*`, `FALL_*`, `RAGDOLL_*`, `RECOVERY_*` |
| Climb and wall-jump feel | `WALL_*`, `CLIMB_*`, `MANTLE_*`, `STAMINA_*` |
| Jump feel | `JUMP_*`, `GRAVITY_*`, `AIR_*` |

## Getting started

```
git clone https://gitlab.com/bamkanal/ducksgame.git
```

1. Open the project in **Godot 4**
2. Press **Play**. Two game windows open, one per player
3. Find a wall and start climbing

## Requirements

- Godot 4.x
- The addons used by the player scene: a wiggle-bone modifier (`DMWBWiggleRotationModifier3D`) and a tick interpolator (`TickInterpolator`) for networking

## Status

Work in progress demo. Camera and controller polish is the main focus.