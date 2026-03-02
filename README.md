
# Robot Arm Control (4-DOF) — MATLAB + Arduino

A MATLAB GUI that controls a 4-DOF servo robot arm using an Arduino. Users can command joint angles through sliders/buttons and observe consistent motion response.

## Tech Stack
- MATLAB (App Designer / .m GUI logic)
- Arduino (servo control)
- Serial communication (COM port) / MATLAB Arduino Support Package
- 4x servo motors (4-DOF)

## Features
- GUI sliders/buttons to set joint angles
- Commands sent from MATLAB to Arduino for real-time actuation
- Basic pick-and-place style control workflow (manual positioning)

## Project Structure
- `src/` — source code (MATLAB)
- `docs/` — report and slides
- `media/` — demo video and screenshots

## How to Run
1. Connect Arduino to your computer via USB.
2. Open MATLAB and run the main script:
   - `src/RobotArmControl.m`
3. Select the correct COM port (if required) and control joints using the GUI.

> Note: Arduino is controlled via MATLAB Arduino Support Package / serial commands. No separate `.ino` file is included in this repository.

## Demo
- Video: `media/demo.mp4`

## Future Improvements
- Add joint limit checks and smoother motion (ramping)
- Save/load presets for common poses
- Add inverse kinematics for point-to-point control
