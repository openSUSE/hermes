xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(@title)
    xml.link(CONFIG['feed_url'] + "/feeds")
    xml.description("openSUSE Hermes RSS Feed for subscription: #{@title}")
    xml.language('en-us')
      for item in @items
        xml.item do
          xml.title(item.subject)
          xml.description("<pre>"+item.body+"</pre>")      
          xml.author(item.sender)               
          xml.pubDate(item.created.xmlschema)
          xml.link(CONFIG['feed_url'] + "/messages/#{item.id}")
          xml.guid(CONFIG['feed_url'] + "/messages/#{item.id}")
        end
      end
  }
}
