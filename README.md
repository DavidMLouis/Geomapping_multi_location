# Geomapping_multi_location
Configures in real time distance between two data set locations based on longitude and latitude 

This script is assuming that database_building_for_geolocation has been run: https://github.com/DavidMLouis/database_building_for_geolocation

Although uploading files with longitude and latitude coordinates already compiled will suffice. This program is taking an achored list of locations and comparing across the secondary list to find the top closest locations. It then proceeds to loop through the entire list creating a matrix of top locations that match based on driving distance. This metric can be swapped out for driving time or straight line distance
