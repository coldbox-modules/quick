component table="teams" extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";
    property name="companyId";

    function users() {
        return hasMany( "User", "team_id" );
    }

    function company() {
        return belongsTo( "Company" );
    }

}
