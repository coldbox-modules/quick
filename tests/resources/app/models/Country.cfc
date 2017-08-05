component extends="quick.models.BaseEntity" {

    function posts() {
        return hasManyThrough( "Post", "User" );
    }

}