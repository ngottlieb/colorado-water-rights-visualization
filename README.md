# Visualizing Constraints on the Distribution of Water in the Colorado River System

## Running the App
The app is hosted here http://ngottlieb.github.io/colorado-water-rights-visualization/. You can run it locally by downloading the source code from the `gh-pages` branch and opening it in a web browser.

## Purpose
This project aims to visualize how existing and historical constraints on the Colorado River system interplay with annual flow -- an analog for total water supply -- to impact real water distribution among stakeholders. In the face of a dynamic water supply and climate forecasts, it’s important to be able to understand how our shortage guidelines will play out, and to be able to visualize ways to improve the legal structure.

## Example Use Case
In its current state, this project is best used as an educational tool to help explain the existing constraints and overarching demands. The historic “Law of the River” is a conglomerate of many documents and understanding it can be quite challenging; the current paradigm, while defined by fewer documents, is equally confusing. This project provides a visual interpretation of what the legal paradigms actually mean in terms of Colorado water distribution, and allows the user to experiment with changing annual flows to see the impact they have in the context of the constraints.

This could be used by academics, the public, or government employees new to the Colorado system to aid understanding of the way water management works at the highest levels in the Colorado basin and how system-wide water supply impacts stakeholder allocations.

## Potential for Extension
This project could easily be extended to be far more detailed, with more adjustable parameters and visual representations of reservoir levels and other major factors that impact water distribution. The map structure is based on GeoJSON and is easily extensible, and the business logic behind the scenes could be extended to incorporate the elements of storage that are not currently included. Other possible enhancements include incorporating climate predictions into the visualization or adding a navigable year-by-year historical analysis of flows, storage, and distribution.

With some of these enhancements, I think this tool could be extremely valuable for water managers, helping them understand the implications of system-wide management strategies like the Interim Shortage Guidelines under varying conditions.