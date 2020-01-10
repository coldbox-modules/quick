/**
 * Interceptor for performing virtual inheritance on components with the
 * `quick` metadata key.
 */
component {

    /**
     * Set virtual inheritence after the instance inspection for components
     * with the `quick` metadata key.
     *
     * @interceptData  The struct of intercept data for the
     *                 afterInstanceInspection interception point.
     *
     * @return         void
     */
    public void function afterInstanceInspection( required struct interceptData ) {
        if ( interceptData.mapping.getObjectMetadata().keyExists( "quick" ) ) {
            interceptData.mapping.setVirtualInheritance( "quick.models.BaseEntity" );
        }
    }

}
