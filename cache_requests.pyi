from requests import Response
from requests.api import _HeadersMapping # type: ignore
from requests.sessions import RequestsCookieJar, _Auth, _Cert, _Data, _Files, _HooksInput, _Params, _TextMapping, _Timeout, _Verify # type: ignore
from _typeshed import Incomplete

def get(
    url: str | bytes,
    params: _Params | None = None,
    *,
    data: _Data | None = ...,
    headers: _HeadersMapping | None = ...,
    cookies: RequestsCookieJar | _TextMapping | None = ...,
    files: _Files | None = ...,
    auth: _Auth | None = ...,
    timeout: _Timeout | None = ...,
    allow_redirects: bool = ...,
    proxies: _TextMapping | None = ...,
    hooks: _HooksInput | None = ...,
    stream: bool | None = ...,
    verify: _Verify | None = ...,
    cert: _Cert | None = ...,
    json: Incomplete | None = ...,
) -> Response: ...
