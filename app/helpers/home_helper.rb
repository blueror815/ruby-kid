module HomeHelper

  HOW_IT_WORKS_VIDEO_ID_FOR_KID = 'VzNLpR7pbyk'
  HOW_IT_WORKS_VIDEO_URL_FOR_KID = 'https://www.youtube.com/embed/' + HOW_IT_WORKS_VIDEO_ID_FOR_KID + '?modestbranding=0&rel=0&showinfo=0'
  HOW_IT_WORKS_VIDEO_URL_FOR_KID_DIRECT = 'https://www.youtube.com/watch?v=' + HOW_IT_WORKS_VIDEO_ID_FOR_KID
  HOW_IT_WORKS_VIDEO_URL_FOR_PARENT = 'https://www.youtube-nocookie.com/embed/VLobm5PU22w?rel=0&showinfo=0'

  def how_it_works_video_iframe_for_kid
    content_tag(:iframe, { width:560, height:315, src: HOW_IT_WORKS_VIDEO_URL_FOR_KID,
      frameborder:0, 'allowfullscreen'=> true} ) { }
  end

  def how_it_works_video_iframe_for_parent
    content_tag(:iframe, { width:560, height:315, src: HOW_IT_WORKS_VIDEO_URL_FOR_PARENT,
                           frameborder:0, 'allowfullscreen'=> true} ) { }
  end
end