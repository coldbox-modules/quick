component singleton {

	public any function get(
		required any entity,
		required string key,
		any value
	) {
		return isNull( arguments.value ) || arguments.entity.isNullValue( arguments.key, arguments.value )
		 ? "casted-null"
		 : arguments.value;
	}

	public any function set(
		required any entity,
		required string key,
		any value
	) {
		return isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value;
	}

}
