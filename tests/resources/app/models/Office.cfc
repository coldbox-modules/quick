component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function teams() {
        return hasMany( "Team" );
    }

    function users() {
        return hasManyThrough( [ "teams", "users" ] );
    }

}
