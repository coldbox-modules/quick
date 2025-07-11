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
    property name="sentimentAnalysis" casts="JsonCast@quick";

    variables._discriminators = [
        "InternalComment",
        "PictureComment"
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

    // chose this sql function as it present in both mysql and sql server
    function scopeAddUpperBody( qb ) {
        qb.selectRaw( "UPPER(body) as upperBody" );
        appendVirtualAttribute( "upperBody" );
    }

}
