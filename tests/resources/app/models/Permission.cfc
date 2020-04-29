component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function roles() {
        return belongsToMany( "Role" );
    }

}
