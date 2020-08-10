component 
    extends="quick.models.BaseEntity"
    discriminatorColumn="designation" 
    accessors="true" 
{

    property name="id";
    property name="body";
    property name="commentableId" column="commentable_id";
    property name="commentableType" column="commentable_type";
    property name="userId" column="user_id";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    variables._discriminators = [
        "InternalComment"
    ];

    function commentable() {
        return polymorphicBelongsTo( "commentable" );
    }

    function author() {
        return belongsTo( "User", "user_id" );
    }

    function tags() {
        return hasManyThrough( [ "commentable", "tags" ] );
    }

}
