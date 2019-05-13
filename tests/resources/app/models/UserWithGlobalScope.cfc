component extends="User" mappedSuperClass="true" table="users" quick {

    function scopeHasCountry( query ) {
        return query.whereNotNull( "countryName" );
    }

    function scopeWithCountryName( query ) {
        addSubselect( "countryName", newEntity( "Country")
            .select( "name" )
            .whereColumn( "users.country_id", "countries.id" )
        );
    }

    function applyGlobalScopes() {
        this.HasCountry();
        this.withCountryName();
    }
}
