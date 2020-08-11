from slumpy.io import open_obj, open_geojson, serialize, to_json





modelStr = open_geojson("../demo/assets/bubny/TSK_ulice.json", storeIDs=True)
modelStr['name'] = 'streets'
modelTer = open_obj("../demo/assets/bubny/bubny_ter.obj")
modelTer['name'] = 'terrain'

data = serialize([modelTer, modelStr])
to_json(data, 'bubny.json')