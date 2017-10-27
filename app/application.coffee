$ = require('jquery')

Application =
  initialize: ->
    SVG = require('svg.js')
    $ = require('jquery')
    this.map = SVG.adopt($('#lower_basin').get(0))
    $('#annual_flow').on 'change', ->
      Application.updateAnnualFlow()

  updateAnnualFlow: ->
    this.annualFlow = parseInt($('#annual_flow').val())
    this.distributeWater()

  map: null

  annualFlow: 15

  distributeWater: ->
    console.log 'allocating water'
    SVG.select('.stakeholder').each ->
      Application.updateFill(this)

  updateFill: (stakeholder) ->
    gradient = this.map.gradient('linear', (stop) ->
        proportion = Application.annualFlow / 15
        stop.at(proportion, '#000fff')
        stop.at(proportion, '#aaa')
      ).from(0,1).to(0,0)
    stakeholder.animate().attr({ fill: gradient })

module.exports = Application
