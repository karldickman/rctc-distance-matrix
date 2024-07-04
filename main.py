#!/usr/bin/env python

from argparse import ArgumentParser
from datetime import datetime
from os import getenv
from typing import List

from dotenv import load_dotenv
from pandas import DataFrame, read_csv # type: ignore

from DistanceMatrixCaller import Accuracy, DistanceMatrixCaller, LngLat

def analyze(caller: DistanceMatrixCaller, origin_addresses: List[str], destinations: DataFrame, arrival_time: datetime, accuracy: Accuracy) -> DataFrame:
    # Geocode addresses
    origins = caller.geocode(origin_addresses, accuracy)
    # Convert coordinates to LngLat
    origin_coordinates: List[LngLat] = origins["coordinates"].to_list()
    destination_coordinates: List[LngLat] = [(float(row["longitude"]), float(row["latitude"])) for _, row in destinations.iterrows()] # type: ignore
    destinations["coordinates"] = destination_coordinates
    # Call API
    distance_matrix = caller.distance_matrix_chunked(origin_coordinates, destination_coordinates, arrival_time, "accurate")
    # Merge distance matrix with origin and destination
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
    return distance_matrix

def main():
    # Environment variables
    load_dotenv()
    api_key = getenv("DISTANCE_MATRIX_API_KEY")
    if api_key is None:
        raise Exception("Required environment variable DISTANCE_MATRIX_API_KEY not set")
    # Arguments
    argument_parser = ArgumentParser()
    argument_parser.add_argument("travel_date", type = str, help = "The date on which to measure travel time")
    argument_parser.add_argument("--origins", type = str, default = "origins.csv", help = "The CSV file containing the origins and their coordinates")
    argument_parser.add_argument("-o", "--out", type = str, help = "The CSV file to which to write the results")
    argument_parser.add_argument("--destinations", type = str, default = "destinations.csv", help = "The CSV file containing the destinations and their coordinates")
    arguments = argument_parser.parse_args()
    travel_date = datetime.fromisoformat(arguments.travel_date)
    arrival_time = datetime(travel_date.year, travel_date.month, travel_date.day, 8)
    origins = read_csv(arguments.origins)
    origin_addresses: List[str] = origins["address"].to_list()
    destinations = read_csv(arguments.destinations)
    # Analysis
    caller = DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", api_key)
    destinations.to_csv("destinations.csv", index = False)
    distance_matrix = analyze(caller, origin_addresses, destinations, arrival_time, "accurate")
    if arguments.out is None:
        print(distance_matrix)
    else:
        distance_matrix.to_csv(arguments.out, index = False)

if __name__ == "__main__":
    main()