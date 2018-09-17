component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="username";
    property name="firstName" column="first_name";
    property name="lastName" column="last_name";
    property name="password";
    property name="countryId" column="country_id";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    this.constraints = {
        "lastName" = {
            "required" = true
        }
    };

    function scopeLatest( query ) {
        return query.orderBy( "created_date", "desc" );
    }

    function posts() {
        return hasMany( "Post", "user_id" );
    }

    function latestPost() {
        return hasOne( "Post", "user_id" ).latest();
    }

}
