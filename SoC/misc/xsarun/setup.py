from setuptools import setup, find_packages

setup(
    name="xsarun",
    version="1.0",
    packages=find_packages(),
    install_requires=[
        'shutil',
        'zipfile',
    ],
    entry_points={
        'console_scripts': [
            'xsarun=xsarun.core:main'
        ]
    },
    include_package_data=True,
    package_data={
        'xsarun': ['templates/*.ipynb'],
    },
)
