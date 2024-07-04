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
    # Parse arguments
    argument_parser = ArgumentParser()
    argument_parser.add_argument("address", nargs = "*")
    arguments = argument_parser.parse_args()
    # Call API
    caller = DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", api_key)
    response = caller.geocode(arguments.address, "accurate")
    print(response["coordinates"][0]) # type: ignore

if __name__ == "__main__":
    main()