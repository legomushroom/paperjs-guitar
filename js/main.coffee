
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
		@o.stringsOffset ?=  @o.width*20
		@touched = false
		@anima = false
		@colors = ["#69D2E7", "#A7DBD8", "#E0E4CC", "#F38630", "#FA6900", "#C02942", "#542437", "#53777A", "#ECD078", "#FE4365"]
		@defaultColor = "#222"
		@makeAudio()


		@makeBase()

	makeAudio:->
		@analyser = @o.context.createAnalyser()
		@audio = new Audio
		@audio.controls = true
		console.log "sounds/#{ @o.guitar.sources[@o.i % @o.guitar.sources.length]}.mp3"
		@audio.src = "sounds/#{ @o.guitar.sources[@o.i % @o.guitar.sources.length]}.mp3"
		@source = @o.context.createMediaElementSource(@audio)
		@source.connect @analyser
		@analyser.connect @o.context.destination


	makeBase:->
		@base = new Path
		@base.add [@o.offset,-@o.width]
		@base.add [@o.offset,view.viewSize.height+@o.width]
		@base.strokeColor = @defaultColor
		@base.strokeWidth = @o.width



	change:(e)->
		if e.delta.x > 0
			if  ((e.point+e.delta).x >= @o.offset) and @o.offset >  mouseDown.x
				@touched = true

		if e.delta.x < 0
			if  ((e.point-e.delta).x <= @o.offset) and @o.offset <  mouseDown.x
				@touched = true

		point = e.point		
		if !@touched then return

		if (point.x > (@o.offset + @o.stringsOffset)) or (point.x <( @o.offset - @o.stringsOffset ))
			@animate()
			return

		if @anima then return

		@base.segments[0].handleOut.y = point.y
		@base.segments[0].handleOut.x = point.x - @o.offset


	animate:->
		@touched = false
		if @anima then return
		@anima = true

		if @base.segments[0].handleOut.x is 0 then return

		@soundX = parseInt Math.abs @base.segments[0].handleOut.x
		@soundY = parseInt Math.abs @base.segments[0].handleOut.y
		@soundY = @soundY/(view.viewSize.height+(2*@o.width))
		@animateQuake()
		@animateColor()
		@makeSound()

	animateColor:->
		@twColor?.stop()
		@base.strokeColor = @colors[@index % @colors.length]
		@base.strokeColor.saturation = @soundY*4
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
		@initialOffset = 200
		@strings = []
		@stringWidth = 25
		@context = new webkitAudioContext()
		@sources = ['a3', 'b2', 'd3', 'e2', 'g2', 'a2', 'c', 'd2', 'f', 'g1', 'a1', 'b1', 'd1', 'e1']

		@makeStrings()
		@makebase()

	

	

	makebase:->
		@base = new Path.Circle [-100,-100], @stringWidth*2
		@base.fillColor = '#FFF'
		@base.opacity = .25

	mouseMove:(e)->
		@base.position = e.point

	makeStrings:(cnt=14)->
		for i in [0...cnt]
			string = new String(
				offset: @initialOffset+(i*@stringWidth*2.5)
				width: @stringWidth
				context: @context
				guitar: @
				i: i )

			string.index = i

			@strings.push string

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

