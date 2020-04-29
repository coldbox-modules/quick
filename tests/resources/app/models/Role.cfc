component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function permissions() {
        return belongsToMany( "Permission" );
    }

    function users() {
        return belongsToMany( "User" );
    }

}
