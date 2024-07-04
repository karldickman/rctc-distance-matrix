#!/usr/bin/env python

from os import getenv

from dotenv import load_dotenv

from DistanceMatrixCaller import DistanceMatrixCaller

def main():
    load_dotenv()
    api_key = getenv("DISTANCE_MATRIX_API_KEY")
    if api_key is None:
        raise Exception("Required environment variable DISTANCE_MATRIX_API_KEY not set")
    caller = DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", api_key)
    print(caller.geocode("1600 Amphitheatre Parkway, Mountain View, CA", "accurate"))

if __name__ == "__main__":
    main()