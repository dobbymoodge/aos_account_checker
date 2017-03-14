//////{ // Attempt 2
// function bindEvents() {
// $( "#redhat_id" ).blur( function() {
//     $.ajax({
//         method: "POST",
//         url: "/",
//         data: { "redhat_id": $( this ).val(),
//                 "fragment": true },
//         success: function( result ) {
//             $( "div#form-trello-section" ).replaceWith( result );
//         } } ); } );

// $( "#github_id" ).blur( function() {
//     $.ajax({
//         method: "POST",
//         url: "/",
//         data: { "github_id": $( this ).val(),
//                 "fragment": true },
//         success: function( result ) {
//             $( "div#form-github-section" ).replaceWith( result );
//         } } ); } );
// }

// bindEvents();
// $( document ).ajaxComplete( bindEvents() );
//////} // Attempt 2

//////{ // Attempt 1
// var ghajaxfn = function() {
//     $.ajax({
//         method: "POST",
//         url: "/",
//         data: { "github_id": $( this ).val(),
//                 "fragment": true },
//         success: function( result ) {
//             $( "div#form-github-section" ).replaceWith( result );
//             $( "#github_id" ).blur( ghajaxfn );
//             // print(result);
//         } } ); };


// $( "#github_id" ).blur( ghajaxfn );

// ghajaxfn.done( function() { $( "#github_id" ).blur( ghajaxfn() ); } );
//////} // Attempt 2

// Websockets - nodejs socketio

//////{ // Attempt 3
function testajax() {
    $.ajax(
        {
            dataType: "json",
            method: "POST",
            url: "/testjson",
            data: {
                "status": "fail" },
            success: gh_update(result),
            // function (result) {
            //     $( "#first_div" ).after( result['reasons'][0] );
            // }
        }
    );
}

function add_error(elem, reasons) {
    if ( ! elem.hasClass('has-error') ) {
        elem.addClass('has-error');
    }
    inner_div = $( "div", elem );
    msg = `<p class="help-block">One or more errors occurred:
  <ul>
    <li>` + reasons.join(`</li>
    <li>`) + `
    </li>
  </ul>
</p>`;
    inner_div.html(msg);
}

// function add_error(elem, reasons) {
//     if ( ! elem.hasClass('has-error') ) {
//         elem.addClass('has-error');
//     }
//     inner_div = $( "div", elem );
//     msg = `<p class="help-block">One or more errors occurred:
//   <ul>
//     <li>` + reasons.join(`</li>
//     <li>`) + `
//     </li>
//   </ul>
// </p>`;
//     help_block = $( "p.help-block", inner_div )
//     if ( help_block.length > 0 ) {
//         help_block.replaceWith(msg);
//     } else {
//         inner_div.append(msg);
//     }
// }

function gh_update(result) {
    var gh_div = $( "div#form-github-section" )
    if ( result['status'] == 'fail' ) {
        add_error(gh_div, result['reasons']);
    }
}
//////} // Attempt 3
