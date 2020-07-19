const std = @import("std");
const print = std.debug.print;

// Create SDL and SDL_gpu bindings
const sdl = @cImport(@cInclude("SDL.h"));
const gpu = @cImport(@cInclude("SDL_gpu.h"));

const SPRITE_COUNT = 100000;

fn runGPU() void {
    const gpuTarget = gpu.GPU_Init(1280, 720, gpu.GPU_DEFAULT_INIT_FLAGS);
    // TODO: Setting the camera moves its position, need ot figure out the right place
    // var camera = gpu.GPU_GetDefaultCamera();
    // camera.zoom_x = 0;
    // camera.zoom_y = 0;
    // _ = gpu.GPU_SetCamera(gpuTarget, &camera);

    const image = gpu.GPU_LoadImage("../crash-the-stack/dist/assets/images/tile.png");
    gpu.GPU_SetSnapMode(image, gpu.GPU_SnapEnum.GPU_SNAP_NONE);
    
    var fps: f32 = -1.0;
    var lastFrameTime: u32 = sdl.SDL_GetTicks();
    var currentFrameTime: u32 = 0;
    var timeStep: f32 = 0;
    var lastFpsPrint = lastFrameTime;

    while (true) {
      currentFrameTime = sdl.SDL_GetTicks();
      timeStep = @intToFloat(f32, currentFrameTime - lastFrameTime) / 1000.0;

      if (fps > -1.0) {
        fps = (fps * 0.95) + (0.05 * (1.0 / timeStep));
      } else if (timeStep > 0.0) {
        fps = 1.0 / timeStep;
      }

      sdl.SDL_PumpEvents();
      const state = sdl.SDL_GetKeyboardState(null);
      if (state[sdl.SDL_SCANCODE_ESCAPE] > 0) {
        break;
      }

        gpu.GPU_Clear(gpuTarget);

        var i: usize = 0;
        while (i < SPRITE_COUNT) {
            gpu.GPU_Blit(image, null, gpuTarget, 0, 0);
            i += 1;
        }

        gpu.GPU_Flip(gpuTarget);

      lastFrameTime = currentFrameTime;
      if (currentFrameTime - lastFpsPrint > 1000) {
        lastFpsPrint = currentFrameTime;
        print("fps: {d:.3}\n", .{fps});
      }
    }
    print("Exiting...\n", .{});

    gpu.GPU_Quit();
}

pub fn main() anyerror!void {
    runGPU();
}
