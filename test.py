from slumpy import obj, geojson, height_map, serialize, to_json, geograph
import matplotlib.pyplot as plt
import numpy as np


def export_bubny():
    modelStr = geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)
    modelTer = obj("../demo/assets/bubny/bubny_ter.obj")
    modelStr = geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)
    graph = geograph(modelStr)
    hmap = height_map(modelTer, 4096)


    mapdata = hmap['data'].reshape((hmap['height'], hmap['width']))
    print(np.amin(hmap['data']))
    print(np.amax(hmap['data']))


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
