class @ROMParser
	file:null
	url:null
	constructor:(file,callback=->)->
		@loadFile file,callback if file?
		
	loadFile: (file,callback=->)->
		@url = file
		@ajax file,(xhr)=>
			buffer = xhr.response
			@file = new Uint8Array buffer
			callback @

	ajax: (url,callback=->)->
		xhr = new XMLHttpRequest
		xhr.open 'get',url,true
		xhr.onload = ()->callback xhr
		xhr.responseType = "arraybuffer"
		xhr.send null
		xhr