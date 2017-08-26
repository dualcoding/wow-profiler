# Profiler for World of Warcraft
A profiler for WoW addons that tries to go deeper.

## For users
Find out which addons...
- Are increasing your startup times the most.
- Have the heaviest CPU-cost while the game is running.
- (not yet) ~~Causes the most frequent and heaviest CPU spikes.~~

## For developers
- Shows the total CPU used per function and times called.
- Tries to figure out what functions belongs to which mod:
    - Will automatically find functions in the global namespace and try to group them by addon structure.
    - Addons can easily improve functionality by exposing local tables globally like so: `if Profiler then _G.PublicTable = privateTable end`.
- (not yet) ~~Show further information about a function, such as who calls it and what it calls in turn.~~

## Follow the development
Each [release](https://github.com/dualcoding/wow-profiler/releases) documents what has changed since the last one.

 [Milestones](https://github.com/dualcoding/wow-profiler/milestones) acts as a rough roadmap for future development. Have a look what is [currently](https://github.com/dualcoding/wow-profiler/milestones/current) in development or what is likely to be worked on [next](https://github.com/dualcoding/wow-profiler/milestones/next).

## Suggestions
Feel free to open issues and pull request, and let me know what you think!
