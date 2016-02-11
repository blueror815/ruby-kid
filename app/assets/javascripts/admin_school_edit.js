$('#schools-table-edit').click(function(){
    var id = $(this).data('id');
    
        alert("Hello! I am an alert box!!");
    $("#school_name").submit( function(eventObj) {
        $('<input />').attr('type', 'hidden')
        .attr('name', "something")
        .attr('value', "something")
        .appendTo(this);
        return true;
    });
});
