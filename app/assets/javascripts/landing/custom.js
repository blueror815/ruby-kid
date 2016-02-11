// System Supplies Grid
$(document).ready(function(){

      
	$(".vedio-section a").click(function(){
		$('.overlay1').fadeIn();
		$(".vidio_container").animate({'top':'10%'});			
	});
	$(".overlay1 .close_popup").click(function(){
		$(".vidio_container").animate({'top':'-300%'},function(){
			$('.overlay1').fadeOut();
		});			
	});

	$('.kids-post').each(function(){
		var img_height = $(this).find('.img').height();
		$(this).find('.textarea').css({'height':img_height});
	});
	/* equalHeight(); */
});
$(window).load(function(){
	$('.kids-post').each(function(){
		var img_height = $(this).find('.img').height();
		$(this).find('.textarea').css({'height':img_height});
	});
});
$(window).resize(function(){
	$('.kids-post').each(function(){
		var img_height = $(this).find('.img').height();
		$(this).find('.textarea').css({'height':img_height});
	});
});


// backgroundSize
$(function() {
     
     $(".ie8 .parents-approve").css({backgroundSize: "cover"});
     $(".ie8 .kids-exchange").css({backgroundSize: "cover"});
     $(".ie8 .earn-buck").css({backgroundSize: "cover"});

});

// Border Radius
$(function() {
    if (window.PIE) {
        $('.contact-form .button .contact-form .input').each(function() {
            PIE.attach(this);
        });
    }
});

// Mac CSS
(function($){
    // console.log(navigator.userAgent);
    /* Adjustments for Safari on Mac */
    if (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Mac') != -1 && navigator.userAgent.indexOf('Chrome') == -1) {
        // console.log('Safari on Mac detected, applying class...');
        $('html').addClass('safari-mac'); // provide a class for the safari-mac specific css to filter with
    }
})(jQuery);
	
	









