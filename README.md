# Profiler for World of Warcraft
A profiler for WoW addons that tries to go deeper.

## Usage
- Will automatically find functions in the global namespace and try to group them by addon structure
- Addons can easily improve functionality by exposing local tables globally like so:
 `if Profiler then _G.PublicTable = privateTable end`

## Upcoming
- Add columns with memory, startup times and number of times called and allow sorting by these.
- Make the UI a bit more user friendly and less ugly overall.

## Latest release: [0.2] 2017-08-20
### Changed
- Entries with the same CPU time (usually 0) are sorted in alphabetical order.
- Tables not containing any child functions are no longer shown.
### Fixed
- Should no longer cause taint.
- The sorting of entries is stable, preventing them from jumping around.
- Cycle detection no longer prevents duplicates.
