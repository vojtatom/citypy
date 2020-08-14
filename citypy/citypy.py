from .io import open_obj, open_geojson, serialize_all, convert_to_json, open_cityjson #pylint: disable=no-name-in-module,import-error
from .height import render_height_map #pylint: disable=no-name-in-module,import-error
from .graph import graph_from_geo

def obj(filename, storeIDs = False):
    """Open .obj file and covert it into GPU-friendly format.
    All vertices and normals are arranged into two buffers 
    represented by numpy arrays. 
    
    If required, a third buffer is attached with object id 
    assigning each vertex to their object.

    Args:
        filename (string): .obj source file
        storeIDs (bool, optional): Flag enabling creation of the object-id buffer. Defaults to False.

    Returns:
        dict: Dictionary containing labeled buffers and additional required metadata.
    """
    return open_obj(filename, storeIDs)

def geojson(filename, dims = 2, storeIDs = False):
    """Open .json file with geoJSON structure. Loads the contents
    and organizes them into GPU-friendly format. 

    If required, a buffer with object ids 
    assigning each vertex to their object is attached.

    Args:
        filename (string): .json source file
        dims (int, optional): Dimensionality of the data gemoetry. Defaults to 2.
        storeIDs (bool, optional): Flag enabling creation of the object-id buffer. Defaults to False.

    Returns:
        dict: Dictionary containing labeled buffers and additional required metadata.
    """
    return open_geojson(filename, dims, storeIDs)

def cityjson(filename):
    """Open .json file with CityJSON structure. Load the contents
    and filter out. the geometry.

    Args:
        filename (string): .json source file

    Returns:
        dict: Dictionary containing loaded metadata for each object.
    """
    return open_cityjson(filename)

def serialize(models):
    """Serialize data into a format that can be easily stringified.

    Args:
        models (dict): Slumpy models to be stringified.

    Returns:
        dict: Stringified models.
    """
    return serialize_all(models)

def to_json(data, filename):
    """Dumps data into a .json file

    Args:
        data (dict): Dict with slumpy models in stringifiable format.
        filename (string): Name of the output file. The name should contain .json suffix.

    Returns:
        None
    """
    
    convert_to_json(data, filename)

def height_map(model, res):
    """Renders a heightmap for supplied slumpy model.

    Args:
        model (dict): slumpy model containing attribute "vertices" and "stats"
        res (int): resolution of the height map in the longer dimension

    Returns:
        dict: Slumpy model of the heightmap, contains np.float32 array, width and height
    """
    return render_height_map(model, res)

def geograph(geomodel):
    """Compute graph from slumpy geo model.

    Args:
        geomodel (dict): slupy model obtained by geojson function

    Returns:
        dict: Graph of neighboring nodes, nodes are identified by their coordinates.
    """
    return graph_from_geo(geomodel)