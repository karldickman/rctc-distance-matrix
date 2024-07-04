from collections import OrderedDict
import json
from typing import List, Literal, Tuple
from urllib.parse import urlencode

import cache_requests as requests

class GeocodingException(Exception):
    ...

type LngLat = Tuple[float, float]

def lng_lat_to_url_arg(coordinates: LngLat) -> str:
    return ",".join(map(str, reversed(coordinates)))

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

    def distance_matrix(self, origins: List[LngLat], destinations: List[LngLat], accuracy: Literal["fast"] | Literal["accurate"]):
        arguments = OrderedDict[str, str](
            origins = "|".join(map(lng_lat_to_url_arg, origins)),
            destinations = "|".join(map(lng_lat_to_url_arg, destinations)),
            key = self.api_key,
        )
        url = self.get_domain(accuracy) + "/maps/api/distancematrix/json?" + urlencode(arguments)
        response = requests.get(url)
        return json.loads(response.content.decode("utf-8"))

    def geocode(self, address: str, accuracy: Literal["fast"] | Literal["accurate"]) -> LngLat:
        arguments = OrderedDict[str, str](address = address, key = self.api_key)
        url = self.get_domain(accuracy) + "/maps/api/geocode/json?" + urlencode(arguments)
        response = requests.get(url)
        content = json.loads(response.content.decode("utf-8"))
        if content["status"] != "OK":
            raise GeocodingException(content["status"])
        matches = content["result"]
        if len(matches) > 1:
            raise GeocodingException("Too many potential matches")
        location = content["result"][0]["geometry"]["location"]
        return location["lng"], location["lat"]

    def get_domain(self, accuracy: Literal["fast"] | Literal["accurate"]) -> str:
        if accuracy == "fast":
            return self.fast
        if accuracy == "accurate":
            return self.accurate
        raise ValueError("Unsupported accuracy " + accuracy)
