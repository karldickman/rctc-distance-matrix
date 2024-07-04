from collections import OrderedDict
import json
from typing import Literal, Tuple
from urllib.parse import urlencode

import cache_requests as requests

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

    def distance_matrix(self, origin: Tuple[float, float], destination: Tuple[float, float], accuracy: Literal["fast"] | Literal["accurate"]):
        arguments = OrderedDict[str, str](
            origins = ",".join(map(str, reversed(origin))),
            destinations = ",".join(map(str, reversed(destination))),
            key = self.api_key,
        )
        url = self.get_domain(accuracy) + "/maps/api/distancematrix/json?" + urlencode(arguments)
        response = requests.get(url)
        return json.loads(response.content.decode("utf-8"))

    def geocode(self, address: str, accuracy: Literal["fast"] | Literal["accurate"]):
        arguments = OrderedDict[str, str](address = address, key = self.api_key)
        url = self.get_domain(accuracy) + "/maps/api/geocode/json?" + urlencode(arguments)
        response = requests.get(url)
        return json.loads(response.content.decode("utf-8"))

    def get_domain(self, accuracy: Literal["fast"] | Literal["accurate"]) -> str:
        if accuracy == "fast":
            return self.fast
        if accuracy == "accurate":
            return self.accurate
        raise ValueError("Unsupported accuracy " + accuracy)
