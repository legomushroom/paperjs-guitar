
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

		@base.sides = [
				{
					isFree:true
				},

				{
					isFree:true
				},

				{
					isFree:true
				}
			]

		a = @addTriangle @base		
		# for i in [0..1500]
		# 	a = @addTriangle a

		

	addTriangle:(path)->
		base = new Path
		base.sides = [
				{
					isFree:true
				},

				{
					isFree:true
				},

				{
					isFree:true
				}
			]

		isFoundSide = false

		side = -1
		if path.sides[0].isFree and !isFoundSide
			base.segments[0] = path.segments[0]
			base.segments[1] = path.segments[1]
			base.sides[0].isFree = false
			path.sides[0].isFree = false
			side = 0
			isFoundSide = true

		if path.sides[1].isFree and !isFoundSide
			base.segments[0] = path.segments[1]
			base.segments[1] = path.segments[2]
			base.sides[0].isFree = false
			path.sides[1].isFree = false
			side = 2
			isFoundSide = true

		if path.sides[2].isFree and !isFoundSide
			base.segments[0] = path.segments[2]
			base.segments[1] = path.segments[3]
			base.sides[0].isFree = false
			path.sides[2].isFree = false
			side = 3
			isFoundSide = true

		# find direction of 3rd point
		
		switch side
			when 0
				vector1 = path.segments[1].point - path.segments[2].point
				vector2 = path.segments[0].point - path.segments[2].point
				
				len = h.getRand 20,80
				vector1.length += len
				vector2.length += len
				point1 = path.segments[1].point + vector1
				point2 = path.segments[0].point + vector2

				a = new Path.Rectangle point1, [10,10]
				a.fillColor  = 'black'

				b = new Path.Rectangle point2, [10,10]
				b.fillColor  = 'black'

				point3 = 
					x: ((point1.x + path.segments[1].point.x)/2)+h.getRand -5,-len/2
					y: ((point1.y + point2.y)/2)+h.getRand -5,len/2

				c = new Path.Rectangle point3, [10,10]
				c.fillColor  = 'orange'


		console.log base


		# base.add new Point 
		# 			x: path.segments[0].point.x + h.getRand -50, 50
		# 			y: path.segments[0].point.y + h.getRand -50, 50

		# base.closed = true
		

		# @color ?= h.getRand(150,175)
		# nextColor  = @color - (h.getRand -10,10)
		# base.fillColor = "rgb(#{nextColor},#{nextColor},#{nextColor})"
		# @color = nextColor

		# path.segments[1].point.y += 20

		@trias.push base

		# @animate base
		
		base

	animate:->


	
	update:(e)->
		TWEEN.update()


triangle = new Triangle

onFrame = (e)->
	triangle.update()







