
Path::setWidth = (width)->
    @segments[3].point.x = @segments[0].point.x + width
    @segments[2].point.x = @segments[1].point.x + width

Path::setHeight = (height)->
    @segments[1].point.y = @segments[0].point.y + height
    @segments[2].point.y = @segments[3].point.y + height

Path::reset = ->
	@setWidth 0
	@setHeight 0
	@smooth()

h = 
	getRand:(min,max)->
		Math.floor((Math.random() * ((max + 1) - min)) + min)

view.setViewSize $(window).outerWidth(), $(window).outerHeight()


mouseDown = null
mouseMove = null
mouseDrag = null
class String
	constructor:(o)->
		@o = o
		@touched 	= false
		@anima 	= false
		@colors = ["#69D2E7", "#A7DBD8", "#E0E4CC", "#F38630", "#FA6900", "#C02942", "#542437", "#53777A", "#ECD078", "#FE4365"]
		@defaultColor = @o.color or "#fff"
		@makeAudio()
		@makeBase()
		@o.stringsOffset ?=  @o.width*30

	makeAudio:->
		@analyser = @o.context.createAnalyser()
		@audio = new Audio
		@audio.controls = true
		@audio.src = "sounds/#{ @o.guitar.sources[@o.i % @o.guitar.sources.length]}.mp3"
		@source = @o.context.createMediaElementSource(@audio)
		@source.connect @analyser
		@analyser.connect @o.context.destination


	makeBase:->
		@base = new Path
		@xOffset = @o.offset
		
		@base.add [@o.offsetX_start, @o.offsetY_start ]
		@base.add [@o.offsetX_end, @o.offsetY_end]
		
		@startX 	= 	Math.min @o.offsetX_start, @o.offsetX_end
		@startY 	= 	Math.min @o.offsetY_start, @o.offsetY_end
		@endX 	= 	Math.max @o.offsetX_start, @o.offsetX_end
		@endY 	= 	Math.max @o.offsetY_start, @o.offsetY_end

		@middleX 	=  		if (@endX isnt @startX) then parseInt((@endX - @startX)/2) else @endX
		@middleX_point =  	if (@endX isnt @startX) then @endX - @middleX else @endX

		@middleY 	=  		if (@endY isnt @startY) then parseInt((@endY - @startY)/2) else @endY
		@middleY_point =  	if (@endY isnt @startY) then @endY - @middleY else @endY

		@base.strokeColor = @defaultColor
		@base.strokeWidth = @o.width

		@height = @o.offsetY_end - @o.offsetY_start

	change:(e)->
		point = e.point	
		@a = null
		if @anima then return


		if e.delta.x > 0
			if  ((e.point+e.delta).x >= @startX) and (mouseDown.x < @startX)
				if ((e.point+e.delta).y >= @startY) and ((e.point+e.delta).y <= @endY)
					@touched = true

		if e.delta.x < 0
			if  ((e.point-e.delta).x <= @endX) and (mouseDown.x > @endX)
				if ((e.point+e.delta).y > @startY) and ((e.point+e.delta).y <@endY)
					@touched = true

		if e.delta.y < 0
			if ((e.point+e.delta).y <=@endY) and (@startY <  mouseDown.y)
				if ((e.point+e.delta).x > @startX) and ((e.point+e.delta).x < @endX)
					@touched = true

		if e.delta.y > 0
			if ((e.point+e.delta).y >= @startY) and (@o.offsetY_end >  mouseDown.y)
				if ((e.point+e.delta).x > @startX) and ((e.point+e.delta).x < @endX)
					@touched = true

		

		if !@touched then return

		x_plus = ((point.x  > @middleX_point + @o.stringsOffset) and (e.delta.x > 0))
		x_minus = ((point.x  < @middleX_point - @o.stringsOffset) and (e.delta.x < 0))

		y_plus = ((point.y  > @middleY_point + @o.stringsOffset) and (e.delta.y > 0))
		y_minus = ((point.y  < @middleY_point - @o.stringsOffset) and (e.delta.y < 0))

		if (x_plus or x_minus or y_plus or y_minus)
				@animate()
				return


		x = if @o.offsetX_end < @o.offsetX_start then @endX else @startX
		y = if @o.offsetY_end < @o.offsetY_start then @endY else @startY

		@base.segments[0].handleOut.y = point.y - y
		@base.segments[0].handleOut.x = point.x - x


	animate:->
		@touched = false
		if @anima then return
		@anima = true

		@soundX = parseInt Math.abs @base.segments[0].handleOut.x
		@soundY_proto = parseInt Math.abs @base.segments[0].handleOut.y
		@soundY = @soundY_proto/(@height+(2*@o.width))
		@meter = Math.max @soundX, @soundY_proto
		@animateQuake()
		@animateColor()
		@makeSound()

	animateColor:->
		@twColor?.stop()
		@base.strokeColor = @colors[@index % @colors.length]
		@base.strokeColor.saturation = 4
		from = 
			t:0
		to = 
			t:1

		@twColor = new TWEEN.Tween(from).to(to, @meter*15)
		@twColor.easing (t)->

			b = Math.exp(-t*10)*Math.cos(Math.PI*2*t*10)
			if t >= 1 then return 1
			1 - b

		it = @
		@twColor.onUpdate ->
			it.base.strokeColor.brightness = @t

		@twColor.start()


	animateQuake:->
		@tw?.stop()
		@anima = true
		from = 
			x: @base.segments[0].handleOut.x
			y: @base.segments[0].handleOut.y
			c: 1000 * @index
		to = 
			x: 0
			y: 0
			c: 0

		@tw = new TWEEN.Tween(from).to(to, 1000)
		@tw.easing (t)->

			b = Math.exp(-t*10)*Math.cos(Math.PI*2*t*10)
			if t >= 1 then return 1
			1 - b


		it = @

		@tw.onStart =>
			if @startY isnt @endY
				it.base.segments[0].handleOut.y = 0


		@tw.onUpdate ->
			it.base.segments[0].handleOut.x = @x
			if @startY is @endY
				it.base.segments[0].handleOut.y = @y
			
		@tw.onComplete =>
			@teardown()

		@tw.start()

	makeSound:->
		@twSound?.stop()

		from = 
			c: 2*(@index*25) + @soundX/4
			t:1
		to = 
			c: (@index*25) + @soundX/4
			t:0

		@twSound = new TWEEN.Tween(from).to(to, @meter*6)
		@twSound.easing (t)->

			b = Math.exp(-t*10)*Math.cos(Math.PI*2*t*10)
			if t >= 1 then return 1
			1 - b

		it = @
		@twSound.onStart =>
			@audio.play()
			@played = true

		@twSound.onComplete =>
			if @played
				@stopAudio()
			@teardown()

		@twSound.start()

	stopAudio:->
		if @played
			@audio?.pause()
			@audio?.currentTime = 0

	teardown:->
		@stopAudio()
		@base.segments[0].handleOut.x = 0
		@base.segments[0].handleOut.y = 0
		@anima = false
		@touched = false
		@base.strokeColor = @defaultColor





