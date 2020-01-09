/**
 * Entity Creator for Adobe engines.
 * Entity creators are separated by engines since
 * Adobe throws a compilation error for Lucee's syntax.
 */
component {

    /**
     * Create a new instance of an entity for a given entity.
     *
     * @entity   The entity to create a new instance.
     *
     * @returns  A Quick instance.
     */
    public any function new( required any entity ) {
        return arguments.entity.get_wirebox().getInstance(
            name = arguments.entity.get_fullName(),
            initArguments = { meta = arguments.entity.get_meta() }
        );
    }

}
