# WoW-Profiler
Investigating the plausibility of a proper profiler for WoW Lua as an addon.

## Concerns
*The* main issue is locals. As far as I can tell, there is no way to both get the name of locals (somewhat possible) and their values (impossible) automatically. This means that local functions are all but invisible to the profiler.

Since the Profiler is mostly intended for addon developers, this problem could be alleviated by having devs explicitly supporting it... However, this requires an API that is neither ugly nor overly verbose to use, and that has minimal performance impact when the Profiler is not loaded. Yet at the same time, it has to be useful enough that devs will bother.

## Viable
On a more positive note, a brief list of improvements and additions that _are_ possible:
- A GUI, obviously. Current visual inspiration may be summarized as a cross between [Table explorer](https://mods.curse.com/addons/wow/table-explorer) and [Skada](https://mods.curse.com/addons/wow/skada) but with more columns ;)
- Frames, event handlers and all public functions will be mostly correctly attributed by addon. Some addons (such as Clique) that creates frames and such as a reaction to other addons being loaded might need special handling.
- "Called by" is probably possible, including calls from local functions.
- Greatly improved startup times: it currently traverses the whole global namespace each time an addon is loaded. A combination of __newindex and caching names in a SavedVariables DB should be much faster.
