component extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";

    function roles() {
        return belongsToMany( "Role" );
    }

}
