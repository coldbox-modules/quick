component implements="quick.models.Casts.CastsAttribute" {

    property name="wirebox" inject="wirebox";

    /**
     * Casts the given value from the database to the target cast type.
     *
     * @entity      The entity with the attribute being casted.
     * @key         The attribute alias name.
     * @value       The value of the attribute.
     * @attributes  The struct of attributes for the entity.
     *
     * @return      The casted attribute.
     */
    public any function get(
        required any entity,
        required string key,
        any value
    ) {
        return wirebox.getInstance( dsl = "Address" )
            .setStreetOne( entity.retrieveAttribute( "streetOne" ) )
            .setStreetTwo( entity.retrieveAttribute( "streetTwo" ) )
            .setCity( entity.retrieveAttribute( "city" ) )
            .setState( entity.retrieveAttribute( "state" ) )
            .setZip( entity.retrieveAttribute( "zip" ) );
    }

    /**
     * Returns the value to assign to the key before saving to the database.
     *
     * @entity      The entity with the attribute being casted.
     * @key         The attribute alias name.
     * @value       The value of the attribute.
     * @attributes  The struct of attributes for the entity.
     *
     * @return      The value to save to the database. A struct of values
     *              can be returned if the cast value affects multiple attributes.
     */
    public any function set(
        required any entity,
        required string key,
        any value
    ) {
        return {
            "streetOne": arguments.value.getStreetOne(),
            "streetTwo": arguments.value.getStreetTwo(),
            "city": arguments.value.getCity(),
            "state": arguments.value.getState(),
            "zip": arguments.value.getZip()
        };
    }

}
