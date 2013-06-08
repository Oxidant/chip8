class @Display 
	container : null
	canvas : null
	context : null
	shadow : null
	config :
		width: 256
		height: 128
		orig_w:	64
		orig_h:	32
	_initialized : false
	data: Array(@::config.orig_w * @::config.orig_w)
	
	init:->
		if  !@_initialized
			@container = document.createElement 'div'
			document.body.appendChild @container

			@canvas = document.createElement 'canvas'
			@canvas.width = @config['orig_w']
			@canvas.height = @config['orig_h']
			@canvas.style.width = @config['width']+'px'
			@canvas.style.height = @config['height']+'px'
			@container.appendChild @canvas

			@context = @canvas.getContext '2d'
			@fill()
			@_initialized = true

	clear:->
		for i in [0 ... @data.length]
			@data[i] = 0
		@context.clearRect 0, 0, @canvas.width, @canvas.height
		@fill()

	fill:(color="black",x=0,y=0,width=@canvas.width,height=@canvas.height)->
		@context.fillStyle = color
		@context.fillRect x,y,width,height
	
	draw:()->
		for i in [0 ... @data.length]
			@data[i] = 0

	setPixel: (x,y)->
		#console.log(1)
		#debugger
		x = if x > @config['orig_w']
				x - @config['orig_w']
			else if x < 0
				@config['orig_w'] + x
			else x

		y = if y > @config['orig_h']
				y - @config['orig_h']
			else if y < 0
				@config['orig_h'] + y
			else y

		result = 1 ^ @getPixel x,y
		if result
			@fill "red",x,y,1,1
		else
			@fill "black",x,y,1,1

		!result
		#@data[] = result

	getPixel:(x,y)->
		pixel = @context.getImageData x,y,1,1
		return !!pixel.data[0];
	
	getCoords:(x,y)->



