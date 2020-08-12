from slumpy import obj, geojson, height_map, serialize, to_json

import matplotlib.pyplot as plt
import numpy as np


modelStr = geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)
modelTer = obj("../demo/assets/bubny/bubny_ter.obj")
hmap = height_map(modelTer, 4096)


mapdata = hmap['data'].reshape((hmap['height'], hmap['width']))

plt.imshow(mapdata, cmap='gray', clim=(0, 500))
plt.show()


data = serialize({
    'terrain': modelTer,
    'streets': modelStr,
    'height': hmap
})


to_json(data, 'bubny.json')