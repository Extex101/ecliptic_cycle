  
### `ecliptic_cycle.register_effect(name, col1, col2)`

**Parameters**:

-  `name`: Name of the effect.

-  `col1`: First color (hex).

-  `col2`: Second color (hex).

**Description**:

Add a new custom effect to the list drawn from at every major event.

---

### `ecliptic_cycle.update_players()`

**Description**:

Updates the moon for all players.

---

### `ecliptic_cycle.get_day()`

**Returns**: `number`: Current day including phase offset.

---

### `ecliptic_cycle.random_color(min, max, fac)`
**Parameters**:

-  `min`: Minimum number passed to the random.
- `max`: Max number passed to the random.
- `fac`: Number between 0-1 determining how much of the saturation is kept. 0 being fully desaturated and 1 being the original random color.

**Returns**:

- `string`: Hex code.

**Example usage**:
```lua
local shadows = ecliptic_cycle.random_color(10, 100, 0.3)
local highlights = ecliptic_cycle.random_color(150, 255, 0.8)
ecliptic_cycle.set_effect(shadows, highlights)
```

---
### `ecliptic_cycle.set_effect(...)`

Takes 1 string/number:

**param1** = `number`: 0-1 sets randomly generated color and keeps a percentage of the saturation defined in param1.

**param1** = `string`:

-  `Effect Name`: Sets the effect to the registered effect by it's name.

-  `#hex1 #hex2`: Sets the effect with hex1 as the shadows and hex2 as highlights.

  

Or 2 strings:

**param1**: `hex`

**param1**:`hex`

  

**Returns**:

-  `boolean`: Whether the operation succeeded.

-  `string`: A status message.

  

**Examples**:

```lua

ecliptic_cycle.set_effect(0.5) -- Random Colors, with 50% saturation

ecliptic_cycle.register_effect("Cosmic Clockwork", "#09362b", "#926e45")

ecliptic_cycle.set_effect("Cosmic Clockwork") -- Sets the effect to one from the pre-registered list.

  

--These two are fuctionally the same

ecliptic_cycle.set_effect("#ff00ff", "#ffffff")

ecliptic_cycle.set_effect("#ff00ff #ffffff")

-- In both cases: The first color sets the shadows

-- The second color sets the highlights.

```
---

  

### `ecliptic_cycle.is_event(day)`

**Parameters**:

-  `day`: Day number.

  

**Returns**:

-  `boolean`: majorEvent (effect shuffle)

-  `boolean`: minorEvent (desaturated random color)

  

**Description**:

- Major events happen around once every 15-150~ days. (3-7 times per 365 days)

- Minor events happens every 1-15 days.

  

---

  

### `ecliptic_cycle.update_player_moon(player)`

**Parameters**:

-  `player`: playerRef.

  

**Description**:

Gets the current phase texture and applies the effect (if needed) and set's the moon texture for that player.

  

---

  

### `ecliptic_cycle.update_phase()`

**Description**:

Sets the current phase based on the day and checks for events.

  

---

  

### `ecliptic_cycle.get_phase(day)`

**Parameters**:

-  `day`: (optional) day number, like that from core.get_day_count()

  

**Returns**:

-  `number`: Phase index.

  

**Description**:

Returns the current lunar phase index. 0-29.

If day is given it will return the phase for that day (plus the phase offset)

If no day is given it will return the phase for the current day

  

---

  

### `ecliptic_cycle.get_effect()`

**Returns**:

-  `table`: `{color1, color2}` hex color or nil (if no effect is set)

-  `string`: effect type. "Effect Name", "random", "none", or "custom"

  

**Description**:

-  `custom`: Color was set using two hex codes.

-  `random`: Color was set using a saturation percentage number.

-  `Doom`: (example name) Color was set using this name.

-  `none`: No effect is applied. Default moon is set.

  

---
