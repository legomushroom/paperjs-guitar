
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
		@o.stringsOffset ?=  @o.width*15
		@touched = false
		@anima = false
		@colors = ["#69D2E7", "#A7DBD8", "#E0E4CC", "#F38630", "#FA6900", "#C02942", "#542437", "#53777A", "#ECD078", "#FE4365"]
		@defaultColor = "#333"
		@makeBase()

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
			
			return

		if @anima then return

		@base.segments[0].handleOut.y = point.y
		@base.segments[0].handleOut.x = point.x - @o.offset


	animate:->
		@touched = false
		if @anima then return
		if @base.segments[0].handleOut.x is 0 then return

		@soundX = parseInt Math.abs @base.segments[0].handleOut.x
		@soundY = parseInt Math.abs @base.segments[0].handleOut.y
		@soundY = @soundY/(view.viewSize.height+(2*@o.width))
		@animateQuake()
		@animateColor()

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
		@anima = true
		from = 
			x: @base.segments[0].handleOut.x
			y: @base.segments[0].handleOut.y
			c: 1
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
			
			# color = parseInt Math.abs (1-@c) * 255
			# if !color then (color = 255)
			# it.base.strokeColor = "rgb(#{color},#{color/2},#{color})"
		@tw.onComplete =>
			@teardown()

		@tw.start()

	teardown:->
		@base.segments[0].handleOut.x = 0
		@base.segments[0].handleOut.y = 0
		@anima = false
		@touched = false
		@base.strokeColor = @defaultColor

class Strings
	constructor:(o)->
		@initialOffset = 100
		@strings = []
		@stringWidth = 10
		@makeStrings()

		@guitarShape = [
					{
						start: new Point [672, @initialOffset]
						length: 10
					}
					{
						start: new Point [672, @initialOffset + @stringWidth*1.5]
						length: 10
					}
				]

		console.log @guitarShape

		@makebase()
		# @guitar = new Raster('guitar')
		# @guitar.position.y += 200

	makebase:->
		@base = new Path.Circle [-100,-100], @stringWidth
		@base.fillColor = '#FFF'
		@base.opacity = .85

	mouseMove:(e)->
		@base.position = e.point

	makeStrings:(cnt=15)->
		for i in [0...cnt]
			string = new String
				offset: @initialOffset+(i*@stringWidth*1.5)
				width: @stringWidth


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









