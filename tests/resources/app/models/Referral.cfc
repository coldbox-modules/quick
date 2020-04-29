component extends="quick.models.BaseEntity" readonly="true" accessors="true" {

    property name="id";
    property name="type";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function setType( type ) {
        return assignAttribute( "type", ucase( arguments.type ) );
    }

}
