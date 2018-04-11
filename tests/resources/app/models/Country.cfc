component extends="quick.models.BaseEntity" {

    property name="keyType" inject="UUID@quick" persistent="false";

    function posts() {
        return hasManyThrough( "Post", "User" );
    }

}
