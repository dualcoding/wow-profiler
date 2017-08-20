# Profiler for World of Warcraft
A profiler for WoW addons that tries to go deeper.

## Usage
- Will automatically find functions in the global namespace and try to group them by addon structure
- Addons can easily improve functionality by exposing local tables globally like so:
 `if Profiler then _G.PublicTable = privateTable end`

## Upcoming
- Add column for startup times.
- Make the UI a bit more user friendly and less ugly overall.

## Latest release: [0.3] 2017-08-20
### Added
- Header showing column names
- Column "mem/ncalls" for memory and times called
- The sorting of entries can be changed by clicking on the header
