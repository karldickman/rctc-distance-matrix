from collections import OrderedDict
from datetime import datetime
import json
from typing import List, Literal, Tuple
from urllib.parse import urlencode

from pandas import DataFrame
import numpy as np

import cache_requests as requests

class DistanceMatrixException(Exception):
    ...

class GeocodingException(Exception):
    ...

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

    accurate: str
    "The domain to call for accurate results."

    api_key: str
    "The API key used to authenticate calls"

    fast: str
    "The domain to call for fast results."

    def __init__(self, fast_domain: str, accurate_domain: str, api_key: str):
        self.fast = fast_domain
        self.accurate = accurate_domain
        self.api_key = api_key

    def distance_matrix_url(self, origins: List[LngLat], destinations: List[LngLat], arrival_time: datetime, accuracy: Literal["fast"] | Literal["accurate"]) -> str:
        epoch = datetime(1970, 1, 1)
        arguments = OrderedDict[str, str | int](
            origins = "|".join(map(lng_lat_to_url_arg, origins)),
            destinations = "|".join(map(lng_lat_to_url_arg, destinations)),
            traffic_model = "pessimistic",
            arrival_time = int((arrival_time - epoch).total_seconds()),
            key = self.api_key,
        )
        return self.get_domain(accuracy) + "/maps/api/distancematrix/json?" + urlencode(arguments)

    def distance_matrix(self, origins: List[LngLat], destinations: List[LngLat], arrival_time: datetime, accuracy: Literal["fast"] | Literal["accurate"]) -> DataFrame:
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
                duration_min.append(element["duration_in_traffic"]["value"] / 60 if element["status"] == "OK" else np.nan)
        return DataFrame({
            "status": status,
            "origin": origin,
            "destination": destination,
            "distance_mi": distance_mi,
            "duration_min": duration_min,
        })

    def geocode_url(self, address: str, accuracy: Literal["fast"] | Literal["accurate"]) -> str:
        arguments = OrderedDict[str, str](address = address, key = self.api_key)
        return self.get_domain(accuracy) + "/maps/api/geocode/json?" + urlencode(arguments)

    def geocode(self, addresses: List[str], accuracy: Literal["fast"] | Literal["accurate"]) -> DataFrame:
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

    def get_domain(self, accuracy: Literal["fast"] | Literal["accurate"]) -> str:
        if accuracy == "fast":
            return self.fast
        if accuracy == "accurate":
            return self.accurate
        raise ValueError("Unsupported accuracy " + accuracy)
