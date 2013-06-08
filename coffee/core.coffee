class @Core
	@MEMORY_OFFSET = 0x200
	@CACHE_CODE = {}

	rom: new ROMParser
	display: new Display
	sound: new Sound
	keyboard: new Keyboard

	sprites:[
		0xF0,0x90,0x90,0x90,0xF0
		0x20,0x60,0x20,0x20,0x70
		0xF0,0x10,0xF0,0x80,0xF0
		0xF0,0x10,0xF0,0x10,0xF0
		0x90,0x90,0xF0,0x10,0x10
		0xF0,0x80,0xF0,0x10,0xF0
		0xF0,0x80,0xF0,0x90,0xF0
		0xF0,0x10,0x20,0x40,0x40
		0xF0,0x90,0xF0,0x90,0xF0
		0xF0,0x90,0xF0,0x10,0xF0
		0xF0,0x90,0xF0,0x90,0x90
		0xE0,0x90,0xE0,0x90,0xE0
		0xF0,0x80,0x80,0x80,0xF0
		0xE0,0x90,0x90,0x90,0xE0
		0xF0,0x80,0xF0,0x80,0xF0
		0xF0,0x80,0xF0,0x80,0x80
	]

	reset:->
		@display.init()
		#@rom.reset()

		Core.CACHE_CODE = {}

		@RAM 	= new Uint8Array(4096)
		@Stack 	= []
		#@SC 	= 0
		@V 		= new Uint8Array(16)
		@I 		= 0
		@DT 	= 0
		@ST 	= 0
		@PC 	= Core.MEMORY_OFFSET

		@stop = false
		@debug = false
		@iteration = 0

		@fillSprites()

		return @

	fillSprites:->
		for i,j in @sprites
			@RAM[j] = i

	loadROM: (rom)->
		@rom.loadFile rom,(file)=> @RAM.set file.file,Core.MEMORY_OFFSET

	decT:->
		if @DT
			 @DT--
		if @ST
			@sound.beep()
			@ST--

	incPC: (step)->
		@inc 'PC',step

	inc:(rg,step)->
		@[rg]+=step ? 2;

	step: ->
		for [0...10]
			unless @stop
				code = @getCode @PC
				@incPC()
				@decT()
				@exec code
			else
				break
		@timer() unless @stop
		code

	getCode: (addr = Core.MEMORY_OFFSET)->
		addrInc = addr
		unless Core.CACHE_CODE[addr]
			d0 = @RAM[addrInc++]
			d1 = @RAM[addrInc]
			data = []
			total = d0 << 8 | d1
			data.push data.code = total#.toString 16 # 2 byte 0
			data.push d0 >> 4 # first 4 bit 1
			data.push d0 & 0xF  # first second 4 bit 2
			data.push d1 >> 4   # last 4 bit 3
			data.push d1 & 0xF  # last second 4 bit 4
			data.push total & 0xFFF  # last 3 bit 5
			data.push d0 # first 8 bit 6
			data.push d1 # last 8 bit 7
			Core.CACHE_CODE[addr] = data
		Core.CACHE_CODE[addr]

	run:->	@timer() #@step() for i in @RAM by 2
	timer:(time=20,timer='DT')-> 
		requestAnimationFrame =>
		#setTimeout => 
			@step() 
		#,time 
	start:-> 
		@reset()
		@loadROM 'games/BRIX'

	exec: (op)-> 
		#console.log @PC,op[0].toString 16
		if @debug
			debugger
		switch op[1]
			when 0x0
				switch(op[5])
					when 0xEE
						#00EE	Returns from a subroutine.
						@PC = @Stack.shift()
					when 0xE0
						#00E0	Clears the screen. 
						@display.clear()
					else
						#0NNN	Calls RCA 1802 program at address NNN.
						@PC = op[5]
			when 0x1
				#1NNN	Jumps to address NNN.
				@PC = op[5]
			when 0x2
				#2NNN	Calls subroutine at NNN.
				@Stack.unshift @PC
				@PC = op[5]
			when 0x3
				#3XNN	Skips the next instruction if VX equals NN.
				if @V[op[2]] is op[7] then @incPC()
			when 0x4
				#4XNN	Skips the next instruction if VX doesn't equal NN.
				if @V[op[2]] isnt op[7] then @incPC()
			when 0x5
				#5XY0	Skips the next instruction if VX equals VY.
				if @V[op[2]] is @V[op[3]] then @incPC()
			when 0x6
				#6XNN	Sets VX to NN.
				@V[op[2]] = op[7]
			when 0x7
				#7XNN	Adds NN to VX.
				@V[op[2]] += op[7]
			when 0x8
				X = op[2]
				Y = op[3]
				switch op[4]
					when 0x0
						#8XY0	Sets VX to the value of VY.
						@V[X] = @V[Y]
					when 0x1
						#8XY1	Sets VX to VX or VY.
						@V[X] |= @V[Y]
					when 0x2
						#8XY2	Sets VX to VX and VY.
						@V[X] &= @V[Y]
					when 0x3
						#8XY3	Sets VX to VX xor VY.
						@V[X] ^= @V[Y]
					when 0x4
						#8XY4	Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
						sum = @V[X] + @V[Y]
						carry = if sum > 255 then 1 else 0
						@V[X] = sum
						@V[0xF] = carry
					when 0x5
						#8XY5	VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
						sub = @V[X] - @V[Y]
						carry = if @V[X] > @V[Y] then 1 else 0
						@V[X] = sub
						@V[0xF] = carry
					when 0x6
						###	
						8XY6	Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift.
								On the original interpreter, the value of VY is shifted, and the result is stored into VX. 
								On current implementations, Y is ignored.
						###
						carry = @V[X] & 0x1
						@V[X] >>= 1
						@V[0xF] = carry
					when 0x7
						#8XY7	Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
						sub = @V[Y] - @V[X]
						carry = if @V[Y] > @V[X] then 1 else 0
						@V[X] = sub
						@V[0xF] = carry
					when 0xE
						###
						8XYE	Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift.
								On the original interpreter, the value of VY is shifted, and the result is stored into VX. 
								On current implementations, Y is ignored.
						###
						carry = if @V[X] & 128 then 1 else 0
						@V[X] <<= 1
						@V[0xF] = carry
			when 0x9
				#9XY0	Skips the next instruction if VX doesn't equal VY
				if @V[X] isnt @V[Y] then @incPC()
			when 0xA 
				#ANNN	Sets I to the address NNN.
				@I=op[5]
			when 0xB
				#BNNN	Jumps to the address NNN plus V0.
				@PC=op[5]+@V[0]
			when 0xC 
				#CXNN	Sets VX to a random number and NN.
				@V[op[2]] = Math.random() * 0xFF  & op[7]
			when 0xD

				###
				DXYN	Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels.
						Each row of 8 pixels is read as bit-coded (with the most significant bit of each byte displayed 
						on the left) starting from memory location I; I value doesn't change after the execution of this
						instruction. As described above, VF is set to 1 if any screen pixels are flipped from set to unset
						when the sprite is drawn, and to 0 if that doesn't happen.
				###
				@V[0xF] = 0
				#@iteration++
				if @iteration is 103 then @debug = true
				coordX = @V[op[2]]
				coordY = @V[op[3]]
				height = op[4]
				for y in [0...height]
					sprite = @RAM[@I+y]
					for x in [0...8]
						@V[0xF] = 1 if @display.setPixel(coordX+x,coordY+y) if sprite & 128
						sprite <<= 1
				true
				#sprites = @RAM.subarray @I,@I+op[4]
				#@incI op[4]+2
			when 0xE
				#console.log @V[op[2]],@keyboard.key
				switch op[7]
					when 0x9E
						#EX9E	Skips the next instruction if the key stored in VX is pressed.
						if @V[op[2]] is @keyboard.key then @incPC()
					when 0xA1
						#EXA1	Skips the next instruction if the key stored in VX isn't pressed.
						if @V[op[2]] isnt @keyboard.key then @incPC()
			when 0xF
				switch op[7]
					when 0x07
						#FX07	Sets VX to the value of the delay timer.
						@V[op[2]] = @DT
					when 0x0A
						#FX0A	A key press is awaited, and then stored in VX.
						@stop = true;
						@keyboard.await (key)=>
							@V[op[2]] = @keyboard.key
							@stop=false
							@run()
					when 0x15
						#FX15	Sets the delay timer to VX.
						@DT = @V[op[2]]
					when 0x18
						#FX18	Sets the sound timer to VX.
						@ST = @V[op[2]]
					when 0x1E
						###
						FX1E	Adds VX to I.
								VF is set to 1 when range overflow (I+VX>0xFFF),
								and 0 when there isn't. This is undocumented feature of the Chip-8 and used by 
								Spacefight 2019! game.
						###
						sum = @I + @V[op[2]]
						carry = if sum>0xFFF then 1 else 0
						@I = sum
						@V[0xF] = carry
					when 0x29
						#FX29	Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font.
						@I = @V[op[2]] * 5
					when 0x33
						###
						FX33	Stores the Binary-coded decimal representation of VX, with the most significant of 
								three digits at the address in I, the middle digit at I plus 1, and the least significant
								digit at I plus 2. (In other words, take the decimal representation of VX, place the hundreds 
								digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.)
						###
						value = @V[op[2]]
						[@RAM[@I],@RAM[@I+1],@RAM[@I+2]] = [value/100%10,value/10%10,value%10]
					when 0x55
						###
						FX55	Stores V0 to VX in memory starting at address I.
								On the original interpreter, when the operation is done, I=I+X+1.
						###
						#value = @V[op[2]]
						@RAM[@I+i] = @V[i] for i in [0 .. op[2]]
						@inc 'I',op[2]+2
					when 0x65
						###
						FX65	Fills V0 to VX with values from memory starting at address I.
								On the original interpreter, when the operation is done, I=I+X+1
						###
						#value = @V[op[2]]
						@V[i] = @RAM[@I+i] for i in [0 .. op[2]]
						@inc 'I',op[2]+2
			else
				console.log "%s not recognized",op[0].toString 16


