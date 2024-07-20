from collections import OrderedDict
from datetime import datetime
import json
from os import getenv
from typing import List, Literal, Tuple
from urllib.parse import urlencode

import pandas as pd
from pandas import DataFrame
import numpy as np

import cache_requests as requests

class DistanceMatrixException(Exception):
    ...

class GeocodingException(Exception):
    ...

type Accuracy = Literal["fast"] | Literal["accurate"]
type LngLat = Tuple[float, float]

def lng_lat_to_url_arg(coordinates: LngLat) -> str:
    return ",".join(map(str, reversed(coordinates)))

def parse_lat_lng(text: str) -> LngLat:
    try:
        lat, lng = text.split(",")
    except:
        raise ValueError(f"Invalid coordinate {text}")
    return float(lng), float(lat)

class DistanceMatrixCaller(object):
    "Makes calls to the Distance Matrix API."

    accurate_domain: str
    "The domain to call for accurate results."

    distance_matrix_api_keys: dict[Accuracy, str]
    "The API Keys used to authenticate distance matrix calls."

    fast_domain: str
    "The domain to call for fast results."

    geocode_api_keys: dict[Accuracy, str]
    "The API Keys used to authenticate geocode calls."

    max_dimensions: int
    "The maximum number of elements in the origin-destination matrix."

    def __init__(self, fast_domain: str, accurate_domain: str, distance_matrix_api_keys: dict[Accuracy, str], geocode_api_keys: dict[Accuracy, str]):
        self.fast_domain = fast_domain
        self.accurate_domain = accurate_domain
        self.distance_matrix_api_keys = distance_matrix_api_keys
        self.geocode_api_keys = geocode_api_keys
        self.max_dimensions = 1

    def distance_matrix_url(self, origins: List[LngLat], destinations: List[LngLat], arrival_time: datetime, accuracy: Accuracy) -> str:
        epoch = datetime(1970, 1, 1)
        arguments = OrderedDict[str, str | int](
            origins = "|".join(map(lng_lat_to_url_arg, origins)),
            destinations = "|".join(map(lng_lat_to_url_arg, destinations)),
            traffic_model = "pessimistic",
            arrival_time = int((arrival_time - epoch).total_seconds()),
            key = self.distance_matrix_api_keys[accuracy],
        )
        return self.get_domain(accuracy) + "/maps/api/distancematrix/json?" + urlencode(arguments)

    def distance_matrix(self, origins: List[LngLat], destinations: List[LngLat], arrival_time: datetime, accuracy: Accuracy) -> DataFrame:
        url = self.distance_matrix_url(origins, destinations, arrival_time, accuracy)
        response = requests.get(url)
        content = json.loads(response.content.decode("utf-8"))
        if content["status"] != "OK":
            raise DistanceMatrixException(content["status"])
        status: List[str] = []
        origin: List[LngLat] = []
        destination: List[LngLat] = []
        distance_mi: List[float] = []
        duration_min: List[float] = []
        for row in content["rows"]:
            for element in row["elements"]:
                status.append(element["status"])
                origin.append(parse_lat_lng(element["origin"]))
                destination.append(parse_lat_lng(element["destination"]))
                distance_mi.append(element["distance"]["value"] / 1609.334 if element["status"] == "OK" else np.nan)
                duration_min.append(element["duration_in_traffic"]["value"] / 60 * 16 / 14 if element["status"] == "OK" else np.nan)
        data = DataFrame({
            "status": status,
            "origin": origin,
            "destination": destination,
            "distance_mi": distance_mi,
            "duration_min": duration_min,
        })
        data["speed_mph"] = data["distance_mi"] / data["duration_min"] * 60
        return data

    def distance_matrix_chunked(self, origins: List[LngLat], destinations: List[LngLat], arrival_time: datetime, accuracy: Accuracy) -> DataFrame:
        results: List[DataFrame] = []
        for destination in destinations:
            start = 0
            end = min(self.max_dimensions, len(origins))
            while start < len(origins):
                chunk = origins[start:end]
                matrix = self.distance_matrix(chunk, [destination], arrival_time, accuracy)
                results.append(matrix)
                start += self.max_dimensions
                end = min(end + self.max_dimensions, len(origins))
        return self.get_shortest_trip(pd.concat(results)) # type: ignore

    def geocode_url(self, address: str, accuracy: Accuracy) -> str:
        arguments = OrderedDict[str, str](address = address, key = self.geocode_api_keys[accuracy])
        return self.get_domain(accuracy) + "/maps/api/geocode/json?" + urlencode(arguments)

    def geocode(self, addresses: List[str], accuracy: Accuracy) -> DataFrame:
        coordinates: List[LngLat] = []
        for address in addresses:
            url = self.geocode_url(address, accuracy)
            response = requests.get(url)
            content = json.loads(response.content.decode("utf-8"))
            if content["status"] != "OK":
                raise GeocodingException(content["status"])
            matches = content["result"]
            if len(matches) > 1:
                raise GeocodingException("Too many potential matches")
            location = content["result"][0]["geometry"]["location"]
            coordinates.append((location["lng"], location["lat"]))
        return DataFrame({
            "address": addresses,
            "coordinates": coordinates
        })

    def get_domain(self, accuracy: Accuracy) -> str:
        if accuracy == "fast":
            return self.fast_domain
        if accuracy == "accurate":
            return self.accurate_domain
        raise ValueError("Unsupported accuracy " + accuracy)

    def get_shortest_trip(self, data: DataFrame) -> DataFrame:
        data = data.groupby(["status", "origin", "destination"]) # type: ignore
        data = data.agg(duration_min = ("duration_min", "min")) # type: ignore
        return data.reset_index()

def getEnvOrRaise(name: str) -> str:
    "Look up an environment variable.  If it does not exist, raise an Exception."
    value = getenv(name)
    if value is None:
        raise Exception(f"Required environment variable {name} not set")
    return value

def distance_matrix_caller_from_env() -> DistanceMatrixCaller:
    "Create a new DistanceMatrixCaller from the current environment variables."
    distance_matrix_api_keys: dict[Accuracy, str] = {
        "accurate": getEnvOrRaise("ACCURATE_GEOCODING_API_KEY"),
        "fast": getEnvOrRaise("FAST_GEOCODING_API_KEY"),
    }
    geocode_api_keys: dict[Accuracy, str] = {
        "accurate": getEnvOrRaise("ACCURATE_DISTANCE_MATRIX_API_KEY"),
        "fast": getEnvOrRaise("FAST_DISTANCE_MATRIX_API_KEY"),
    }
    return DistanceMatrixCaller("https://api-v2.distancematrix.ai", "https://api.distancematrix.ai", distance_matrix_api_keys, geocode_api_keys)