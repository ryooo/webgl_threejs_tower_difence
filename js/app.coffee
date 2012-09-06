T_WIDTH = T_HEIGHT = 100
class Stage
  constructor: ->
    @frame = 0
    @map = [
      [' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',]
      ['S','→','→','→','→','→','→','→','→','→','↓',' ',]
      [' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','↓',' ',]
      [' ',' ','↓','←','←','←','←',' ',' ',' ','↓',' ',]
      [' ',' ','↓',' ',' ',' ','↑',' ',' ',' ','↓',' ',]
      [' ',' ','↓',' ',' ',' ','↑',' ',' ',' ','↓',' ',]
      [' ',' ','↓',' ',' ',' ','↑','←','←','←','←',' ',]
      [' ',' ','↓',' ',' ',' ',' ',' ',' ',' ',' ',' ',]
      [' ',' ','↓',' ',' ',' ',' ',' ',' ',' ',' ',' ',]
      [' ',' ','↓',' ',' ',' ',' ',' ',' ',' ',' ',' ',]
      [' ',' ','→','→','→','→','→','→','→','↓',' ',' ',]
      [' ',' ',' ',' ',' ',' ',' ',' ',' ','G',' ',' ',]
    ]
    @scene = new THREE.Scene()
    @camera = new THREE.PerspectiveCamera(40, document.width / document.height, 1, 10000)
    @camera.position.z = 1000
    
    @renderer = new THREE.WebGLRenderer({antialias: true})
    @renderer.setSize(document.width, document.height)
    document.body.appendChild(@renderer.domElement)
    
    light = new THREE.DirectionalLight(0xFFFFFF)
    light.position = {x:100, y:1000, z:1000}
    @scene.add(light)
    
    @towers = []
    @enemys = []
    @planes = []
    @start = null
    geometory = new THREE.PlaneGeometry(T_WIDTH, T_HEIGHT)
    for y, row of @map
      for x, cell of @map[y]
        if cell is ' '
          material = new THREE.MeshLambertMaterial({color: 0xAAAAAA, opacity: 0.2})
        else
          material = new THREE.MeshLambertMaterial({color: 0x00EE00, opacity: 0.6})
        mesh = new THREE.Mesh(geometory, material)
        mesh.position = {x: x * T_WIDTH - 600, y: -99, z: y * T_HEIGHT - 600}
        mesh.rotation.x = 270 * 2 * Math.PI / 360
        if cell is 'S'
          cell = '→'
          @start = mesh
        mesh.direction = cell
        mesh.tile = {}
        mesh.tile.x = parseInt(x)
        mesh.tile.y = parseInt(y)
        @scene.add(mesh)
        @planes.push(mesh)
        @map[y][x] = mesh
    
    @control = new THREE.TrackballControls(@camera, @renderer.domElement)
    @projector = new THREE.Projector()
    @renderer.domElement.addEventListener "click", (e) =>
      mouseX = e.clientX - @getElementPosition(@renderer.domElement).left;
      mouseY = e.clientY - @getElementPosition(@renderer.domElement).top;
      x =   (mouseX / @renderer.domElement.width) * 2 - 1;
      y = - (mouseY / @renderer.domElement.height) * 2 + 1;
      vector = new THREE.Vector3(x, y, 1);
      @projector.unprojectVector(vector, @camera);
      ray = new THREE.Ray(@camera.position, vector.subSelf(@camera.position).normalize());
      intersects = ray.intersectObjects(@planes);
      if intersects.length > 0 && intersects[0].object.direction is ' '
        tower = new Tower(intersects[0].object.position)
        @scene.add(tower.mesh)
        @towers.push(tower)
        @renderer.render(@scene, @camera)
    , false
  getElementPosition: (element) =>
    top = left = 0
    while element
      top  += element.offsetTop  || 0;
      left += element.offsetLeft || 0;
      element =  element.offsetParent;
    return {top: top, left: left}
  render: ->
    if (@frame++ % 180) is 0
      enemy = new Enemy(@map, @start)
      enemy.nextTile()
      @scene.add(enemy.mesh)
      @enemys.push(enemy)
    if (@frame % 10) is 0
      for tower in @towers
        tower.aim()
    @control.update()
    TWEEN.update()
    @renderer.render(@scene, @camera)

class Tower
  constructor:(position) ->
    @height = 100
    geometry = new THREE.CylinderGeometry(0, 20, @height, 0, 0, false)
    material = new THREE.MeshLambertMaterial({color: Math.random() * 0xffffff})
    @mesh = new THREE.Mesh(geometry, material)
    @mesh.position.copy(position)
    @mesh.position.y += @height/2
  aim: ->
    for i, enemy of stage.enemys
      xx = enemy.mesh.position.x - @mesh.position.x
      zz = enemy.mesh.position.z - @mesh.position.z
      distance = Math.sqrt(Math.pow(xx,2) + Math.pow(zz,2))
      if distance <= 300
        stage.scene.add(new Shot(@mesh.position, enemy.mesh.position).mesh)
        return true

class Shot
  constructor:(start, end) ->
    geometry = new THREE.SphereGeometry(5, 3, 3)
    material = new THREE.MeshBasicMaterial({color: 0x6666ff})
    @mesh = new THREE.Mesh(geometry, material)
    @mesh.position.copy(start)
    @tween = new TWEEN.Tween(@mesh.position).to({x: end.x, y: end.y, z: end.z}, 100).onComplete(=> @destroy()).easing(TWEEN.Easing.Linear.EaseNone).start()
  destroy: ->
    stage.scene.remove(@mesh)

class Enemy
  constructor:(map, tile) ->
    @height = 100
    @map = map
    @tile = tile
    geometry = new THREE.SphereGeometry(30, 7, 7)
    material = new THREE.MeshBasicMaterial({
      color: 0xff6666, wireframe: true, wireframeLinewidth: 0.1
    })
    @mesh = new THREE.Mesh(geometry, material)
    @mesh.position.copy(@tile.position)
    @mesh.position.y += @height/2
  nextTile: ->
    xx = 0
    zz = 0
    xx = -1 if @tile.direction is '←'
    xx = +1 if @tile.direction is '→'
    zz = -1 if @tile.direction is '↑'
    zz = +1 if @tile.direction is '↓'
    @tile = @map[@tile.tile.y + zz][@tile.tile.x + xx]
    @tween = new TWEEN.Tween(@mesh.position).to({
      x: @tile.position.x,
      z: @tile.position.z
    }, 1000).onComplete(=> @nextTile()).easing(TWEEN.Easing.Linear.EaseNone).start()

@stage = new Stage()
@addEventListener "DOMContentLoaded", ->
  @stage.render()
  ((stage) ->
    setInterval ->
      stage.render()
    , 10
  ) @stage
