# Profiler for World of Warcraft
A profiler for WoW addons that tries to go deeper.

## Current functionality
- Will automatically find functions in the global namespace and try to group them by addon structure
- Addons can easily improve functionality by exposing local tables globally like so:
 `if Profiler then _G.PublicTable = privateTable end`

## Roadmap
- Improve the user interface
- Provide more functionality to addon developers
