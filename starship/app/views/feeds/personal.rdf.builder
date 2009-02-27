xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
xml.rdf(:RDF, "xmlns:rdf"     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "xmlns"         => "http://purl.org/rss/1.0/",
  "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
  "xmlns:taxo"    => "http://purl.org/rss/1.0/modules/taxonomy/",
  "xmlns:dc"      => "http://purl.org/dc/elements/1.1/",
  "xmlns:syn"     => "http://purl.org/rss/1.0/modules/syndication/",
  "xmlns:admin"   => "http://webns.net/mvcb/" ) {
  xml.channel("rdf:about" => "http://hermes.opensuse.org/messages") {
  xml.title "openSUSE Hermes"
  xml.link "http://hermes.opensuse.org/messages"
  xml.description "Personal Hermes RSS Feed"
  xml.dc :language, "en-us"
  xml.dc :rights, "Copyright 2008, 2009 openSUSE Project"
  xml.dc :date, "INSERT DATE HERE" #FIXME: date
  xml.dc :publisher, "hermes@opensuse.org"
  xml.dc :creator, "hermes@opensuse.org"
  xml.dc :subject, "openSUSE Buildservice"
  xml.items {
    @items.each do |item|
    xml.rdf :li, "rdf:resource" => "http://hermes.opensuse.org/messages/#{item.id}"
    end
  }
}
@items.each do |item|
  xml.item("rdf:about" => "http://hermes.opensuse.org/messages/#{item.id}") {
    xml.title item.subject
    xml.link "http://hermes.opensuse.org/messages/#{item.id}"
    xml.description "<pre>"+item.body+"</pre>"
  }
end
  }
