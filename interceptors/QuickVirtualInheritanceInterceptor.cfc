component {

    function afterInstanceInspection( interceptData ) {
        if ( interceptData.mapping.getObjectMetadata().keyExists( "quick" ) ) {
            interceptData.mapping.setVirtualInheritance( "quick.models.BaseEntity" );
        }
    }

}
