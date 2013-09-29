class GraphBuilder
  constructor: (dom_element, data) ->
    @sigma_instance = sigma.init( dom_element )
      .drawingProperties {
          defaultLabelColor: '#fff',
          defaultLabelSize: 14,
          defaultLabelBGColor: '#fff',
          defaultLabelHoverColor: '#000',
          labelThreshold: 1,
          defaultEdgeType: 'curve'
        }
      .graphProperties {
          minNodeSize: 0.5,
          maxNodeSize: 10,
          minEdgeSize: 1,
          maxEdgeSize: 1,
          sideMargin: 50
        }
      .mouseProperties {
          maxRatio: 32
        }

      @service_nodes = data.service_nodes || {}
      @device_nodes = data.device_nodes || {}
      @service_edges = data.service_edges || {}
      @device_service_edges = data.device_service_nodes || {}
      @service_device_edges = data.service_service_nodes || {}

  nodeId: (label) ->
    label = label.replace(/_/g, "-").toLowerCase() if label?

  nodeFrequency: (edges) ->
    result = {}

    $(edges).each (idx) =>
      result[@nodeId(this[0])] = +result[@nodeId(this[0])] + 1 || 1
      result[@nodeId(this[1])] = +result[@nodeId(this[1])] + 1 || 1

    result

  createNodes: (nodes, frequency, x_offset, radius ) ->
    frequency = frequency || {}
    x_offset = x_offset || 0
    radius = radius || 200

    nodes = nodes.filter (el) =>
      frequency[ @nodeId(el[0]) ] > 0

    $(nodes).each (idx) =>
      @sigma_instante.addNode @nodeId(this[0]), 
        {
          label: this[0],
          color: this[1],
          x: (Math.sin( (Math.PI * 2) / nodes.length * idx) * radius) + x_offset,
          y: Math.cos( (Math.PI * 2) / nodes.length * idx) * radius,
          size: 1 + (frequency[@nodeId(this[0])] || 0 )
        }

  draw: ->
    # Calculate the frequency of all the nodes
    node_frequency = @nodeFrequency( @service_edges.concat( @device_service_edges, @service_device_edges ) )

    @createNodes(@service_nodes, node_frequency ,    0, 150 )
    @createNodes(@device_nodess, node_frequency , -400,  50 )

    $(@service_edges.concat(@service_device_edges)).each (idx) =>
      @sigma_instance.addEdge( this.join('_'), this[0], this[1], {arrow: 'target'} )

    $(@device_service_edges).each (idx) =>
      @sigma_instance.addEdge( this.join('_'), this[0], this[1], {arrow: 'target', type: 'line'} )
   
    @sigma_instance.draw