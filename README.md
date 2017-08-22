# Profiler for World of Warcraft
A profiler for WoW addons that tries to go deeper.

## Usage
- Will automatically find functions in the global namespace and try to group them by addon structure
- Addons can easily improve functionality by exposing local tables globally like so:
 `if Profiler then _G.PublicTable = privateTable end`

 ## Changes
 Want to get an idea of what has changed since last time? I recommend checking out the  [release](https://github.com/dualcoding/wow-profiler/releases) page.

## Roadmap
Want to know what comes next? [Milestones](https://github.com/dualcoding/wow-profiler/milestones) is the place to go to. In particular, have a look at features that are [currently](https://github.com/dualcoding/wow-profiler/milestones/current) in development, and those likely to be worked on  [next](https://github.com/dualcoding/wow-profiler/milestones/next).

## Suggestions
Feel free to open issues and pull request, and let me know what you think!
