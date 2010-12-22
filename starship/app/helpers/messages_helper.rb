module MessagesHelper

  def fuzzy_time_string(time, keep)
    diff = Time.now - Time.parse(time)
    re = ''
    re = "now" if diff < 60
    re = (diff/60).to_i.to_s + " min ago" if diff < 3600
    diff = Integer(diff/3600) # now hours
    re = diff.to_s + (diff == 1 ? " hour ago" : " hours ago") if diff < 24
    diff = Integer(diff/24) # now days
    re = diff.to_s + (diff == 1 ? " day ago" : " days ago") if diff < 14
    diff_w = Integer(diff/7) # now weeks
    re = diff_w.to_s + (diff_w == 1 ? " week ago" : " weeks&nbsp;ago") if diff < 50
    diff_m = Integer(diff/30.5) # roughly months
    re = diff_m.to_s + " months ago" if re.empty?
    re = re.gsub( / /, "&nbsp;" ) if keep;
    return re
  end


  def add_links(html)
    html.gsub!(/((http|ftp|https):\/\/[\S]+[^\s\.,)(\]])/im, '<a href="\1">\1</a>')
    html.gsub!(/bnc#([\d]+)/im, '<a href="http://bugzilla.novell.com/\1">bnc#\1</a>')
    return html
  end

end
