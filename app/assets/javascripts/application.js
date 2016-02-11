// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery.min
//= require bootstrap.min
//= require browser_timezone_rails/application.js
//= require jquery-ui.min
//= require ./landing/html5shiv.js
//= require ./landing/jquery.ajaxchimp.min.js
//= require ./landing/jquery.fitvids.js
//= require ./landing/jquery.localScroll.min.js
//= require ./landing/jquery.nav.js
//= require ./landing/jquery.scrollTo.min.js
//= require ./landing/jquery.stellar.min.js
//= require ./landing/matchMedia.js
//= require ./landing/nivo-lightbox.min.js
//= require ./landing/owl.carousel.min.js
//= require ./landing/respond.min.js
//= require ./landing/retina.min.js
//= require ./landing/simple-expand.min.js
//= require ./landing/smoothscroll.js
//= require ./landing/wow.min.js
//= require ./landing/custom.js
//  require_tree .

$(function () {
  ////////////////////////////
  // Menu
  /*
  var menu = $('#nav-menu'),
  pos = menu.offset();

  $(window).scroll(function () {
    if ($(this).scrollTop() > pos.top + menu.height() && menu.hasClass('default-menu')) {
      menu.fadeOut('fast', function () {
        $(this).removeClass('default-menu').addClass('fixed-menu').fadeIn('fast');
      });
    } else if ($(this).scrollTop() <= pos.top && menu.hasClass('fixed-menu')) {
      menu.fadeOut('fast', function () {
        $(this).removeClass('fixed-menu').addClass('default-menu').fadeIn('fast');
      });
    }
  });
  */

  ///////////////////////////////////
  // Calendar
  //$("#user_birthdate").datepicker();
  //if ( $("#child_birthdate") ) { $("#child_birthdate").datepicker(); }
});

$.fn.positionOn = function(element, align) {
    return this.each(function() {
    var target   = $(this);
    var position = element.position();
    
    var x      = position.left; 
    var y      = position.top;
    
    if(align == 'right') {
      x -= (target.outerWidth() - element.outerWidth());
    } else if(align == 'center') {
      x -= target.outerWidth() / 2 - element.outerWidth() / 2;
    }
    
    target.css({
      position: 'absolute',
      zIndex:   5000,
      top:      y, 
      left:     x
    });
  });
};

//////////////////////////
// Form

function setButtonWithChangingStatus(button)
{
    button.attr("disabled", false);
    var form = button.parents("form");
    if (button.attr("submitting-label")) {
        button.bind("click", function() {
            $(this).attr("disabled", true);
            $(this).val( $(this).attr("submitting-label") );
        })
    }
    form.bind("submit", function() {
        if ($(this).attr("submitted-label")) {
            $(this).val( $(this).attr("submitted-label"));
        }
    });
}
