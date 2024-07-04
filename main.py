#!/usr/bin/env python

from argparse import ArgumentParser
from os import getenv
from typing import List

from dotenv import load_dotenv
from pandas import DataFrame

from DistanceMatrixCaller import DistanceMatrixCaller, LngLat

def main():
    # Environment variables
    load_dotenv()
    api_key = getenv("DISTANCE_MATRIX_API_KEY")
    if api_key is None:
        raise Exception("Required environment variable DISTANCE_MATRIX_API_KEY not set")
    # Arguments
    argument_parser = ArgumentParser()
    argument_parser.add_argument("address", type = str, nargs = "+", help = "The addresses to geocode")
    argument_parser.add_argument("--url", action = "store_true", help = "Print a Distance Matrix API URL instead of calling it")
    arguments = argument_parser.parse_args()
    addresses: List[str] = arguments.address
    caller = DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", api_key)
    origins = caller.geocode(addresses, "accurate")
    origin_coordinates: List[LngLat] = origins["coordinates"].to_list()
    destinations = DataFrame({
        "address": [
            "Sauvie Island",
            "Gresham",
            "Fairmount",
            "Sellwood Riverfront Park",
            "Thurman",
            "Willamette Boulevard",
            "Crown-Zellerbach Trail",
            "Banks-Vernonia Trail",
        ],
        "coordinates": [
            (-122.8154507, 45.6292369),
            (-122.4307401, 45.4969289),
            (-122.7073407, 45.5006769),
            (-122.6629027, 45.4657357),
            (-122.7253299, 45.5391237),
            (-122.6963084, 45.5662581),
            (-122.9034284, 45.783716),
            (-123.1638105, 45.6648253),
        ],
    })
    destination_coordinates: List[LngLat] = destinations["coordinates"].to_list()
    if arguments.url:
        print(caller.distance_matrix_url(origin_coordinates, destination_coordinates, "accurate"))
    else:
        distance_matrix = caller.distance_matrix(origin_coordinates, destination_coordinates, "accurate")
        origins = origins.rename(columns = {
            "address": "origin_address",
            "coordinates": "origin",
        })
        destinations = destinations.rename(columns = {
            "address": "destination_address",
            "coordinates": "destination",
        })
        distance_matrix = origins.merge(distance_matrix, how = "left", on = ["origin"]) # type: ignore
        distance_matrix = distance_matrix.merge(destinations, how = "right", on = ["destination"]) # type: ignore
        distance_matrix = distance_matrix[["origin_address", "destination_address", "status", "distance_mi", "duration_min"]].rename(columns = {
            "origin_address": "origin",
            "destination_address": "destination",
        })
        print(distance_matrix)

if __name__ == "__main__":
    main()