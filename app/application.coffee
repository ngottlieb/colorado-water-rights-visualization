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
    #
    # CITATION: annual flow data from https://www.usbr.gov/lc/region/programs/crbstudy/finalreport/Technical%20Report%20B%20-%20Water%20Supply%20Assessment/TR-B_Water_Supply_Assessment_FINAL.pdf
    $('#annual_flow').slider(
      formatter: (value) ->
        return value + ' maf'
      min: 0
      max: 35
      value: this.annualFlow
      ticks: [0,5.6, 15, 25.2, 35]
      ticks_labels: ['','1977', 'mean', '1984','']
      ticks_positions: [0, 16, 42.9, 72, 100]
      ticks_snap_bounds: 1
      step: 0.1
    ).on('change', this.updateAnnualFlow)
    this.updateAnnualFlow()

  map: null

  annualFlow: 15

  distributeWater: ->
    SVG.select('.stakeholder').each ->
      Application.updateFill(this)

  updateAnnualFlow: ->
    currFlow = parseFloat($('#annual_flow').val())
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
