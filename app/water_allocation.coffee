WaterAllocation =
  determineAllocation: (annualFlow, allocationParadigm) ->
    if allocationParadigm == 'modern'
      allocations = this.modernAllocation(annualFlow)
    else
      allocations = this.originalAllocation(annualFlow)

    return allocations

  modernAllocation: (annualFlow) ->
    allocations = this.emptyAllocation()
    
    # establish the level of shortage as distribution of shortage depends on degree of shortage
    # if annualFlow is less than 9, then the lower basin (and Mexico) will face a shortages
    if annualFlow >= 9
      shortage = false
      allocations = this.originalAllocation(annualFlow)
    # the exact number at which we switch from Stage I to Stage II shortage is in flux --
    # it depends on the amount of water AZ is using through fourth priority rights vs. third priority.
    # We are basing this decision here based Interim Shortage Plan EIS example scenario
    # dated 2017 (https://www.usbr.gov/lc/region/programs/strategies/FEIS/AppG.pdf)
    # which shows a maximum Stage I Shortage of 1,729,907 af
    else if annualFlow >= 7.27
      shortage = 'stageI'
      shortageAmt = 9 - annualFlow
      allocations.california = 4.4
      # Shortage is distributed among Mexico, Arizona, Nevada
      # AZ: 80%
      # MX: 16.67%
      # NV: 3.33%
      allocations.arizonaLowerBasin = 2.8 - (0.8*shortageAmt)
      allocations.mexico = 1.5 - (0.1667*shortageAmt)
      allocations.nevada = 0.3 - (0.0333*shortageAmt)
      
    else
      shortage = 'stageII'
      stageIShortageAmt = 1.73 # shared according to stageI paradigm
      stageIIShortageAmt = 7.27 - annualFlow
      totalShortage = stageIIShortageAmt + stageIShortageAmt
      allocations.mexico = 1.5 - (0.1667 * totalShortage)
      allocations.nevada = 0.3 - (0.0333 * totalShortage)
      # in stage 2, california begins to share in the shortage
      # AZ/CA are supposed to take 20%/60%, but the exact amount varies depending on 
      # the water rights priorities of the water AZ is using. 
      # in this example, using data from the BoR example of 2017 linked above,
      # AZ ends up at 19.5%
      allocations.arizonaLowerBasin = 2.8 - (0.8 * stageIShortageAmt) - (0.195 * stageIIShortageAmt)
      # to get the right amount here, we just ensure that we're ending up at 0
      allocations.california = annualFlow - allocations.mexico - allocations.nevada - allocations.arizonaLowerBasin
      
      # just make sure they're all positive so we don't get "-0" in our display
      for k in Object.keys(allocations)
        allocations[k] = Math.abs(allocations[k])
    return allocations

  originalAllocation: (annualFlow) ->
    allocations = this.emptyAllocation()
    remainingFlow = annualFlow

    # delivery to Mexico can be somewhat discretionary, but in theory has highest priority
    allocations.mexico = this.allocate(1.5, remainingFlow)
    remainingFlow = remainingFlow - allocations.mexico

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

  emptyAllocation: ->
    return
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

module.exports = WaterAllocation
