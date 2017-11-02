WaterAllocation = require('water_allocation')
SVG = require('svg.js')
Application =
  initialize: ->
    this.map = SVG.adopt($('#lower_basin').get(0))
    this.setUpSlider()
    this.setUpMapClicks()
    this.setAnnualFlow()

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
      ticks_snap_bounds: 0.5
      step: 0.1
    ).on('change', this.setAnnualFlow)

  map: null

  waterApportionments: null

  annualFlow: 15
  deliverToMexico: true

  distributeWater: ->
    SVG.select('.stakeholder').each ->
      Application.updateFill(this)
      state = this.attr('id')
      $("#" + state + "Flow").
        text(Application.waterApportionments[state].toFixed(2) + 'maf')

  setAnnualFlow: ->
    currFlow = parseFloat($('#annual_flow').val())
    Application.annualFlow = currFlow
    Application.waterApportionments = WaterAllocation.determineAllocation(currFlow, Application.deliverToMexico)
    $('#annual_flow_val').text(currFlow + 'maf')
    Application.distributeWater()

  updateFill: (stakeholder) ->
    gradient = this.map.gradient('linear', (stop) ->
        proportion = Application.getPortion(stakeholder)
        stop.at(proportion, '#000fff')
        stop.at(proportion, '#aaa')
      ).from(0,1).to(0,0)
    stakeholder.attr({ fill: gradient })

  # accepts a stakeholder (state or mexico) and returns the
  # percentage of their allotment that they receive given the
  # available water
  getPortion: (stakeholder) ->
    state = stakeholder.attr('id')
    return this.waterApportionments[state] / this.fullAllotments[state]

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
