component extends="quick.models.BaseEntity" {

    function commentable() {
        return polymorphicBelongsTo( "commentable" );
    }

}