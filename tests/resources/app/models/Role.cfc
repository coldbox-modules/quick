component extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";

    function permissions() {
        return belongsToMany( "Permission" );
    }

    function users() {
        return belongsToMany( "User" );
    }

}
