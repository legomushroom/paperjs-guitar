
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
		@makeOsc()

		@makeBase()

	makeOsc:->
		@oscillator = @o.context.createOscillator() 
		@gainNode = @o.context.createGainNode()
		@gainNode.gain.value = 0.01
		@oscillator.connect @gainNode
		# @oscillator.type = 3
		@gainNode.connect @o.context.destination


		curveLength = 100;
		curve1 = new Float32Array(curveLength);
		curve2 = new Float32Array(curveLength);
		curve3 = new Float32Array(curveLength);

		for i in [0...curveLength]
			curve1[i] = Math.cos(Math.PI*i/(curveLength))*222

		for i in [0...curveLength]
			curve2[i] = Math.sin(Math.PI*i/(curveLength))*222

		for i in [0...curveLength]
			curve3[i] = Math.exp(Math.PI*i/(curveLength))

		waveTable = @o.context.createWaveTable( curve1, curve2, curve3)
		@oscillator.setWaveTable(waveTable)

	makeBase:->
		@base = new Path
		@base.add [@o.offset,-@o.width]
		@base.add [@o.offset,view.viewSize.height+@o.width]
		@base.strokeColor = @defaultColor
		@base.strokeWidth = @o.width
		# @base.opacity = .75



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

		@twSound = new TWEEN.Tween(from).to(to, @soundX)
		@twSound.easing (t)->

			b = Math.exp(-t*10)*Math.cos(Math.PI*2*t*10)
			if t >= 1 then return 1
			1 - b

		it = @
		@twSound.onStart =>
			@oscillator.connect @o.context.destination
			@oscillator?.noteOn 0

		@twSound.onUpdate ->
			it.oscillator.frequency.value = @c
		@twSound.onComplete =>
			@teardown()

		@twSound.start()

	teardown:->
		@oscillator?.disconnect()

		@base.segments[0].handleOut.x = 0
		@base.segments[0].handleOut.y = 0
		@anima = false
		@touched = false
		@base.strokeColor = @defaultColor



class Strings
	constructor:(o)->
		@initialOffset = 100
		@strings = []
		@stringWidth = 25
		@context = new webkitAudioContext()

		@makeStrings()
		@makebase()

	

	makebase:->
		@base = new Path.Circle [-100,-100], @stringWidth
		@base.fillColor = '#FFF'
		@base.opacity = .25

	mouseMove:(e)->
		@base.position = e.point

	makeStrings:(cnt=15)->
		for i in [0...cnt]
			string = new String
				offset: @initialOffset+(i*@stringWidth*3)
				width: @stringWidth
				context: @context

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




# class Note
# 	constructor:(o)->
# 		@o = o
# 		@makeBase()
# 		@animate()

# 	makeBase:(o)->
# 		@char = new PointText @o.point
# 		@char.characterStyle = 
# 			fontSize: 30
# 			font: 'ToneDeafBB'
# 			fillColor: @o.color

# 		@char.content = @o.char

# 	animate:->
# 		dfr = new $.Deferred
# 		@tw = new TWEEN.Tween(@o.point).to(new Point([@o.point.x+h.getRand(-50,50),-100]), 1000)
# 		it = @
# 		@tw.onUpdate ->
# 			it.char.position.x = @x
# 			it.char.position.y = @y

# 		@tw.onComplete =>
# 			dfr.resolve()
# 			$(@).trigger 'complete'

# 		@tw.start()
# 		dfr.promise()



# setInterval ->

# 	note = new Note(
# 		point: new Point [200,200]
# 		color: '#69D2E7'
# 		char: 'c'
# 	)

# 	$(note).on 'complete', ->
# 		`delete note`

# , h.getRand(200,400)





