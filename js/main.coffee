
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
		@touched = false
		@anima = false
		@colors = ["#69D2E7", "#A7DBD8", "#E0E4CC", "#F38630", "#FA6900", "#C02942", "#542437", "#53777A", "#ECD078", "#FE4365"]
		@defaultColor = "#fff"
		@makeAudio()
		@makeBase()
		@o.stringsOffset ?=  @o.width*15

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
		@base.add [@o.offset, @o.offsetY ]
		@base.add [@o.offset, @o.offsetY + @o.length]
		@base.strokeColor = @defaultColor
		@base.strokeWidth = @o.width

		@height = @o.length

	change:(e)->
		if e.delta.x > 0
			if  ((e.point+e.delta).x >= @o.offset) and @o.offset >  mouseDown.x
				if ((e.point+e.delta).y > @o.offsetY) and ((e.point+e.delta).y < @o.offsetY + @o.length)
					@touched = true

		if e.delta.x < 0
			if  ((e.point-e.delta).x <= @o.offset) and @o.offset <  mouseDown.x
				if ((e.point+e.delta).y > @o.offsetY) and ((e.point+e.delta).y < @o.offsetY + @o.length)
					@touched = true

		point = e.point		
		if !@touched then return

		if (point.x > (@o.offset + @o.stringsOffset)) or (point.x <( @o.offset - @o.stringsOffset ))
			@animate()
			return

		if @anima then return

		@base.segments[0].handleOut.y = point.y - @o.offsetY
		@base.segments[0].handleOut.x = point.x - @o.offset


	animate:->
		@touched = false
		if @anima then return
		@anima = true

		if @base.segments[0].handleOut.x is 0 then return

		@soundX = parseInt Math.abs @base.segments[0].handleOut.x
		@soundY = parseInt Math.abs @base.segments[0].handleOut.y
		@soundY = @soundY/(@height+(2*@o.width))
		@animateQuake()
		@animateColor()
		@makeSound()

	animateColor:->
		@twColor?.stop()
		@base.strokeColor = @colors[@index % @colors.length]
		@base.strokeColor.saturation = 1
		from = 
			t:0
		to = 
			t:1

		@twColor = new TWEEN.Tween(from).to(to, @soundX*6)

		it = @
		@twColor.onUpdate ->
			it.base.strokeColor.brightness -= @t/8
			if it.base.strokeColor.brightness <= 0.1
				it.base.strokeColor = it.defaultColor

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

		@tw.onUpdate ->
			it.base.segments[0].handleOut.x = @x
			# it.base.segments[0].handleOut.y = @y
			
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

		@twSound = new TWEEN.Tween(from).to(to, @soundX*6)
		@twSound.easing (t)->

			b = Math.exp(-t*10)*Math.cos(Math.PI*2*t*10)
			if t >= 1 then return 1
			1 - b

		it = @
		@twSound.onStart =>
			@audio.play()

		@twSound.onComplete =>
			@stopAudio()

			@teardown()

		@twSound.start()

	stopAudio:->
		@audio.pause()
		@audio.currentTime = 0

	teardown:->
		@stopAudio()

		@base.segments[0].handleOut.x = 0
		@base.segments[0].handleOut.y = 0
		@anima = false
		@touched = false
		@base.strokeColor = @defaultColor



class Strings
	constructor:(o)->
		@initialOffset = 300
		@strings = []
		@stringWidth = 5
		@context = new webkitAudioContext()
		@sources = ['a3', 'b2', 'd3', 'e2', 'g2', 'a2', 'c', 'd2', 'f', 'g1', 'a1', 'b1', 'd1', 'e1']

		@makeStrings()
		@makebase()

	makebase:->
		@base = new Path.Circle [-100,-100], @stringWidth*2
		@base.fillColor = '#FFF'
		@base.opacity = .25

		@guitar = new Raster 'guitar'
		@guitar.position.y += 450
		@guitar.position.x += 450

		@text = new Raster 'text'
		@text.position.y += 1000
		@text.position.x += 450

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
				offset: offsetX
				offsetY: o.offsetY
				length: o.length
				width: @stringWidth
				context: @context
				guitar: @
				i: i )

			string.index = i

			@strings.push string

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


class M
	constructor:->

		string = new String(
				offset: 100
				offsetY: 100
				length: 100
				width: 	5
				context: @context
				guitar: @
				i: i )


onFrame = (e)->
	TWEEN.update()


onMouseDrag = (e)->
	# strings.teardown()
	strings.changeStrings e
	strings.mouseMove e
	mouseDrag = e.point

onMouseDown = (e)->
	strings.teardown()

	mouseDown = e.point


onMouseUp = (e)->
	strings.makeQuake()


onMouseMove = (e)->
	mouseMove = e.point
	strings.mouseMove e

