###

Materia
It's a thing

Widget	: Labeling, Creator
Authors	: Jonathan Warner
Updated	: 11/13

###

Namespace('Labeling').Creator = do ->
	# variables for local use
	_title = _qset = null

	# canvas, context, and image to render to it
	_canvas = _context = _img = null

	# offset for legacy support
	_offsetX = _offsetY = 0

	initNewWidget = (widget, baseUrl) ->
		$('#title').val 'New Labeling Widget'

		# make a scaffold qset object
		_qset = {}
		_qset.options = {}
		_qset.options.backgroundTheme = 'themeCorkBoard'

		# arrow that tells the user which button to press first	
		$('.arrow_box').css 'display','block'

		# set up the creator, shared between new and existing
		_setupCreator()

	_setupCreator = ->
		# set background and header title
		_setBackground()

		# get canvas context
		_canvas = document.getElementById('canvas')
		_context = _canvas.getContext('2d')

		_img = new Image()

		# set up event handlers
		$('.graph').click ->
			_qset.options.backgroundTheme = 'themeGraphPaper'
			_setBackground()
		$('.cork').click  ->
			_qset.options.backgroundTheme = 'themeCorkBoard'
			_setBackground()
		$('.color').click ->
			_qset.options.backgroundTheme = 'themeSolidColor'
			_qset.options.backgroundColor = 11184810
			_setBackground()
		$('#btnMoveResize').click ->
			_resizeMode true
		$('#btnMoveResizeDone').click ->
			_resizeMode false
		$('#btnChooseImage').click ->
			Materia.CreatorCore.showMediaImporter()

		document.getElementById('canvas').addEventListener('click', _addTerm, false)

		# drag all sides of the image for resizing
		$('#imagewrapper').draggable().resizable
			aspectRatio: true
			handles: 'n, e, s, w'

		# update background
		$('#colorpicker').spectrum({
			move: _updateColorFromSelector
			change: _updateColorFromSelector
			cancelText: ''
		})

	# sets resize mode on and off, and sets UI accordingly
	_resizeMode = (isOn) ->
		$('#terms').css 'display', if isOn then 'none' else 'block'
		$('#canvas').css 'display', if isOn then 'none' else 'block'
		$('#maincontrols').css 'display', if isOn then 'none' else 'block'
		$('#resizecontrols').css 'display', if isOn then 'block' else 'none'
		if isOn
			$('#imagewrapper').addClass 'resizable'
		else
			$('#imagewrapper').removeClass 'resizable'

	# set background color, called from the spectrum events	
	_updateColorFromSelector = (color) ->
		_qset.options.backgroundTheme = 'themeSolidColor'
		_qset.options.backgroundColor = parseInt(color.toHex(),16)
		_setBackground()

	# sets background from the qset
	_setBackground = ->
		# set background
		switch _qset.options.backgroundTheme
			when 'themeGraphPaper'
				background = 'url(assets/labeling-graph-bg.png)'
			when 'themeCorkBoard'
				background = 'url(assets/labeling-cork-bg.jpg)'
			else
				# convert to hex and zero pad the background, which is stored as an integer
				background = '#' + ('000000' + _qset.options.backgroundColor.toString(16)).substr(-6)

		$('#board').css('background',background)

	initExistingWidget = (title,widget,qset,version,baseUrl) ->
		_qset = qset

		_setupCreator()

		# get asset url from Materia API (baseUrl and all)
		url = Materia.CreatorCore.getMediaUrl(_qset.options.image.id)

		# render the image inside of the imagewrapper
		$('#image').attr 'src', url
		$('#image').attr 'data-imgid', _qset.options.image.id

		# load the image resource via JavaScript for rendering later
		_img.src = url
		_img.onload = ->
			$('#imagewrapper').css('height', (_img.height * _qset.options.imageScale))
			$('#imagewrapper').css('width', (_img.width * _qset.options.imageScale))

		# set the resizable image wrapper to the size and pos from qset
		$('#imagewrapper').css('left', (_qset.options.imageX))
		$('#imagewrapper').css('top', (_qset.options.imageY))

		# set the title from the qset
		$('#title').val title

		# add qset terms to the list
		# legacy support:
		questions = qset.items
		if questions[0]? and questions[0].items
			questions = questions[0].items
		for item in questions
			_makeTerm(item.options.endPointX,item.options.endPointY,item.questions[0].text,item.options.labelBoxX,item.options.labelBoxY)

	# draw lines on the board
	_drawBoard = ->
		# clear the board area
		_context.clearRect(0,0,1000,1000)

		# iterate every term and read dot attributes
		for term in $('.term')
			dotx = parseInt(term.getAttribute('data-x'))
			doty = parseInt(term.getAttribute('data-y'))

			# read label position from css
			labelx = parseInt(term.style.left)
			labely = parseInt(term.style.top)

			# drawLine handles the curves and such; run it for inner
			# and outer stroke
			_drawLine(dotx, doty, labelx, labely, 6, '#fff')
			_drawLine(dotx, doty, labelx, labely, 2, '#000')

	
	# Add term to the list, called by the click event
	_addTerm = (e) ->
		# draw a dot on the canvas for the question location
		_makeTerm e.clientX-document.getElementById('frame').offsetLeft-document.getElementById('board').offsetLeft,e.clientY-50
	
	# draw the line from x1,y1 to x2,y2, with curve
	_drawLine = (x1,y1,x2,y2,width,color) ->
		_context.lineCap = 'round'
		_context.beginPath()

		# move lines
		_context.moveTo(x1 + _offsetX,y1 + _offsetY)

		# determine curvature based on direction of line
		labelOffsetX = 0
		labelOffsetY = 0
		lineCurveOffsetY = 0
		lineCurveOffsetX = 60
		lineResultX = 60

		# Arrange the curves based on which y or x is greater
		if Math.abs(y1-y2) > 40
			lineCurveOffsetX = 0
			if y1 > y2
				lineCurveOffsetY = 65
				labelOffsetY = 20
			else
				lineCurveOffsetY = -35
				labelOffsetY = -10
			labelOffsetX = 60
			lineResultX = 0
		else if Math.abs(x1-x2) > 60
			if x1 > x2
				lineCurveOffsetX = 180
				lineResultX = 140
			else
				lineResultX = -10
				lineCurveOffsetX = -60

		# draw curvedline on the canvas
		_context.lineTo(x2 + labelOffsetX + lineCurveOffsetX + _offsetX, y2 + lineCurveOffsetY + _offsetY)
		_context.lineTo(x2 + labelOffsetX + lineResultX + _offsetX, y2 + labelOffsetY + _offsetY)
		_context.lineWidth = width
		_context.strokeStyle = color
		_context.stroke()
	
	# generate a term div
	_makeTerm = (x,y,text = '',labelX=null,labelY=null) ->
		dotx = x
		doty = y

		term = document.createElement 'div'
		term.id = 'term_' + Math.random(); # fake id for linking with dot
		term.innerHTML = "<div contenteditable='true'>"+text+"</div><div class='delete'></div>"
		term.className = 'term'
		
		# if we're generating a generic one, decide on a position
		if labelX is null or labelY is null
			y = (y - 200)

			labelAreaHalfWidth = 500 / 2
			labelAreaHalfHeight = 500 / 2

			labelStartOffsetX = 70
			labelStartOffsetY = 50
			
			if (x < labelAreaHalfWidth)
				x -= labelStartOffsetX

				if (y < labelAreaHalfHeight)
					y += labelStartOffsetY
				else
					y -= labelStartOffsetY
			else
				x += labelStartOffsetX

				if (y < labelAreaHalfHeight)
					y += labelStartOffsetY
				else
					y -= labelStartOffsetY

			if (y < 100)
				y += 100

			if x > 600
				x -= 200
		else
			x = labelX
			y = labelY

		# set term location and dot attribute
		term.style.left = x + 'px'
		term.style.top = y + 'px'
		term.setAttribute 'data-x', dotx
		term.setAttribute 'data-y', doty

		$('#terms').append term

		dot = document.createElement 'div'
		dot.className = 'dot'
		dot.style.left = dotx + 'px'
		dot.style.top = doty + 'px'
		dot.setAttribute 'data-termid', term.id

		$('#terms').append dot

		# edit on click
		term.onclick = ->
			term.childNodes[0].focus()
			document.execCommand 'selectAll',false,null

		# resize text on change
		term.childNodes[0].onkeyup = _termKeyUp
		# set initial font size
		term.childNodes[0].onkeyup target: term.childNodes[0]
		
		# enter key press should stop editing
		term.childNodes[0].onkeydown = _termKeyDown

		# check if blank when the text is cleared
		term.childNodes[0].onblur = _termBlurred
		
		# make delete button remove it from the list
		term.childNodes[1].onclick = ->
			term.parentElement.removeChild(term)
			dot.parentElement.removeChild(dot)
			_drawBoard()

		# make the term movable
		$(term).draggable({
			drag: (event,ui) ->
				_drawBoard()
		})
		# make the dot movable
		$(dot).draggable({
			drag: _dotDragged
		})
		setTimeout ->
			term.childNodes[0].focus()
		,10

		_drawBoard()

	# When typing on a term, resize the font accordingly
	_termKeyUp = (e) ->
		e = window.event if not e?
		fontSize = (16 - e.target.innerHTML.length / 10)
		fontSize = 12 if fontSize < 12
		e.target.style.fontSize = fontSize + 'px'

	# When typing on a term, resize the font accordingly
	_termKeyDown = (e) ->
		e = window.event if not e?
		if e.keyCode is 13
			e.target.blur()
			e.stopPropagation() if e.stopPropagation?
			false

	# If the term is blank, put dummy text in it
	_termBlurred = (e) ->
		e = window.event if not e?
		e.target.innerHTML = '(blank)' if e.target.innerHTML is ''

	# a dot has been dragged, lock it in place if its within 10px
	_dotDragged = (event,ui) ->
		minDist = 9999
		minDistEle = null

		for dot in $('.dot')
			if dot is event.target
				continue
			dist = Math.sqrt(Math.pow((ui.position.left - $(dot).position().left),2) + Math.pow((ui.position.top - $(dot).position().top),2))
			if dist < minDist
				minDist = dist
				minDistEle = dot

		# less than 10px away, put the dot where the other one is
		# this is how duplicates are supported
		if minDist < 10
			ui.position.left = $(minDistEle).position().left
			ui.position.top = $(minDistEle).position().top
		
		term = document.getElementById event.target.getAttribute('data-termid')
		term.setAttribute('data-x', ui.position.left)
		term.setAttribute('data-y', ui.position.top)

		_drawBoard()

	# called from Materia creator page
	onSaveClicked = (mode = 'save') ->
		if not _buildSaveData()
			return Materia.CreatorCore.cancelSave 'Widget needs a title and at least one term.'
		Materia.CreatorCore.save _title, _qset

	onSaveComplete = (title, widget, qset, version) -> true

	# called from Materia creator page
	# place the questions in an arbitrary location to be moved
	onQuestionImportComplete = (items) ->
		for item in items
			_makeTerm(150,300,item.questions[0].text)

	# generate the qset	
	_buildSaveData = ->
		if not _qset? then _qset = {}
		if not _qset.options? then _qset.options = {}

		words = []

		_qset.assets = []
		_qset.rand = false
		_qset.name = ''
		_title = $('#title').val()
		_okToSave = if _title? && _title != '' then true else false

		items = []

		dots = $('.term')
		for dot in dots
			item = {}

			answer =
				text: dot.childNodes[0].innerHTML
				value: 100
				id: ''
			item.answers = [answer]
			item.assets = []
			question =
				text: dot.childNodes[0].innerHTML
			item.questions = [question]
			item.type = 'QA'
			item.id = ''
			item.options =
				labelBoxX: parseInt(dot.style.left.replace('px',''))
				labelBoxY: parseInt(dot.style.top.replace('px',''))
				endPointX: parseInt(dot.getAttribute('data-x'))
				endPointY: parseInt(dot.getAttribute('data-y'))

			items.push item

		_qset.items = items

		if items.length < 1
			_okToSave = false

		_qset.options =
			backgroundTheme: _qset.options.backgroundTheme
			backgroundColor: _qset.options.backgroundColor
			imageScale: $('#imagewrapper').width() / _img.width
			image:
				id: $('#image').attr('data-imgid')
				materiaType: "asset"
			imageX: $('#imagewrapper').position().left
			imageY: $('#imagewrapper').position().top

		_qset.version = "2"

		_okToSave

	# called from Materia creator page
	# loads and sets appropriate data for loading image
	onMediaImportComplete = (media) ->
		url = Materia.CreatorCore.getMediaUrl(media[0].id)
		$('#image').attr 'src', url
		$('#image').attr 'data-imgid', media[0].id
		_img.src = url
		_img.onload = ->
			iw = $('#imagewrapper')
			if _img.width > _img.height
				width = 570
				iw.css('width', width)
				iw.css('height', (_img.height * iw.width() / _img.width))
			else
				height = 470
				iw.css('height', height)
				iw.css('width', (_img.width * iw.height() / _img.height))

			$('#imagewrapper').css('left', (600 / 2) - (iw.width() / 2))
			$('#imagewrapper').css('top', (500 / 2) - (iw.height() / 2))

		_resizeMode true
		
		# hide help tips
		$('.arrow_box').css 'display','none'
		
		true

	# Public members
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete