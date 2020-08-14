from slumpy import obj, geojson, height_map, serialize, to_json, geograph
from slumpy.graph import graph_from_tsk
import matplotlib.pyplot as plt
import numpy as np


def export_bubny():
    modelStr = geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)
    #graph = graph_from_tsk(modelStr)
    graph = graph_from_tsk("../demo/assets/bubny/TSK_ulice.json")
    modelTer = obj("../demo/assets/bubny/bubny_ter.obj")
    hmap = height_map(modelTer, 4096)


    mapdata = hmap['data'].reshape((hmap['height'], hmap['width']))


    plt.imshow(mapdata, cmap='gray', clim=(0, 500))
    plt.show()


    data = serialize({
        'terrain': modelTer,
        'streets': modelStr,
        'height': hmap,
        'graph': graph
    })


    to_json(data, 'bubny.json')


if __name__ == "__main__":
    export_bubny()
