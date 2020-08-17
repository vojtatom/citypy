from citypy import obj, geojson, cityjson, height_map, serialize, to_json, geograph

from citypy.graph import graph_from_tsk
import matplotlib.pyplot as plt
import numpy as np


def export_bubny():
    modelStr = geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)

    #graph = geograph(modelStr)
    graph = graph_from_tsk("../demo/assets/bubny/TSK_ulice.json")

    modelBri = obj("../demo/assets/bubny/bubny_most_filtered.obj", storeIDs=True)
    metaBri = cityjson("../demo/assets/bubny/bubny_most.json")
    modelTer = obj("../demo/assets/bubny/bubny_ter.obj")

    vert = np.hstack((modelTer['vertices'], modelBri['vertices']))
    print(vert, vert.shape)

    surfaceModel = {
        "vertices": vert,
        "stats": modelTer["stats"]
    }

    hmap = height_map(surfaceModel, 4096)

    modelBui = obj("../demo/assets/bubny/bubny_bud.obj", storeIDs=True)
    metaBui = cityjson("../demo/assets/bubny/bubny_bud.json")


    mapdata = hmap['data'].reshape((hmap['height'], hmap['width']))


    plt.imshow(mapdata, cmap='gray', clim=(0, 500))
    plt.show()


    data = serialize({
        'terrain': modelTer,
        'streets': modelStr,
        'height': hmap,
        'graph': graph,
        'bridges': modelBri,
        'bridges_meta': metaBri,
        'buildings': modelBui,
        'buildings_meta': metaBui
    })


    to_json(data, 'bubny.json')


if __name__ == "__main__":
    export_bubny()
