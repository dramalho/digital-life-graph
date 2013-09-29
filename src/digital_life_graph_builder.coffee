class @DigitalLifeGraphBuilder
  constructor: (element_id, data) ->
    @sigma_instance = sigma.init( document.getElementById(element_id) )
      .drawingProperties( {
                defaultLabelColor: '#fff',
                defaultLabelSize: 14,
                defaultLabelBGColor: '#fff',
                defaultLabelHoverColor: '#000',
                labelThreshold: 1,
                defaultEdgeType: 'curve'
              })
      .graphProperties( {
                minNodeSize: 0.5,
                maxNodeSize: 10,
                minEdgeSize: 1,
                maxEdgeSize: 1,
                sideMargin: 50
              })
      .mouseProperties( {
                maxRatio: 32
            })

      @service_nodes = data.service_nodes || {}
      @device_nodes = data.device_nodes || {}
      @service_edges = data.service_edges || {}
      @device_service_edges = data.device_service_edges || {}
      @service_device_edges = data.service_device_edges || {}

      @node_frequency = @nodeFrequency( @service_edges.concat( @device_service_edges, @service_device_edges ) )

  nodeId: (label) ->
    label = label.replace(/_/g, "-").toLowerCase() if label?

  nodeFrequency: (edges) ->
    result = {}

    $(edges).each (idx, el) =>
      result[@nodeId(el[0])] = +result[@nodeId(el[0])] + 1 || 1
      result[@nodeId(el[1])] = +result[@nodeId(el[1])] + 1 || 1

    result

  createNodes: (nodes, frequency, x_offset, style ) ->
    frequency = frequency || {}
    x_offset = x_offset || 0
    style = style || { type: 'circular', radius: 200}

    nodes = nodes.filter (el) =>
      frequency[ @nodeId(el[0]) ] > 0

    $(nodes).each (idx, el) =>
      switch style.type
        when 'circular'
          position = @nodePositionInACircle(nodes.length, idx)

          position.x = position.x * style.radius
          position.y = position.y * style.radius
        when 'line'
          position = @nodePositionInALine(nodes.length,idx)
          position.y = position.y * style.distance

      position.x = position.x + x_offset

      @sigma_instance.addNode @nodeId(el[0]), 
        {
          label: el[0],
          color: el[1],
          x: position.x,
          y: position.y,
          size: 1 + (frequency[@nodeId(el[0])] || 0 )
        }

  nodePositionInACircle: (element_count,element_index) ->
    {
      x: ( Math.sin( (Math.PI * 2) / element_count * element_index ) ) || 0,
      y: ( Math.cos( (Math.PI * 2) / element_count * element_index ) ) || 1
    }

  nodePositionInALine: (element_count, element_index) ->
    el_initial_position = 0 - (element_count/2)
    {
      x: 0,
      y: el_initial_position + element_index
    }

  draw: ->
    # Calculate the frequency of all the nodes
    @node_frequency

    @createNodes(@service_nodes, @node_frequency ,    0, {type: 'circular', radius: 150} )
    @createNodes(@device_nodes, @node_frequency , -400,  {type: 'line', distance: 40 } )

    $(@service_edges.concat(@service_device_edges)).each (idx,el) =>
      @sigma_instance.addEdge( el.join('_'), el[0], el[1], {arrow: 'target'} )

    $(@device_service_edges).each (idx,el) =>
      @sigma_instance.addEdge( el.join('_'), el[0], el[1], {arrow: 'target', type: 'line'} )
   
    @sigma_instance.draw()

    this