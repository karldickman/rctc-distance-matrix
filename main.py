#!/usr/bin/env python

from argparse import ArgumentParser
import json
from os import getenv
from typing import List

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
    argument_parser.add_argument("address", type = str, nargs = "+", help = "The addresses to geocode")
    argument_parser.add_argument("--url", action = "store_true", help = "Print a Distance Matrix API URL instead of calling it")
    arguments = argument_parser.parse_args()
    addresses: List[str] = arguments.address
    caller = DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", api_key)
    origin = caller.geocode(addresses, "accurate")
    destination = -122.8154507, 45.6292369
    if arguments.url:
        print(caller.distance_matrix_url(origin, [destination], "accurate"))
    else:
        print(json.dumps(caller.distance_matrix(origin, [destination], "accurate"), indent = 4))

if __name__ == "__main__":
    main()