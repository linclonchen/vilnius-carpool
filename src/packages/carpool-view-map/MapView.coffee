reactivate = (obj, property)->
  depName = 'dep'+ (property[0].toUpperCase() + property[1..-1].toLowerCase())
  obj.prototype[depName] = new Tracker.Dependency;
  getterName = 'get'+ (property[0].toUpperCase() + property[1..-1].toLowerCase())
  obj.prototype[getterName] = new Function("", 'this["'+depName+'"].depend(); return this["'+property+'"];');
  setterName = 'set'+ (property[0].toUpperCase() + property[1..-1].toLowerCase())
  obj.prototype[setterName] = new Function("value", 'this["'+depName+'"].changed(); return this["'+property+'"]=value;');

class Location
  address: null
  latlng: null;

reactivate(Location, "latlng");

class CarpoolTrip
  time: new Date();
  from: new Location
  to: new Location

  getTime: () ->
    return @time

class MapView
  afterMapShown = new ParallelQueue(@);
  trip: new CarpoolTrip();
  toMarker: null;
  fromMarker: null;
  stops: []
  progress: {};
  activeTrips: {}

  ###
  Shows Google Map when all required libraries are ready and starts afterMapShown queue
  ###
  showMap: (id, cb)->
    mapElement = document.getElementById(id);
    # This method is called after google services are initialized
    googleServices.afterInit =>
      myOptions =
        zoom: 12
        center: new (google.maps.LatLng)(54.67704, 25.25405)
        mapTypeId: google.maps.MapTypeId.ROADMAP
      @map = new (google.maps.Map)(mapElement, myOptions)
      cb(null, @map);
      #da ["stops-drawing"], "Map is shown"
      afterMapShown.start();
  ###
  Automcomplete requires map to be initialized
  ###
  addAutocomplete: afterMapShown.wrap (input, cb)->
    googleServices.addAutocomplete input, @map, cb
  ###
  Geolocate more details about location
  ###
  clarifyPlace: (latlng, address, cb)->
    #d "Clarify place", address
    googleServices.getGeocoder().geocode { 'address': address }, (error, result) ->
      if !error and result.length > 0
        cb?(null, result[0].geometry.location, address)
      else
        cb?(error)
  ###
  The new trip destination
  ###
  setCurrentTripTo: (err, latlng, address, place)=>
    #d "Set current trip to", address
    setToLatLng = (refinedLatlng, refinedAddress)=>
      @trip.to.setLatlng(refinedLatlng)
      @trip.to.address = refinedAddress
      @dropToMarker @trip.to.latlng
    if not latlng then @clarifyPlace location, address, (err, refinedLatlng, refinedAddress)=>
      d "Refined latlng #{refinedAddress}:", refinedLatlng,
      setToLatLng(refinedLatlng, refinedAddress) unless err
    else
      setToLatLng(latlng, address)
  dropToMarker: (latlng)->
    if not @toMarker
      pinImage = new (google.maps.MarkerImage)('http://maps.google.com/mapfiles/ms/icons/green-dot.png', new (google.maps.Size)(32, 32), new (google.maps.Point)(0, 0), new (google.maps.Point)(16, 32))
      toMarker = new (google.maps.Marker)(
        map: @map
        position: latlng
        icon: pinImage
        draggable: true)
    else
      @toMarker.setPosition(location);
  ###
  The new trip origin
  ###
  setCurrentTripFrom: (err, latlng, address, place)=>
    #d "Set current trip to", address
    setFromLatLng = (refinedLatlng, refinedAddress)=>
      #d "Refine latlng", refinedLatlng
      @trip.from.setLatlng(refinedLatlng)
      @trip.from.address = refinedAddress
      @dropFromMarker @trip.from.latlng
    if not latlng then @clarifyPlace location, address, (err, refinedLatlng, refinedAddress)=>
      setFromLatLng(refinedLatlng, refinedAddress) unless err
    else
      setFromLatLng(latlng, address)
  dropFromMarker: (latlng)->
    if not @fromMarker
      pinImage = new (google.maps.MarkerImage)('http://maps.google.com/mapfiles/ms/icons/red-dot.png', new (google.maps.Size)(32, 32), new (google.maps.Point)(0, 0), new (google.maps.Point)(16, 32))
      fromMarker = new (google.maps.Marker)(
        map: @map
        position: latlng
        icon: pinImage
        draggable: true)
    else
      @toMarker.setPosition(location);
  ###
  Draw stops on the map
  ###
  showStops: afterMapShown.wrap (stops) ->
    #da ["stops-drawing"], "Stops", stops
    for i, stop of stops
      #da ["stops-drawing"], "Show stop", stop
      @stops[i] = new (google.maps.Marker)(
        map: @map
        position: googleServices.toLatLng stop.loc
        draggable: false
        icon: new (google.maps.MarkerImage)('/img/white-dot.png',
          new (google.maps.Size)(11, 11),
          new (google.maps.Point)(0, 0),
          new (google.maps.Point)(6, 6)))
  ###
  Removes the trip from map
  ###
  removeTrip: (trip)->
    da ['trips-drawing'], "Removign trip", trip
    trip.line.setMap(null);
    for point in trip.points
      point.setMap(null)
  ###
  Puts markers and decoded points on the map
  ###
  drawActiveTrip: afterMapShown.wrap (trip, options, cb) ->
    da ['trips-drawing'], "Check is trip already drawn", trip
    if @activeTrips[trip._id]?
      @removeTrip @activeTrips[trip._id]
    result =
      points: []
    da ['trips-drawing'], 'Drawing trip:', trip
    if trip.path and trip.toLoc and trip.fromLoc
      decodedPoints = google.maps.geometry.encoding.decodePath(trip.path)
      fromLatLng = googleServices.toLatLng trip.fromLoc
      toLatLng = googleServices.toLatLng trip.toLoc
      #d("Decoded points:", decodedPoints);
      result.line = new (google.maps.Polyline)(_.extend({
        clickable: true
        map: @map
        path: decodedPoints
        strokeColor: 'SteelBlue'
        strokeOpacity: 0.5
        strokeWeight: 3
      }, options))
      result.points[0] = new (google.maps.Marker)(
        map: @map
        position: fromLatLng
        draggable: false
        icon: new (google.maps.MarkerImage)('/img/red-dot-small.png',
          new (google.maps.Size)(9, 9),
          new (google.maps.Point)(0, 0),
          new (google.maps.Point)(4, 4)))
      result.points[1] = new (google.maps.Marker)(
        map: @map
        position: toLatLng
        draggable: false
        icon: new (google.maps.MarkerImage)('/img/green-dot-small.png',
          new (google.maps.Size)(9, 9),
          new (google.maps.Point)(0, 0),
          new (google.maps.Point)(4, 4)))
      @activeTrips[trip._id] = result
      cb and cb(null, result)
    else
      da ['veiwport-map'], 'Can\'t draw - path is not decoded: ' + trip
      cb? "No path", null
  ###
  Removes the trips not present in set
  ###
  invalidateActiveTrips: (set)->
    oldTrips = _(@activeTrips).keys()
    purge = _.difference(oldTrips,set)
    for key in purge
      @removeTrip(@activeTrips[key])
  ###
  Progress bar reset
  ###
  resetActionProgress: ->
    @progress = {}
    NProgress.done()
  ###
  Set progress bar values
  ###
  setActionProgress: (action, value) ->
    if value == 100
      delete @progress[action]
    else
      @progress[action] = value
    sum = 0
    total = 0
    _.each @progress, (item) ->
      sum += item
      total += 100
      return
    #da(['ie8-router', 'group-security'], "Progress:"+sum+"/"+total+" of "+action+"="+value, progress);
    if sum == 0
      if total == 0
        NProgress.done()
      else
        NProgress.start()
    else
      NProgress.set sum / total

@mapView = new MapView

###
  Meteor templates for UI
###
Template.MapView.rendered = ->
  #d "Stops admin rendered"
  mapView.showMap "map_canvas", (err, map)=>
    #d "Stops might not be loaded", @data
