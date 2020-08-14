# cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True
# distutils: language=c++

import numpy as np
import json
import uuid
import base64
from tqdm import tqdm

oid = 0

def copyVector(bufferTo, bufferFrom, idTo, idFrom):
    idTo *= 3
    idFrom *= 3
    bufferTo[idTo:idTo + 3] = bufferFrom[idFrom:idFrom + 3]


def parse_normal(tokens, normalBuffer, filled):
    normalBuffer[filled] = float(tokens[1])
    normalBuffer[filled + 1] = float(tokens[2])
    normalBuffer[filled + 2] = float(tokens[3])


def parse_vertex(tokens, vertexBuffer, stats, filled):
    vec = np.array([float(tokens[1]), float(tokens[2]), float(tokens[3])], dtype=np.float32) 

    vertexBuffer[filled: filled + 3] = vec

    np.minimum(stats['min'], vec, out=stats['min'], dtype=np.float32)
    np.maximum(stats['max'], vec, out=stats['max'], dtype=np.float32)


def setup_normal(vertexIDs, vertexBuffer):
    vs = []
    for vid in vertexIDs:
        rid = 3 * vid
        vs.append(np.array([vertexBuffer[rid], vertexBuffer[rid + 1], vertexBuffer[rid + 2]]))

    a = vs[2] - vs[0]
    b = vs[1] - vs[0]
    normal = np.cross(a, b)

    return normal / np.linalg.norm(normal)


def load_no_normals(lines, counts, storeIDs):
    global oid

    rvert = np.empty(counts['v'] * 3, dtype=np.float32)
    stats = {
        'min': np.array([np.inf, np.inf, np.inf], dtype=np.float32),
        'max': np.array([-np.inf, -np.inf, -np.inf], dtype=np.float32)
    }

    filled = 0

    for line in  tqdm(lines):
        tokens = line.split(' ')
        if tokens[0] == 'v':
            parse_vertex(tokens, rvert, stats, filled)
            filled += 3
    

    filled = 0
    vertices = np.empty(counts['t'] * 3 * 3, dtype=np.float32)
    normals = np.empty(counts['t'] * 3 * 3, dtype=np.float32)
    objects, idToObj, objToId = None, None, None

    if storeIDs:
        objects = np.empty(counts['t'] * 3, dtype=np.float32)
        idToObj = {}
        objToId = {}

    
    for line in tqdm(lines):
        tokens = line.split(' ')
        
        if tokens[0] == 'o' and storeIDs:
            oid += 1
            idToObj[oid] = tokens[1]
            objToId[tokens[1]] = oid

        elif tokens[0] == 'f':
            faceVertIds  = []

            for i in range(1, len(tokens)):
                faceVertIds.append(int(tokens[i]) - 1)
            
            faceIDs = [faceVertIds[0], 0, 0]

            #split face into triangles
            for i in range(len(faceVertIds) - 2):
                faceIDs[1] = faceVertIds[i + 1]
                faceIDs[2] = faceVertIds[i + 2]
                
                copyVector(vertices, rvert, filled, faceIDs[0])
                copyVector(vertices, rvert, filled + 1, faceIDs[1])
                copyVector(vertices, rvert, filled + 2, faceIDs[2])
                normal = setup_normal(faceIDs, rvert)
                copyVector(normals, normal, filled, 0)
                copyVector(normals, normal, filled + 1, 0)
                copyVector(normals, normal, filled + 2, 0)
                
                if storeIDs:
                    objects[filled] = oid
                    objects[filled + 1] = oid
                    objects[filled + 2] = oid

                filled += 3
            
        
    if storeIDs:
        return {
            'type': 'obj',
            'vertices': vertices,
            'normals': normals,
            'objects': objects,
            'idToObj': idToObj,
            'objToId': objToId,
            'stats': stats
        }

    else:
        return {
            'type': 'obj',
            'vertices': vertices,
            'normals': normals,
            'stats': stats
        }


