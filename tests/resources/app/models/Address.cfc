component accessors="true" {

    property name="streetOne";
    property name="streetTwo";
    property name="city";
    property name="state";
    property name="zip";

    function fullStreet() {
        var street = [ getStreetOne(), getStreetTwo() ];
        return street.filter( function( part ) {
            return !isNull( part ) && part != "";
        } ).toList( chr( 10 ) );
    }

    function formatted() {
        return fullStreet() & chr( 10 ) & "#getCity()#, #getState()# #getZip()#";
    }

}
