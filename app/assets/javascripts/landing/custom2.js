function close_accordion_section() {
        jQuery('.faq-content .faq-section-title').removeClass('active');
        jQuery('.faq-content .faq-section-content').slideUp(500).removeClass('open');
    }

    jQuery('.faq-section-title').click(function(e) {
        // Grab current anchor value
        //var currentAttrValue = jQuery(this).attr('href');
           
        if(jQuery(e.target).is('.active')) {
            close_accordion_section();
        }else {
            close_accordion_section();

            // Add active class to section title
            jQuery(this).addClass('active');
            // Open up the hidden content panel
            jQuery(this).next().slideDown(500).addClass('open');
        }

        e.preventDefault();
    }); 