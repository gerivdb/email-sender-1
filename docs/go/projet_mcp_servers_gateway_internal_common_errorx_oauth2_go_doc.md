# Package errorx

## Types

### OAuth2Error

#### Methods

##### OAuth2Error.Error

```go
func (e *OAuth2Error) Error() string
```

## Variables

### ErrInvalidRequest, ErrInvalidClient, ErrInvalidGrant, ErrUnauthorizedClient, ErrUnsupportedGrantType, ErrInvalidScope, ErrInvalidRedirectURI, ErrClientAlreadyExists, ErrAuthorizationCodeExpired, ErrAuthorizationCodeNotFound, ErrTokenExpired, ErrTokenNotFound, ErrOAuth2NotEnabled

```go
var (
	ErrInvalidRequest	= &OAuth2Error{
		ErrorType:	"invalid_request",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrInvalidClient	= &OAuth2Error{
		ErrorType:	"invalid_client",
		HTTPStatus:	http.StatusUnauthorized,
	}

	ErrInvalidGrant	= &OAuth2Error{
		ErrorType:	"invalid_grant",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrUnauthorizedClient	= &OAuth2Error{
		ErrorType:	"unauthorized_client",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrUnsupportedGrantType	= &OAuth2Error{
		ErrorType:	"unsupported_grant_type",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrInvalidScope	= &OAuth2Error{
		ErrorType:	"invalid_scope",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrInvalidRedirectURI	= &OAuth2Error{
		ErrorType:	"invalid_request",
		ErrorCode:	"invalid_redirect_uri",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrClientAlreadyExists	= &OAuth2Error{
		ErrorType:	"invalid_request",
		ErrorCode:	"client_already_exists",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrAuthorizationCodeExpired	= &OAuth2Error{
		ErrorType:	"invalid_grant",
		ErrorCode:	"code_expired",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrAuthorizationCodeNotFound	= &OAuth2Error{
		ErrorType:	"invalid_grant",
		ErrorCode:	"invalid_code",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrTokenExpired	= &OAuth2Error{
		ErrorType:	"invalid_token",
		ErrorCode:	"token_expired",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrTokenNotFound	= &OAuth2Error{
		ErrorType:	"invalid_token",
		ErrorCode:	"invalid_token",
		HTTPStatus:	http.StatusBadRequest,
	}

	ErrOAuth2NotEnabled	= &OAuth2Error{
		ErrorType:	"invalid_request",
		ErrorCode:	"oauth2_not_enabled",
		HTTPStatus:	http.StatusBadRequest,
	}
)
```

