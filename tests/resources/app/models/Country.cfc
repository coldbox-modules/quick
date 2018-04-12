component extends="quick.models.BaseEntity" {

    property name="keyType" inject="UUID@quick" persistent="false";

    variables.relationships = {
        "posts" = function() {
            return hasManyThrough( "Post", "User" );
        }
    };

}
