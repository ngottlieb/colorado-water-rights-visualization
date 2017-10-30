Application =
  initialize: ->
    SVG = require('svg.js')
    this.map = SVG.adopt($('#lower_basin').get(0))
    this.setUpSlider()
    this.setUpMapClicks()

  setUpSlider: ->
    Slider = require('bootstrap-slider')

    # TODO: sort out binding of "this" in the call below so
    # I don't have to call Application all over the place (unless that's Right?)
    $('#annual_flow').slider(
      formatter: (value) ->
        return value + ' maf'
    ).on('change', this.updateAnnualFlow)
    this.updateAnnualFlow()

  map: null

  annualFlow: 15

  distributeWater: ->
    console.log 'allocating water'
    SVG.select('.stakeholder').each ->
      Application.updateFill(this)

  updateAnnualFlow: ->
    currFlow = parseInt($('#annual_flow').val())
    Application.annualFlow = currFlow
    $('#annual_flow_val').text(currFlow)
    Application.distributeWater()

  updateFill: (stakeholder) ->
    gradient = this.map.gradient('linear', (stop) ->
        proportion = Application.getAllotment(stakeholder)
        stop.at(proportion, '#000fff')
        stop.at(proportion, '#aaa')
      ).from(0,1).to(0,0)
    stakeholder.attr({ fill: gradient })

  # accepts a stakeholder (state or mexico) and returns the
  # percentage of their allotment that they receive given the
  # available water
  getAllotment: (stakeholder) ->
    return this.annualFlow / 100

  setUpMapClicks: ->
    console.log 'setting up map clicks'
    $('.stakeholder').each ->
      name = $(this).attr('id')
      console.log(name)

module.exports = Application
