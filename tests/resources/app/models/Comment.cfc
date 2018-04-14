component extends="quick.models.BaseEntity" {

    property name="id";
    property name="body";
    property name="commentableId" column="commentable_id";
    property name="commentableType" column="commentable_type";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function commentable() {
        return polymorphicBelongsTo( "commentable" );
    }

}
