$( "#redhat_id" ).blur( function() {
    $.ajax({
        method: "POST",
        url: "/",
        data: { "redhat_id": $( this ).val(),
                "fragment": true },
        success: function( result ) {
            $( "div#form-trello-section" ).replaceWith( result ); } } ); } );

$( "#github_id" ).blur( function() {
    $.ajax({
        method: "POST",
        url: "/",
        data: { "github_id": $( this ).val(),
                "fragment": true },
        success: function( result ) {
            $( "div#form-github-section" ).replaceWith( result ); } } ); } );
