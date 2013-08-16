
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


console.log TWEEN.Easing
console.log TWEEN.Easing.Elastic.Out


class String
	constructor:->
		@makeBase()

	makeBase:->
		@base = new Path
		
		@base.add [200,-5]
		@base.add [200,view.viewSize.height+5]

		@base.strokeColor = 'black'
		@base.strokeWidth = 4

	change:(point)->
		if point.x > 500 or point.x < 0 then return

		@base.segments[0].handleOut.y = point.y
		@base.segments[0].handleOut.x = point.x - 200

	animate:->
		from = 
			x: @base.segments[0].handleOut.x
			y: @base.segments[0].handleOut.y
		to = 
			x: 0
			y: 0

		tw = new TWEEN.Tween(from).to(to, 500)
		tw.easing (a)->
			b = Math.sin( a)
			console.log b
			b

		it = @
		tw.onUpdate ->
			it.base.segments[0].handleOut.x = @x
			it.base.segments[0].handleOut.y = @y

		tw.start()

string = new String

onFrame = (e)->
	TWEEN.update()


onMouseDrag = (e)->
	string.change e.point

onMouseUp = (e)->
	string.animate()









