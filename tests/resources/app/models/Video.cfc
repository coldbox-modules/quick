component extends="quick.models.BaseEntity" {

    function comments() {
        return polymorphicHasMany( "Comment", "commentable" );
    }

}