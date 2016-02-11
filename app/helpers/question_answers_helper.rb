module QuestionAnswersHelper


  def answer_to_html(text)
    if (text =~ /^\s*<ul/i )
      text.html_safe
    else
      text.split(/\n[\r]?\n/).collect do|paragraph|
        p_css_class = (paragraph =~ /^\s*<img/i) ? 'faq-tab-img' : 'answer-text'
        content_tag :p, class: p_css_class do
          paragraph.html_safe
        end
      end.join("\n")
    end
  end

end