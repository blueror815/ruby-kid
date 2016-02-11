// Manifest file for compiling needed Javascript for browsing items

//= require wookmark
//= require jquery.tmpl.min
//= require nested_form

var handler = null;
var page = 1;
var isLoading = false;
var morePages = true;
var apiURL = 'http://www.wookmark.com/api/json/popular'

// Prepare layout options.
var options = {
    autoResize: true, // This will auto-update the layout when the browser window is resized.
    container: $('#tiles'), // Optional, used for some extra CSS styling
    offset: 2, // Optional, the distance between grid items
    itemWidth: 210 // Optional, the width of a grid item
};

/**
 * When scrolled all the way to the bottom, add more tiles.
 */
function onScroll(event) {
    // Only check when we're not still waiting for data.
    if(!isLoading && morePages) {
        var closeToBottom = ($(window).scrollTop() > $(document).height() - 1000);
        if(closeToBottom) {
            loadData();
        }
    }
};

/**
 * Refreshes the layout.
 */
function applyLayout() {
    // Clear our previous layout handler.
    if(handler) handler.wookmarkClear();

    // Create a new layout handler.
    handler = $('#tiles li');
    handler.wookmark(options);
};

/**
 * Loads data from the API.
 */
function loadData() {
    isLoading = true;
    $('#loader-circle').show();
    page += 1;
    $.ajax({url: apiURL, data: {page: page}, dataType:'script', complete: onLoadData  })
};

/**
 * Receives data from the API, updates the layout
 */
function onLoadData(data) {
    isLoading = false;
    $('#loader-circle').hide();
    applyLayout();
    setTilesWithWookmark();
}

function setTilesWithWookmark() {
    var docW = $(window).width();
    var offset = ( docW > 620 ) ? 20 : (docW > 440 ? 16 : (docW > 360 ? 12 : 8) );
    var itemWidth = ( docW > 620) ? 280 : (docW > 440 ? 200 : (docW - offset * 2) / 2.2  );
    var options = {
        autoResize: true,
        container: $("#items_container"),
        offset:  offset,
        itemWidth: itemWidth
    };
    $("#tiles li").wookmark(options);
}
