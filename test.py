from slumpy.io import open_obj, open_geojson, serialize, to_json
from slumpy.height import render_height_map

#modelStr = open_geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)
modelTer = open_obj("../demo/assets/bubny/bubny_ter.obj")
hmap = render_height_map(modelTer, 4096)

print(hmap)
#data = serialize({
#    'terrain': modelTer,
#    'streets': modelStr
#})


#to_json(data, 'bubny.json')