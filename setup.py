import sys
import os
from setuptools import setup, find_packages
from setuptools.extension import Extension
from Cython.Build import cythonize
import numpy as np

#from distutils.extension import Extension
#from distutils.core import setup


def scandir(dir, files=[], cfiles=[]):
	for file in os.listdir(dir):
		path = os.path.join(dir, file)
		print("testing", file)
		if os.path.isfile(path) and path.endswith(".pyx"):
			files.append(path.replace(os.path.sep, ".")[:-4])
		elif os.path.isfile(path) and path.endswith(".cpp"):
			cfiles.append(path)
		elif os.path.isdir(path):
			scandir(path, files, cfiles)
			
	return files, cfiles

# generate an Extension object from its dotted name
def makeExtension(extName, cfiles):
	extPath= extName.replace(".", os.path.sep) + ".pyx" 
	print('path:', extName, [extPath] + cfiles)
	return Extension(
		extName,
		[extPath] + cfiles,
		# adding the '.' to include_dirs is CRUCIAL!!
		include_dirs=[".", np.get_include()],
		extra_compile_args=["-Wall"],
		extra_link_args=['-O2', '-Wno-cpp', '-std=c++11'],
		define_macros=[('NPY_NO_DEPRECATED_API', 'NPY_1_7_API_VERSION')],
		language="c++"
		)

# get the list of extensions
extNames, cfiles = scandir("citypy") 

# and build up the set of Extension objects
extensions = [makeExtension(name, cfiles) for name in extNames]

setup(
	name='citypy',         # How you named your package folder (MyLib)
	packages=['citypy'],   # Chose the same as "name"
	# Start with a small number and increase it with every change you make
	version='0.0.1',
	# Chose a license from here: https://help.github.com/articles/licensing-a-repository
	license='MIT',
	# Give a short description about your library
	description='Support package for yet another city data format',
	author='Vojtech Tomas',                   # Type in your name
	author_email='tomas@vojtatom.cz',      # Type in your E-Mail
	# Provide either the link to your github or to your website
	url='https://github.com/vojtatom/citypy',
	# I explain this later on
	download_url='TODO',  #TODO
	# Keywords that define your package best
	keywords=['city', 'visualization', 'format'],
	install_requires=[            # dependencies
		'Cython >= 0.18',
		'numpy',
		'scipy'
		],
	classifiers=[
		# Chose either "3 - Alpha", "4 - Beta" or "5 - Production/Stable" as the current state of your package
		'Development Status :: 3 - Alpha',
		# Define that your audience are developers
		'Intended Audience :: Developers',
		'Topic :: Multimedia :: Graphics',
		'License :: OSI Approved :: MIT License',   # Again, pick a license
		# Specify which pyhton versions that you want to support
		'Programming Language :: Python :: 3.4',
		'Programming Language :: Python :: 3.5',
		'Programming Language :: Python :: 3.6',
	],
	ext_modules=cythonize(extensions),
	include_package_data=True
)
