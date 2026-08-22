component singleton {

	public any function get(
		required any entity,
		required string key,
		any value
	) {
		return arguments.value == "Y";
	}

	public any function set(
		required any entity,
		required string key,
		any value
	) {
		return arguments.value ? "Y" : "N";
	}

}
