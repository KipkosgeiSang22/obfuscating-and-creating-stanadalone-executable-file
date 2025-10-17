from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize("checkcp311_win_amd64.pyx", compiler_directives={'language_level': "3"})
)