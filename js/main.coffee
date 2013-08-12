
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

class Triangle
	constructor:->
		@trias = []

		@makeBase()

	makeBase:->
		@base = new Path [
						[view.center.x+0,view.center.y+10],
						[view.center.x+10,view.center.y+40]
						[view.center.x+60,view.center.y+40]
					]
		@base.fillColor = '#f1f1f1'
		@base.closed = true

		a = @addTriangle @base		
		for i in [0..1500]
			a = @addTriangle a

		

	addTriangle:(path)->
		base = new Path

		base.add new Point 
					x: path.segments[1].point.x + h.getRand -50, 50
					y: path.segments[1].point.y + h.getRand -50, 50

		base.segments[1] = path.segments[0]
		base.segments[2] = path.segments[1]

		@color ?= h.getRand(150,175)
		nextColor  = @color - (h.getRand -10,10)
		base.fillColor = "rgb(#{nextColor},#{nextColor},#{nextColor})"
		@color = nextColor
		base.closed = true

		# path.segments[1].point.y += 20

		@trias.push base

		@animate base
		
		base

	animate:->


	
	update:(e)->
		TWEEN.update()


triangle = new Triangle

onFrame = (e)->
	triangle.update()







