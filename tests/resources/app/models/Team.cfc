component table="teams" extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";
    property name="officeId";

    function users() {
        return hasMany( "User", "team_id" );
    }

    function office() {
        return belongsTo( "Office" );
    }

}
