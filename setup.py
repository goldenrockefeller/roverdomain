from setuptools import setup, find_namespace_packages
from setuptools.extension import Extension
from Cython.Build import cythonize
import Cython.Compiler.Options
import os
import sys
import numpy

if __name__ == "__main__":

    namespace = "rockefeg"
    pkg = "roverdomain"
    
    setup(
        name = "{namespace}.{pkg}".format(**locals()),
        version='0.0.6',
        ext_modules =  (
            cythonize(
                "src/{namespace}/{pkg}/*.pyx".format(**locals()), 
                force=False,
                include_path = ["src/"],
                compiler_directives={
                    'language_level': 3,},)),
        zip_safe=False,
        packages=find_namespace_packages("src"),
        package_dir={'': 'src'}, 
        package_data={"": ["*.pxd"]},
        install_requires=['setuptools', 'cython', 'numpy', 'rockefeg.ndarray'],
        include_dirs=[numpy.get_include()],
        setup_requires = ['cython', 'numpy', 'rockefeg.ndarray'],
        script_args = ["build_ext",  "install"],
        namespace_packages = [namespace],
        python_requires = ">=3.5")
