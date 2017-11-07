WaterAllocation =
  determineAllocation: (annualFlow, deliverToMexico) ->
    allocations =
      mexico: 0
      california: 0
      utah: 0
      newMexico: 0
      arizonaLowerBasin: 0
      arizonaUpperBasin: 0
      colorado: 0
      wyoming: 0
      nevada: 0
      surplus: 0
    remainingFlow = annualFlow

    # delivery to Mexico can be somewhat discretionary, but in theory has highest priority
    if deliverToMexico
      allocations.mexico = this.allocate(1.5, remainingFlow)
      remainingFlow = remainingFlow - allocations.mexico
    else
      allocations.mexico = 0

    # Lower Basin has effective priority
    allocations.california = this.allocate(4.4, remainingFlow)
    remainingFlow = remainingFlow - allocations.california

    allocations.nevada = this.allocate(0.3, remainingFlow)
    remainingFlow = remainingFlow - allocations.nevada

    allocations.arizonaLowerBasin = this.allocate(2.8, remainingFlow)
    remainingFlow = remainingFlow - allocations.arizonaLowerBasin

    # Upper Basin
    # Arizona has a small portion
    azBonus = this.allocate(0.05, remainingFlow)
    allocations.arizonaUpperBasin = azBonus
    remainingFlow = remainingFlow - azBonus

    # the rest of the Upper Basin is divisioned up based on percentages,
    # but shortage is a complicated situation and shortages are divvied up
    # based on use
    upperBasinAllotment = this.allocate(7.5, remainingFlow)
    allocations.colorado = 0.5175 * upperBasinAllotment
    allocations.newMexico = 0.1125 * upperBasinAllotment
    allocations.utah = 0.23 * upperBasinAllotment
    allocations.wyoming = 0.14 * upperBasinAllotment
    
    remainingFlow = remainingFlow - upperBasinAllotment

    allocations.surplus = remainingFlow

    return allocations

  allocate: (fullAllocation, remainingFlow) ->
    if remainingFlow > fullAllocation
      return fullAllocation
    else
      return remainingFlow


module.exports = WaterAllocation
