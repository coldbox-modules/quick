component extends="User" table="users"  accessors="true" {

    function scopeWithCountryName( qb ) {
        qb.addSubselect( "countryName", "country.name" );
    }

    function applyGlobalScopes( qb ) {
        qb.withCountryName();
    }
}
