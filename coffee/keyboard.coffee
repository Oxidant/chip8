class @Keyboard
	key:null
	keyCode:null
	map:
	#49 50 51 52
		0x0:81 #q
		0x1:87 #w
		0x2:69 #e
		0x3:65 #a
		0x4:83 #s
		0x5:68 #d
		0x6:90 #z
		0x7:88 #x
		0x8:67 #c
		0x9:82 #r
		0xa:70 #f
		0xb:86 #v
		0xc:84 #t
		0xd:71 #g
		0xe:66 #b
		0xf:32 #space
	await_list:[]

	constructor:->
		document.addEventListener "keydown",@
		document.addEventListener "keyup",@

	await:(callback)->
		console.log "AWAIT"
		@await_list.push callback

	await_process:()->
		while callback = do @await_list.shift
			callback @key
		true

	getCode:(key)->
		return +i for i,j of @map when j is key

	handleEvent:(e)->
		switch e.type
			when "keydown"
				if e.keyCode isnt @keyCode and !@key
					if @key = @getCode e.keyCode
						@keyCode = e.keyCode
						do @await_process
					else
						@key = null
						@keyCode = null
			when "keyup"
				if e.keyCode is @keyCode
					@key = null
					@keyCode = null