from rest_framework.views import exception_handler


def tutta_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return response

    if isinstance(response.data, dict):
        detail = response.data.get('detail')
        if detail is None:
            detail = 'Validation error.'
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