def load_with_normals(lines, counts, storeIDs):
    global oid

    rvert = np.empty(counts['v'] * 3, dtype=np.float32)
    rnorm = np.empty(counts['v'] * 3, dtype=np.float32)
    stats = {
        'min': np.array([np.inf, np.inf, np.inf], dtype=np.float32),
        'max': np.array([-np.inf, -np.inf, -np.inf], dtype=np.float32)
    }

    filledVert = 0
    filledNorm = 0

    for line in  tqdm(lines):
        tokens = line.split(' ')
        if tokens[0] == 'v':
            parse_vertex(tokens, rvert, stats, filledVert)
            filledVert += 3
        if tokens[0] == 'vn':
            parse_normal(tokens, rnorm, filledNorm)
            filledNorm += 3
    

    filled = 0
    vertices = np.empty(counts['t'] * 3 * 3, dtype=np.float32)
    normals = np.empty(counts['t'] * 3 * 3, dtype=np.float32)
    objects, idToObj, objToId = None, None, None


    if storeIDs:
        objects = np.empty(counts['t'] * 3, dtype=np.float32)
        idToObj = {}
        objToId = {}

    
    for line in tqdm(lines):
        tokens = line.split(' ')
        
        if tokens[0] == 'o' and storeIDs:
            oid += 1
            idToObj[oid] = tokens[1]
            objToId[tokens[1]] = oid

        elif tokens[0] == 'f':
            faceVertIds = []
            faceNormIds = []
            missingNormal = False

            for i in range(1, len(tokens)):
                vertIds = tokens[i].split('/')

                faceVertIds.append(int(vertIds[0]) - 1)

                if len(vertIds) == 3:
                    faceNormIds.append(int(vertIds[len(vertIds) - 1]) - 1) 
                else:
                    faceNormIds.append(-1)
                    missingNormal = True

            triVertIds = [faceVertIds[0], 0, 0]
            triNormIds = [faceNormIds[0], 0, 0]

            #split face into triangles
            for i in range(len(faceVertIds) - 2):
                triVertIds[1] = faceVertIds[i + 1]
                triVertIds[2] = faceVertIds[i + 2]
                triNormIds[1] = faceNormIds[i + 1]
                triNormIds[2] = faceNormIds[i + 2]
                
                copyVector(vertices, rvert, filled, triVertIds[0])
                copyVector(vertices, rvert, filled + 1, triVertIds[1])
                copyVector(vertices, rvert, filled + 2, triVertIds[2])

                if missingNormal:
                    normal = setup_normal(triVertIds, rvert)
                    copyVector(normals, normal, filled, 0)
                    copyVector(normals, normal, filled + 1, 0)
                    copyVector(normals, normal, filled + 2, 0)
                else:
                    copyVector(normals, rnorm, filled, triNormIds[0])
                    copyVector(normals, rnorm, filled + 1, triNormIds[1])
                    copyVector(normals, rnorm, filled + 2, triNormIds[2])
                    
                
                if storeIDs:
                    objects[filled] = oid
                    objects[filled + 1] = oid
                    objects[filled + 2] = oid

                filled += 3      
        
    if storeIDs:
        return {
            'type': 'obj',
            'vertices': vertices,
            'normals': normals,
            'objects': objects,
            'idToObj': idToObj,
            'objToId': objToId,
            'stats': stats
        }
    else:
        return {
            'type': 'obj',
            'vertices': vertices,
            'normals': normals,
            'stats': stats
        }


def countPrimitives(lines):
    vertices = 0
    normals = 0
    triangles = 0

    for line in lines:
        tokens = line.split(' ')
        ltype = tokens[0]

        if ltype == 'v':
            vertices += 1
        elif ltype == 'vn':
            normals += 1
        elif ltype == 'f':
            triangles += len(tokens) - 3

    return { 'v': vertices, 'n': normals, 't': triangles }


def open_obj(filename, storeIDs = False):
    print(f"Loading OBJ: {filename}")

    with open(filename, 'r') as file:
        contents = file.read()

    lines = contents.split('\n')
    counts = countPrimitives(lines)


    if counts['n'] == 0:
        return load_no_normals(lines, counts, storeIDs)
    else: 
        return load_with_normals(lines, counts, storeIDs)



def open_cityjson(filename):
    global oid
    print(f"Loading geoJson: {filename}")

    with open(filename, 'r') as file:
        contents = file.read()

    contents = json.loads(contents)
    contents = contents['CityBuildings']

    for b in contents:
        del b['geometry']
        del b['semantic']['values']
    
    return {
        'type': 'city',
        'data': contents
    }

