%w{NO_DELAY PER_MINUTE PER_HOUR PER_DAY PER_WEEK PER_MONTH}.each do |d|
  Delay.find_or_create_by_name(name: d, description: "default entry: #{d}" )
end

[{:id => 1, :name => "Mail", :description => "E-mail", :public => true},
 {:id => 2, :name => "RSS", :description => "Web / RSS Newsfeed", :public => true},
 {:id => 3, :name => "HTTP", :description => "HTTP-GET (fixme)", :public => false},
 {:id => 4, :name => "TwitterOBSHermes", :description => "Twitter OBSHermes (Admin only)", :public => false},
 {:id => 5, :name => "TwitterMaintenance", :description => "Twitter for Maintenance Stuff (Admin only)", :public => false},
 {:id => 6, :name => "TwitterMaintSLE", :description => "Twitter for SLE Maintenance (Admin only)", :public => false}].each do |d|
  Delivery.find_or_create_by_name(d)
end
