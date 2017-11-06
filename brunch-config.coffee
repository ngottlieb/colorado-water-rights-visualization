module.exports =
  npm:
    styles:
      'bootstrap': ['dist/css/bootstrap.css']
      'bootstrap-slider': ['dist/css/bootstrap-slider.css']
      'leaflet': ['dist/leaflet.css']
    globals:
      $: 'jquery'
      jQuery: 'jquery'
  files:
    javascripts:
      joinTo: 'app.js'
    stylesheets:
      joinTo: 'app.css'
