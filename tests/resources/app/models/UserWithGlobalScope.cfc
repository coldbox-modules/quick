component extends="User" table="users"  accessors="true" {

    function scopeWithCountryName( qb ) {
        qb.addSubselect( "countryName", "country.name" );
    }

    function scopeWithTeamName( qb ) {
        qb.addSubselect( "teamName", "team.name" );
    }

    function applyGlobalScopes( qb ) {
        qb.withCountryName();
        qb.withTeamName();
    }
}
