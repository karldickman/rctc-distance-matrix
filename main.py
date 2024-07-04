#!/usr/bin/env python

from argparse import ArgumentParser
from os import getenv

from dotenv import load_dotenv

from DistanceMatrixCaller import DistanceMatrixCaller

def main():
    # Environment variables
    load_dotenv()
    api_key = getenv("DISTANCE_MATRIX_API_KEY")
    if api_key is None:
        raise Exception("Required environment variable DISTANCE_MATRIX_API_KEY not set")
    # Arguments
    argument_parser = ArgumentParser()
    argument_parser.add_argument("address", type = str, help = "The address to geocode")
    arguments = argument_parser.parse_args()
    caller = DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", api_key)
    origin = caller.geocode(arguments.address, "accurate")
    destination = -122.8154507, 45.6292369
    print(caller.distance_matrix([origin], [destination], "accurate"))

if __name__ == "__main__":
    main()