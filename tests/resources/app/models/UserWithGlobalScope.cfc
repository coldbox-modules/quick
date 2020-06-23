component extends="User" table="users"  accessors="true" {

    function scopeWithCountryName( query ) {
        addSubselect( "countryName", "country.name" );
    }

    function applyGlobalScopes() {
        this.withCountryName();
    }
}
