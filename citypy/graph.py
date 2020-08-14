import numpy as np
from tqdm import tqdm
import json

def graph_degrees(graph):
    stats = {}
    for k, v in graph.items():
        connections = len(v)
    
        if connections not in stats:
            stats[connections] = 0
        stats[connections] += 1

    return stats


def construct_graph(segments):
    graph = {}

    print("Computing graph")
    for a, b in tqdm(segments):
        al = tuple(a)
        bl = tuple(b)

        if al not in graph:
            graph[al] = []
        graph[al].append(bl)

        if bl not in graph:
            graph[bl] = []
        graph[bl].append(al)


    
    return graph, graph_degrees(graph)


def graph_from_tsk(filename):
    with open(filename, 'r') as file:
        contents = file.read()

    contents = json.loads(contents)

    if contents['type'] != 'FeatureCollection':
        raise Exception('FeatureCollection required.')

    features = contents['features']
    graph = {}

    for feature in features:
        geo = feature['geometry']
        if geo['type'] != "LineString":
            raise Exception('LineString required.')

        direct = feature["properties"]["SMEROVOST"]
        coord = geo['coordinates']
        L = len(coord)

        if direct == 0:  #bothdir
            for a, b in zip(coord[0:L - 1], coord[1:L]):
                al = tuple(a)
                bl = tuple(b)

                if al not in graph:
                    graph[al] = []
                graph[al].append(bl)

                if bl not in graph:
                    graph[bl] = []
                graph[bl].append(al)
                
        
        if direct == 1:  #there
            for a, b in zip(coord[0:L - 1], coord[1:L]):
                al = tuple(a)
                bl = tuple(b)

                if al not in graph:
                    graph[al] = []
                graph[al].append(bl)
        
        if direct == 2:  #back
            for a, b in zip(coord[0:L - 1], coord[1:L]):
                al = tuple(a)
                bl = tuple(b)

                if bl not in graph:
                    graph[bl] = []
                graph[bl].append(al)

        
    return {
        'type': 'graph',
        'data': graph,
        'degrees': graph_degrees(graph) 
    }


def graph_from_geo(geomodel):
    if 'lineVertices' not in geomodel:
        raise Exception('Graph construction requires model containing attribute "lineVertices".')

    size = geomodel['lineVertices'].shape[0] // 4
    segments = geomodel['lineVertices'].reshape(size, 2, 2)

    graph, deg = construct_graph(segments)
    return {
        'type': 'graph',
        'data': graph,
        'degrees': deg 
    }

