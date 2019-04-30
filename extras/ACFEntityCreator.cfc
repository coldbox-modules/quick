component {

    function new( entity ) {
        return entity.get_wirebox().getInstance(
            name = entity.get_fullName(),
            initArguments = { meta = entity.get_meta() }
        );
    }

}
