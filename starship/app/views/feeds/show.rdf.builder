xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(@title)
    xml.link url_for :only_path => false, :controller => 'feeds', :action => "index"
    xml.description("openSUSE Hermes RSS Feed for subscription: #{@title}")
    xml.language('en-us')
      for item in @items
        xml.item do
          xml.title(item.subject)
          xml.description("<pre>#{CGI::escapeHTML(item.body)}</pre>")      
          xml.author(item.sender)               
          xml.pubDate(item.created.xmlschema)
          xml.link url_for :only_path => false, :controller => 'messages', :action => "show", :id => item.id
          xml.guid url_for :only_path => false, :controller => 'messages', :action => "show", :id => item.id
        end
      end
  }
}
