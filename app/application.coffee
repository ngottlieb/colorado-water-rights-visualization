WaterAllocation = require('water_allocation')
L = require('leaflet')
mapboxAccessToken = 'pk.eyJ1IjoibmdvdHRsaWViIiwiYSI6ImNqOW9uNGRzYTVmNjgzM21xemt0ZHVxZHoifQ.A6Mc9XJp5q23xmPpqbTAcQ'
usStates = require('us-states')
mexico = require('mexico')

Application =
  initialize: ->
    this.prepareMap()
    this.updateAnnualFlow()
    this.setUpSlider()
    #this.setUpMapClicks()

  prepareMap: ->
    this.map = L.map('map').setView([32.8, -110], 3.5);
    L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=' + mapboxAccessToken,
      id: 'mapbox.light'
    ).addTo(this.map)
    this.mapFeatures = L.geoJson(usStates.stateData, style: this.mapUnitStyle)
    this.mapFeatures.addData(mexico.mexico).addTo(this.map)

  mapFeatures: null

  setUpSlider: ->
    Slider = require('bootstrap-slider')
    # TODO: sort out binding of "this" in the call below so
    # I don't have to call Application all over the place (unless that's Right?)
    #
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

  map: null

  waterApportionments: {}

  annualFlow: 15
  deliverToMexico: true

  updateDisplay: ->
    Application.mapFeatures.setStyle(Application.mapUnitStyle)
    Application.mapFeatures.eachLayer (layer) ->
      # update maf label on info tab
      state = Application.camelcaseName(layer.feature.properties.name)
      $("#" + state + "Flow")
        .text(Application.waterApportionments[state].toFixed(2) + 'maf')


    #SVG.select('.stakeholder').each ->
    #  Application.updateFill(this)
    #  state = this.attr('id')
    #  $("#" + state + "Flow").
    #    text(Application.waterApportionments[state].toFixed(2) + 'maf')

  updateAnnualFlow: ->
    currFlow = parseFloat($('#annual_flow').val())
    Application.annualFlow = currFlow
    Application.waterApportionments = WaterAllocation.determineAllocation(currFlow, Application.deliverToMexico)
    Application.updateDisplay()

  # color is a gradient from rgb(247,251,255) to rgb(8,48,107)
  getColor: (proportion)->
    if proportion <= 0.5
      red = parseInt(178 + proportion * 75)
      green = parseInt(24 + proportion * 223)
      blue = parseInt(43 + proportion*204)
    else
      red = parseInt(247 - 214*proportion)
      green = parseInt(247 - 145*proportion)
      blue = parseInt(247 - proportion*75)
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

  # accepts a stakeholder (state or mexico) and returns the
  # percentage of their allotment that they receive given the
  # available water
  getProportion: (feature) ->
    state = Application.camelcaseName(feature.properties.name)
    return this.waterApportionments[state] / this.fullAllotments[state]

  camelcaseName: (name) ->
    return name
      .replace(/\s(.)/g, ($1)-> return $1.toUpperCase() )
      .replace(/\s/g, '')
      .replace(/^(.)/, ($1)-> return $1.toLowerCase() )

  fullAllotments:
    mexico: 1.5
    california: 4.4
    arizona: 2.85
    nevada: 0.3
    colorado: 3.88
    newMexico: 0.84
    utah: 1.73
    wyoming: 1.05

  setUpMapClicks: ->
    $('.stakeholder').each ->
      name = $(this).attr('id')

module.exports = Application
