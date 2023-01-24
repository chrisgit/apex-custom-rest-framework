public inherited sharing class RestDispatcher {
    private static final string PATH_SEPARATOR = '/';
    private static final string PARAMETER_DELIMETERS = '{}';

    Map<String, System.Type> routeControllers = new Map<String, System.Type>();

    public RestDispatcher register(String route, System.Type clazz) {
        System.debug(LoggingLevel.DEBUG, string.format('RestDispatcher: register route [{0}] against controller [{1}]', new object[] { route, clazz }));
        routeControllers.put(route, clazz);
        return this;
    }

    public RestResponseWrapper execute(RestRequestWrapper request, RestResponseWrapper response) {
        System.debug(LoggingLevel.DEBUG, string.format('Attempting to dispatch [{0}] [{1}]', new Object[] { request.RequestType, request.requestURI}));
        for (String route : routeControllers.keySet()) {
            System.debug(LoggingLevel.DEBUG, string.format('Attempting to match route with registered route [{0}]', new String[] { route }));
            if (matchRoute(request, route)) {
                System.Type controllerType = routeControllers.get(route);
                System.debug(LoggingLevel.DEBUG, string.format('Matched route with controller [{0}]', new Object[] { controllerType }));
                
                if (BaseController.class.isAssignableFrom(controllerType) == true) {
                    String controllerProperties = createControllerProperties(request, response);
                    Object controller = JSON.deserialize(controllerProperties, controllerType);
                    return ((BaseController)controller).execute();    
                }

                String controllerConfigurationMessage = string.format('Controllers should be inherited from BaseController [{0}]', new Object[] { controllerType });
                return response.CustomRestException(ControllerConfigurationException.raise(controllerConfigurationMessage));
            }
        }
        System.debug(LoggingLevel.DEBUG, 'No matching controller found for the request path, returning 404');
        return response.NotFound();
    }

    private String createControllerProperties(RestRequestWrapper request, RestResponseWrapper response) {
        Map<String, Object> controllerProperties = new Map<String, Object>();
        for (String key : request.pathParameters.keySet()) {
            controllerProperties.put(key, request.pathParameters.get(key));
        }
        controllerProperties.put('Request', request);
        controllerProperties.put('Response', response);
        return JSON.serialize(controllerProperties);
    }

    private Boolean matchRoute(RestRequestWrapper request, String controllerRoute) {
        List<String> requestUriElements = request.requestUri.split(PATH_SEPARATOR);
        List<String> controllerRouteElements = controllerRoute.split(PATH_SEPARATOR);
        if (requestUriElements.size() != controllerRouteElements.size()) {
            return false;            
        }
        Map<string, string> pathParameters = new Map<string, string>();
        for (Integer i = 0; i < controllerRouteElements.size(); i++) {
            if (pathElementIsVariable(controllerRouteElements.get(i))) {
                pathParameters.put(stripVariableDelimeters(controllerRouteElements.get(i)), requestUriElements.get(i));
            } else if (controllerRouteElements.get(i) != requestUriElements.get(i)) {
                return false;
            }
        }

        request.pathParameters = pathParameters;
        return true;
    }

    private Boolean pathElementIsVariable(string pathElement) {
        return pathElement.startsWith('{') && pathElement.endsWith('}');
    }

    private string stripVariableDelimeters(string pathElement) {
        return pathElement.mid(1, pathElement.length() - 2); // .removeStart('{') then .removeEnd('}')
    }
}
