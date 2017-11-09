WaterAllocation = require('water_allocation')
L = require('leaflet')
mapboxAccessToken = 'pk.eyJ1IjoibmdvdHRsaWViIiwiYSI6ImNqOW9uNGRzYTVmNjgzM21xemt0ZHVxZHoifQ.A6Mc9XJp5q23xmPpqbTAcQ'
usStates = require('us-states')
mexico = require('mexico')
WaterData = require('water_data')

Application =
  initialize: ->
    this.calculateTotals()
    this.prepareMap()
    this.updateAnnualFlow()
    this.setUpControls()

  prepareMap: ->
    this.map = L.map('map').setView([32.8, -110], 3.5);
    L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=' + mapboxAccessToken,
      id: 'mapbox.light'
    ).addTo(this.map)
    this.mapFeatures = L.geoJson(usStates.stateData,
      style: this.mapUnitStyle
      onEachFeature: this.onEachMapFeature
    )
    this.mapFeatures.addData(mexico.mexico).addTo(this.map)

    # add legend
    legend = L.control({position: 'bottomright'})
    legend.onAdd = this.buildLegend
    legend.addTo(this.map)
    
    # build hover-over info control
    this.mapInfo = L.control()
    this.mapInfo.onAdd = (map) ->
      this._div = L.DomUtil.create('div', 'info')
      this.update()
      return this._div
    this.mapInfo.update = (props) ->
      contents = '<h4>Colorado Basin Water Distribution</h4>'
      if props
        contents += Application.stateInfoDisplay(props)
      else
        contents += 'Hover over a state'
      this._div.innerHTML = contents
    this.mapInfo.addTo(this.map)

    this.mapSurplusDisplay = L.control({position: 'bottomleft'})
    this.mapSurplusDisplay.onAdd = (map) ->
      this._div = L.DomUtil.create('div', 'info')
      this.update()
      return this._div
    this.mapSurplusDisplay.update = ->
      if Application.mapVariable == 'legalAllocation'
        baseLine = Application.totalLegalAllotment
        relativeTo = 'Legal Allocation'
      else
        baseLine = Application.totalAvgConsumptiveUse
        relativeTo = 'Recent Avg Consumptive Use'

      difference = Application.annualFlow - baseLine
      surp_def = if difference >= 0 then 'Surplus' else 'Deficit'
      contents = "<h4>Basin-wide #{surp_def}</h4>"
      contents += "<b>Relative to #{relativeTo}</b><br />"
      contents += "<span class='pull-right badge'>#{difference.toFixed(2)} maf</span>"
      this._div.innerHTML = contents
    this.mapSurplusDisplay.addTo(this.map)

  mapFeatures: null
  mapInfo: null
  mapSurplusDisplay: null

  totalAvgConsumptiveUse: 0
  totalLegalAllotment: 0

  calculateTotals: ->
    sum = 0
    for k in Object.keys(WaterData.historicalConsumptiveUse)
      avgUse = Application.averageRecentConsumptiveUse(k)
      if avgUse != 'na'
        sum += avgUse
    Application.totalAvgConsumptiveUse = (sum).toFixed(2)
    sum = 0
    for k, v of WaterData.legalAllotments
      sum += v
    Application.totalLegalAllotment = sum

  # controlled by the select box control for what's on the map
  mapVariable: 'legalAllocation'

  setUpControls: ->
    # Set up slider
    Slider = require('bootstrap-slider')
    # CITATION: annual flow data from https://www.usbr.gov/lc/region/programs/crbstudy/finalreport/Technical%20Report%20B%20-%20Water%20Supply%20Assessment/TR-B_Water_Supply_Assessment_FINAL.pdf
    slider = $('#annual_flow').slider(
      formatter: (value) ->
        return value + ' maf'
      min: 0
      max: 28
      tooltip: 'always'
      value: this.annualFlow
      step: 0.1
    ).on('change', this.updateAnnualFlow)

    $('.flow-btn').on 'click', ->
      slider.slider('setValue',$(this).data('flow'), true, true)

    # set up select box variable control
    $('#mapVariableControl').on 'change', ->
      Application.mapVariable = $(this).val()
      Application.updateDisplay()

  updateExplanations: ->
    currentlyIn = Application.mapVariable
    currentlyOut = if Application.mapVariable == 'legalAllocation' then 'consumptiveUse' else 'legalAllocation'
    $("##{currentlyIn}Blurb").show()
    $("##{currentlyOut}Blurb").hide()
    $("##{currentlyIn}Collapse").collapse('show')
    $("##{currentlyOut}Collapse").collapse('hide')

  map: null

  waterAllocation: {}

  annualFlow: 15
  deliverToMexico: true

  updateDisplay: ->
    Application.mapFeatures.setStyle(Application.mapUnitStyle)
    Application.mapSurplusDisplay.update()
    Application.updateExplanations()

  updateAnnualFlow: ->
    currFlow = parseFloat($('#annual_flow').val())
    Application.annualFlow = currFlow
    Application.waterAllocation = WaterAllocation.determineAllocation(currFlow, Application.deliverToMexico)
    Application.updateDisplay()

  # color is a divergent gradient from red to white to blue
  getColor: (proportion)->
    if proportion == 'na'
      return '#fec44f'
    else if proportion <= 0.5
      red = parseInt(178 + proportion * 150)
      green = parseInt(24 + proportion * 446)
      blue = parseInt(43 + proportion*408)
    else
      num = proportion - 0.5
      red = parseInt(247 - 428*num)
      green = parseInt(247 - 290*num)
      blue = parseInt(247 - 150*num)
    return 'rgb(' + red + ',' + green + ',' + blue + ')'

  mapUnitStyle: (feature)->
    return {
      fillColor: Application.getColor(Application.getProportion(feature))
      weight: 2
      opacity: 1
      color: 'white'
      dashArray: '3'
      fillOpacity: 0.7
    }

  highlightMapUnit: (e) ->
    layer = e.target
    layer.setStyle
      weight: 5
      color: '#666'
      dashArray: ''
    layer.bringToFront()
    Application.mapInfo.update(layer.feature.properties)

  resetHighlight: (e) ->
    Application.mapFeatures.resetStyle(e.target)
    Application.mapInfo.update()

  # accepts a stakeholder (state or mexico) and returns the
  # percentage of their allotment that they receive given the
  # available water
  getProportion: (feature) ->
    state = Application.camelcaseName(feature.properties.name)
    water = this.waterAllocation[state]
    if Application.mapVariable == 'legalAllocation'
      return water / WaterData.legalAllotments[state]
    else
      denom = Application.averageRecentConsumptiveUse(state)
      if denom == 'na'
        return 'na'
      else
        proportion = water / denom
        if proportion > 1
          return 1
        else
          return proportion

  # averages all available consumptive use datapoints since 2001
  averageRecentConsumptiveUse: (state) ->
    sum = 0
    n = 0
    for year, value of WaterData.historicalConsumptiveUse[state]
      if parseInt(year) >= 2001
        sum += value
        n += 1
    if n > 0
      return sum/n
    else
      return 'na'


  camelcaseName: (name) ->
    return name
      .replace(/\s(.)/g, ($1)-> return $1.toUpperCase() )
      .replace(/\-/g, '')
      .replace(/\s/g, '')
      .replace(/^(.)/, ($1)-> return $1.toLowerCase() )

  onEachMapFeature: (feature, layer) ->
    layer.on(
      mouseover: Application.highlightMapUnit
      mouseout: Application.resetHighlight
    )

  stateInfoDisplay: (props) ->
    state = Application.camelcaseName(props.name)
    water = Application.waterAllocation[state]
    avgUse = Application.averageRecentConsumptiveUse(state)
    if avgUse == 'na'
      percConsumptiveUse = 'N/A'
    else
      proportionUsed = if water > avgUse then 1 else water / avgUse
      percConsumptiveUse = "#{(proportionUsed * 100).toFixed(0)}%"
    keyValPairs =
      "#{props.name}": "#{water.toFixed(2)} maf"
      "% of Legal Allocation": "#{(water * 100 / WaterData.legalAllotments[state]).toFixed(0)}%"
      "% of Avg Consumptive Use": percConsumptiveUse
    outputHtml = ''
    for key, value of keyValPairs
      outputHtml += "<b class='pull-left'>#{key}</b>"
      outputHtml += "<span class='pull-right'>#{value}</span><br />"
    outputHtml

  buildLegend: (map) ->
    div = L.DomUtil.create('div', 'info legend')
    grades = [0,0.1, 0.2, 0.3,0.4,0.5,0.6,0.7, 0.8,0.9,1.0, 'na']
    labels = ['0%', '10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%', '100%', 'Data Unavailable']
    for g, index in grades
      # separate the "Data Unavailable" from the rest
      if index == grades.length - 1
        div.innerHTML += '<br />'
      div.innerHTML +=
        '<i style="background:' + Application.getColor(g) + '"></i> ' + labels[index] + '<br />'
    return div


module.exports = Application
