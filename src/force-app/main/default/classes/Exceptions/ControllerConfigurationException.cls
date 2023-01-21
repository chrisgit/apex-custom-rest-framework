public with sharing class ControllerConfigurationException extends CustomRestException {
    private static final Integer HTTP_STATUS_CODE = 422;

    public virtual override Integer getHttpStatusCode() {
        return HTTP_STATUS_CODE;
    }

    public virtual override ErrorCategory getErrorCategory() {
        return CustomRestException.ErrorCategory.INTERNAL_API_ERROR;
    }

    public static ControllerConfigurationException raise(String message) {
        return (ControllerConfigurationException)(new ControllerConfigurationException(message));
    }
}
