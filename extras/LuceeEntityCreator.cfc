/**
 * Entity Creator for Lucee engines.
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
        // Lucee allows a shallow copy which does not copy the object graph.
        // This is perfect for our use cases and cuts loading time down immensely!
        var newEntity = duplicate( arguments.entity, false );
        newEntity.reset();
        return newEntity;
    }

}