def countLineVerts(features):
    points = 0
    for feature in features:
        if feature['geometry']['type'] == 'LineString':
            points += len(feature['geometry']['coordinates']) * 2 - 2

    return points

def open_geojson(filename, dims = 2, storeIDs = False):
    global oid
    print(f"Loading geoJson: {filename}")

    with open(filename, 'r') as file:
        contents = file.read()

    contents = json.loads(contents)


    if contents['type'] == 'FeatureCollection':
        features = contents['features']

        lineVertCount = countLineVerts(features)
        lineVertices = np.empty(lineVertCount * dims, dtype=np.float32)
        lineFilled = 0

        if storeIDs:
            lineIds = np.empty(lineVertCount, dtype=np.uint32)
            lineIdsFilled = 0
            idToObj = {}
            objToId = {}
            metadata = {}


        for feature in tqdm(features):
            geom = feature['geometry']

            if storeIDs:
                uid = str(uuid.uuid4())
                oid += 1
                idToObj[oid] = uid
                objToId[uid] = oid

                if 'properties' in feature:
                    metadata[uid] = feature['properties']
                else:
                    metadata[uid] = {}

            if geom['type'] == 'Point':
                pass #TODO
            elif geom['type'] == 'LineString':

                last = len(geom['coordinates']) - 1
                for i, coord in enumerate(geom['coordinates']):
                    if i > 0 and i < last: 
                        lineVertices[lineFilled:lineFilled + dims] = coord
                        lineFilled += dims
                    
                    lineVertices[lineFilled:lineFilled + dims] = coord
                    lineFilled += dims

                    if storeIDs:
                        lineIds[lineIdsFilled] = oid
                        lineIdsFilled += 1    

            elif geom['type'] == 'Polygon':
                pass #TODO
            elif geom['type'] == 'MultiPoint':                
                pass #TODO
            elif geom['type'] == 'MultiLineString':                
                pass #TODO
            elif geom['type'] == 'MultiPolygon':                
                pass #TODO                           
            else:
                print(f"parsing geoJSON: encountered unknown geometry type: {geom['type']}")
    else:
        pass #TODO


    if storeIDs:
        return {
            'type': 'geo',
            'lineVertices': lineVertices,
            'lineObjects': lineIds,
            'idToObj': idToObj,
            'objToId': objToId,
            'metadata': metadata
        }
    else:
        return {
            'type': 'geo',
            'lineVertices': lineVertices
        }




def serialize_array(array, dtype):
    a = np.ascontiguousarray(dtype(array), dtype=dtype)
    a = base64.b64encode(a.data)
    return a.decode('utf-8')


def serialize_obj(data):
    data['vertices'] = serialize_array(data['vertices'], np.float32)
    data['normals'] = serialize_array(data['normals'], np.float32)
    data['stats'] = {
        'min': serialize_array(data['stats']['min'], np.float32),
        'max': serialize_array(data['stats']['max'], np.float32)
    }

    if 'objects' in data:
        data['objects'] = serialize_array(data['objects'], np.uint32)


def serialize_geo(data):
    data['lineVertices'] = serialize_array(data['lineVertices'], np.float32)

    if 'lineObjects' in data:
        data['lineObjects'] = serialize_array(data['lineObjects'], np.uint32)


def serialize_height(data):
    data['data'] = serialize_array(data['data'], np.float32)


def serialize_graph(data):
    graph_data = {}
    for k, v in data['data'].items():
        graph_data[serialize_array(k, np.float32)] = [ serialize_array(node, np.float32) for node in v ]
    data['data'] = graph_data


def serialize_all(models: dict):
    for key, model in models.items():
        if model['type'] == 'obj':
            serialize_obj(model)
        elif model['type'] == 'geo':
            serialize_geo(model)
        elif model['type'] == 'heightmap':
            serialize_height(model)
        elif model['type'] == 'graph':
            serialize_graph(model)

    return models


class MyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        else:
            return super(MyEncoder, self).default(obj)


def convert_to_json(data, filename):
    data = json.dumps(data, separators=(',', ':'), cls=MyEncoder)
    #data = json.dumps(data, separators=[',\n', ':'], indent=2)
    
    with open(filename, 'w') as file:
        file.write(data)
