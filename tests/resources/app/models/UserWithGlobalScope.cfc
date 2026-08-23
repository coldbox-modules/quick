component extends="User" table="users"  accessors="true" {

    function scopeWithCountryName( qb ) {
        qb.addSubselect( "countryName", "country.name" );
    }

    function scopeWithTeamName( qb ) {
        qb.addSubselect( "teamName", "team.name" );
    }        

    function scopeWithBoundCountryName( qb ) {
        qb.addSubselect( "boundCountryName", function( q ) {
            q.select( "name" )
                .from( "countries" )
                .whereColumn( "countries.id", "users.country_id" )
                .where( "countries.id", "02B84D66-0AA0-F7FB-1F71AFC954843861" );
        } );
    }

    function applyGlobalScopes( qb ) {
        qb.withCountryName();
        qb.withTeamName();
        qb.withBoundCountryName();
    }
}