class Char 
	constructor:(o)->
		@o = o
		@width = @o.width or 3
		for item, i in text[@o.symbol]
			string = new String
				offsetX_start: item.offsetX_start 	+ @o.xOffset
				offsetX_end: 	item.offsetX_end 	+ @o.xOffset
				offsetY_start: item.offsetY_start 	+ @o.yOffset
				offsetY_end: 	item.offsetY_end 	+ @o.yOffset
				width: @width
				context: @o.context
				guitar: @o.guitar
				color: '#fff'
				i: i

			string.index = i

			@o.guitar.strings.push string



class Strings
	constructor:(o)->
		@initialOffset = 300
		@strings = []
		@stringWidth = 5
		@context = new webkitAudioContext()
		@sources = ['a3', 'b2', 'd3', 'e2', 'g2', 'a2', 'c', 'd2', 'f', 'g1', 'a1', 'b1', 'd1', 'e1']

		@makeStrings()
		@makebase()

		@makeM()

	makebase:->
		@base = new Path.Circle [-100,-100], @stringWidth*2
		@base.fillColor = '#FFF'
		@base.opacity = .25

		@guitar = new Raster 'guitar'
		@guitar.position.y += 450
		@guitar.position.x += 450


	mouseMove:(e)->
		@base.position = e.point

	makeStrings:(cnt=15)->
		for i in [0...cnt]
			o = @getOffset i
			stringOffset = @stringWidth*5
			offsetX = @initialOffset+(i*stringOffset)
			if i is 13 then offsetX = @initialOffset+(5*stringOffset)
			if i is 14 then offsetX = @initialOffset+(7*stringOffset)
			string = new String(
				offsetX_start: offsetX
				offsetX_end: offsetX
				offsetY_start: o.offsetY
				offsetY_end: o.offsetY + o.length
				width: @stringWidth
				context: @context
				guitar: @
				i: i )

			string.index = i
			@strings.push string

	makeM:->
		@y 	= 150
		@y2 	= 330
		@x 	= 650
		@x2 	= 200
		new Char
			context: @context
			guitar: @
			symbol: 'M'
			xOffset: @x + 28
			yOffset: @y

		new Char
			context: @context
			guitar: @
			symbol: 'U'
			xOffset: @x + 170
			yOffset: @y

		new Char
			context: @context
			guitar: @
			symbol: 'S'
			xOffset: @x + 262
			yOffset: @y

		new Char
			context: @context
			guitar: @
			symbol: 'I'
			xOffset: @x + 352
			yOffset: @y

		new Char
			context: @context
			guitar: @
			symbol: 'C'
			xOffset: @x + 394
			yOffset: @y

		# SPACE

		new Char
			context: @context
			guitar: @
			symbol: 'T'
			xOffset: @x2 + 518
			yOffset: @y2

		new Char
			context: @context
			guitar: @
			symbol: 'I'
			xOffset: @x2 + 620
			yOffset: @y2

		new Char
			context: @context
			guitar: @
			symbol: 'M'
			xOffset: @x2 + 668
			yOffset: @y2

		new Char
			context: @context
			guitar: @
			symbol: 'E'
			xOffset: @x2 + 808
			yOffset: @y2




	getOffset:(i)->
		size = {}
		switch i
			when 0
				size.length = 130
				size.offsetY = 705

			when 1
				size.length = 205
				size.offsetY = 650

			when 2
				size.length = 375
				size.offsetY = 490

			when 3
				size.length = 395
				size.offsetY = 480

			when 4
				size.length = 405
				size.offsetY = 475

			when 5
				size.length = 405
				size.offsetY = 475

			when 6
				size.length = 860
				size.offsetY = 20

			when 7
				size.length = 405
				size.offsetY = 475

			when 8
				size.length = 405
				size.offsetY = 475

			when 9
				size.length = 395
				size.offsetY = 480

			when 10
				size.length = 375
				size.offsetY = 490

			when 11
				size.length = 205
				size.offsetY = 650

			when 12
				size.length = 130
				size.offsetY = 705

			when 13, 14
				size.length = 120
				size.offsetY = 25
		size



	makeQuake:->
		for string, i in @strings
			string.animate()

	changeStrings:(point)->
		for string, i in @strings
			string.change point

	teardown:->
		TWEEN.removeAll()
		for string, i in @strings
			string.teardown()

strings = new Strings


class Note
	constructor:(o)->
		@o = o


new Note

onFrame = (e)->
	TWEEN.update()


onMouseDrag = (e)->

	strings.changeStrings e
	strings.mouseMove e

onMouseDown = (e)->
	strings.teardown()
	mouseDown = e.point


onMouseUp = (e)->
	strings.makeQuake()



onMouseMove = (e)->
	mouseMove = e.point
	strings.mouseMove e

