component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="url";
    property name="title";
    property name="description";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function comments() {
        return polymorphicHasMany( "Comment", "commentable" );
    }

}
