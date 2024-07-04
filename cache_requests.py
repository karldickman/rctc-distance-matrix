from hashlib import md5
from io import TextIOWrapper
import json
from os import path
import requests
from requests import Response

CACHE_DIRECTORY = "request_cache"

def deserialize_response(text: TextIOWrapper) -> Response:
    serialized = json.load(text)
    response = Response()
    response.url = serialized["url"]
    response.status_code = serialized["status_code"]
    response.headers = serialized["headers"]
    response._content = serialized["content"].encode("utf-8")
    return response

def serialize_response(response: Response) -> str:
    return json.dumps({
        "url": response.url,
        "status_code": response.status_code,
        "headers": dict(response.headers),
        "content": response.text,
    })

def get(url: str, *args, **kwargs) -> Response: #type: ignore
    r"""Sends a GET request.

    :param url: URL for the new :class:`Request` object.
    :param params: (optional) Dictionary, list of tuples or bytes to send
        in the query string for the :class:`Request`.
    :param \*\*kwargs: Optional arguments that ``request`` takes.
    :return: :class:`Response <Response>` object
    :rtype: requests.Response
    """
    key = md5(url.encode("utf-8")).hexdigest()
    cache_file_path = path.join(CACHE_DIRECTORY, key)
    try:
        with open(cache_file_path, "r") as cache_file:
            return deserialize_response(cache_file)
    except FileNotFoundError:
        response = requests.get(url, *args, **kwargs) # type: ignore
        if response.ok:
            with open(cache_file_path, "w") as cache_file:
                cache_file.write(serialize_response(response))
        return response