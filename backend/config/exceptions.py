from rest_framework.views import exception_handler


def _first_error_message(value):
    if isinstance(value, str):
        text = value.strip()
        return text or None

    if isinstance(value, list):
        for item in value:
            found = _first_error_message(item)
            if found:
                return found
        return None

    if isinstance(value, dict):
        for item in value.values():
            found = _first_error_message(item)
            if found:
                return found
        return None

    return None


def tutta_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return response

    if isinstance(response.data, dict):
        detail = response.data.get('detail')
        if detail is None:
            detail = _first_error_message(response.data) or 'Validation error.'
        response.data = {
            'success': False,
            'message': str(detail),
            'errors': response.data,
        }
    else:
        response.data = {
            'success': False,
            'message': 'Request failed.',
            'errors': response.data,
        }

    return response
