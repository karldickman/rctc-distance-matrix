#!/usr/bin/env python

from argparse import ArgumentParser

from dotenv import load_dotenv

from DistanceMatrixCaller import distance_matrix_caller_from_env

def main():
    load_dotenv()
    # Parse arguments
    argument_parser = ArgumentParser()
    argument_parser.add_argument("address", nargs = "*")
    arguments = argument_parser.parse_args()
    # Call API
    caller = distance_matrix_caller_from_env()
    response = caller.geocode(arguments.address, "accurate")
    print(response["coordinates"][0]) # type: ignore

if __name__ == "__main__":
    main()