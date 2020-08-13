import numpy as np
from tqdm import tqdm

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

