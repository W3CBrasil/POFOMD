$(function() {
	var cache = {};

	$( "#busca" ).typeahead({
		minLength: 2,
		source: function( query, response ) {
			if ( query in cache ) {
				response( cache[ query ] );
				return;
			}

			$.getJSON( "/credores/sugestao?q="+query, function( data, status, xhr ) {
				cache[ query ] = data.nomes;
				response( data.nomes );
			});
		}
	});
});
