-- Place this folder at GS\tier3\LegendSense-HelloWorld\.
-- LegendSense loads module.lua as the module entry point.

local message = "Hello World from LegendSense!"

print(message)

Callback.Bind(CallbackType.OnImguiDraw, function()
    Renderer.DrawText(message, Math.Vector2(30, 30), 20, 0xFFFFFFFF)
end)
