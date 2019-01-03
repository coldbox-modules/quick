component {

    function new( entity ) {
        // Lucee allows a shallow copy which does not copy the object graph.
        // This is perfect for our use cases and cuts loading time down immensely!
        var newEntity = duplicate( entity, false );
        newEntity.reset();
        return newEntity;
    }

}
