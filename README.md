
# Machine
*A state machine written in MoonScript*

**Importing with [Neon](https://github.com/Belkworks/NEON)**:
```lua
_ = NEON:github('belkworks', 'machine')
```

This module is in progress and the API is still evolving!  
Documentation will come soon.

## Example (MoonScript)

```moonscript
X = Machine
	States:
		Open: =>
			@on 'close', 'Closed'
			@entry -> print 'opened'

		Closed: =>
			@initial!

			@entry -> print 'closed'
			@exit -> print 'going to open'

			@on 'open', 'Open'

			@substate
				Idle: =>
					@on 'start', 'Cooking'
					@entry -> print 'idle'
					@initial!

				Cooking: =>
					@entry -> print 'cooking now'
					@exit -> print 'not cooking'
					@on 'stop', 'Idle'

X\input 'start'
X\input 'open'
```

This example prints the following output:

```
closed
idle
cooking now
not cooking
going to open
opened
```
