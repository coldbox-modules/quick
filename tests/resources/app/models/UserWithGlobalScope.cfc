component extends="User" table="users" quick {

    function scopeWithCountryName( query ) {
        addSubselect( "countryName", newEntity( "Country")
            .select( "name" )
            .whereColumn( "users.country_id", "countries.id" )
        );
    }

    function applyGlobalScopes() {
        this.withCountryName();
    }
}
