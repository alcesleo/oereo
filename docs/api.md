# API

## Try it out

I strongly recommend [Postman](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm?hl=en)
to play with the API. It supports sending all the needed headers and presents a
simple interface with nicely formatted responses.

## Formats

The API supports both **JSON** and **XML**, however JSON is the standard format
and is recommended. To get the same result in XML simply append `.xml` to the
url.

## Authorization

The API requires _both **token** and **http basic** authorization_.

Authorizing with HTTP basic as a user is requested when needed, the
application access token should be sent as a `X-AUTH-TOKEN` header.
