class @Sound
	audioContext: null
	context: null
	running: false
	constructor:->
		@audioContext = new window.webkitAudioContext

	beep:->
		do @start
		setTimeout => 
			do @stop
		, 100

	start:->
		unless @running
			@context = do @audioContext.createOscillator
			@context.connect @audioContext.destination
			@context.type = 3
			@context.noteOn 0
			@running = true
	stop:->
		@running = false
		@context.noteOff 0