require('pry')
require("bundler/setup")
require('pg')
require('bcrypt')

DB = PG.connect({:dbname => "ticket_development"})
  Bundler.require(:default)

  Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
  also_reload("lib/*.rb")

  enable :sessions

helpers do

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end

  def username
    return session[:username]
  end

end

get ('/') do
  @categories = Category.all()
  @events= Event.all()
  @venues= Venue.all()
  @artists=Artist.all()
  @offers=Offer.all()
  @users = User.all()
  erb(:index)
end

get "/signup" do
  erb(:signup)
end

post('/signup') do
  password = params.fetch('password')
  username = params.fetch('username')

  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)
  User.create({:username => username, :password => password_hash, :salt => password_salt})

  session[:username] = params[:username]
  if params[:username] == "admin"
    redirect "/"
  else
    redirect "user"
  end
end

get "/login" do
  erb(:signin)
end

post "/login" do
  username= params.fetch('username')
  if (User.find_by username: username) != nil
    user = User.find_by username: username
    if user.password == BCrypt::Engine.hash_secret(params[:password], user.salt)
      session[:username] = params[:username]
      if params[:username] == "admin"
        redirect "/"
      else
        redirect "user"
      end
    end
  end
  erb(:signin)
end

get "/logout" do
  session[:username] = nil
  redirect "/login"
end

get('/events') do
  @categories = Category.all()
  @events= Event.all()
  @venues= Venue.all()
  @artists=Artist.all()
  erb(:events)
end

get('/artists') do
  @artists=Artist.all()
  erb(:artists)
end

get('/venues') do
  @venues=Venue.all()
  erb(:venues)
end

get('/categories') do
  @categories=Category.all()
  erb(:categories)
end

post ('/event') do
  name = params.fetch('name')
  date = params.fetch('date')
  duration = params.fetch('duration')
  imageurl = params.fetch('imageurl')
  category_id = Integer(params.fetch('category_id'))
  category = Category.find(category_id)
  venue_id = Integer(params.fetch('venue_id'))
  venue = Venue.find(venue_id)
  event = Event.create({:name => name, :date => date, :duration => duration, :imageurl => imageurl, :venue => venue, :category => category})
  artist_id = Integer(params.fetch('artist_id'))
  artist = Artist.find(artist_id)
  ArtistsEvent.create(event: event, artist: artist)
  if event.save()
    redirect ('/')
  else
    erb(:errors)
  end
end

get('/event/:id') do
  @event=Event.find(Integer(params.fetch('id')))
  erb(:event)
end

patch("/event/:id") do
  event_id=Integer(params.fetch('id'))
  name = params.fetch("name")
  date = params.fetch("date")
  imageurl = params.fetch("imageurl")
  @event = Event.find(params.fetch("id").to_i())
  @event.update({:name => name, :date => date, :imageurl => imageurl})
  redirect("/event/#{event_id}")
end

delete("/event/:id") do
  event_id=Integer(params.fetch("id"))
  event_to_be_deleted= Event.find(event_id)
  event_to_be_deleted.destroy()
  redirect("/")
end

post ('/artist') do
  name = params.fetch('name')
  artist = Artist.create({:name => name})
  if artist.save()
    redirect ('/')
  else
    erb(:errors)
  end
end

get('/artist/:id') do
  @artist=Artist.find(Integer(params.fetch('id')))
  erb(:artist)
end

patch("/artist/:id") do
  artist_id=Integer(params.fetch('id'))
  name = params.fetch("name")
  @artist = Artist.find(params.fetch("id").to_i())
  @artist.update({:name => name})
  redirect("/artist/#{artist_id}")
end


delete("/artist/:id") do
  artist_id=Integer(params.fetch("id"))
  artist_to_be_deleted= Artist.find(artist_id)
  artist_to_be_deleted.destroy()
  redirect("/")
end

post ('/venue') do
  name = params.fetch('name')
  address = params.fetch('address')
  imageurl = params.fetch('imageurl')
  venue = Venue.create({:name => name, :address => address, :imageurl => imageurl})
  if venue.save()
    redirect ('/')
  else
    erb(:errors)
  end
end

get('/venue/:id') do
  @venue=Venue.find(Integer(params.fetch('id')))
  erb(:venue)
end

patch("/venue/:id") do
  venue_id=Integer(params.fetch('id'))
  name = params.fetch("name")
  address = params.fetch('address')
  imageurl = params.fetch('imageurl')
  @venue = Venue.find(params.fetch("id").to_i())
  @venue.update({:name => name, :address => address, :imageurl => imageurl})
  redirect("/venue/#{venue_id}")
end


delete("/venue/:id") do
  venue_id=Integer(params.fetch("id"))
  venue_to_be_deleted= Venue.find(venue_id)
  venue_to_be_deleted.destroy()
  redirect("/")
end

post ('/category') do
  name = params.fetch('name')
  category = Category.create({:name => name})
  if category.save()
    redirect ('/')
  else
    erb(:errors)
  end
end

get('/category/:id') do
  @category=Category.find(Integer(params.fetch('id')))
  erb(:category)
end

patch("/category/:id") do
  category_id=Integer(params.fetch('id'))
  name = params.fetch("name")
  @category = Category.find(params.fetch("id").to_i())
  @category.update({:name => name})
  redirect("/category/#{category_id}")
end


delete("/category/:id") do
  category_id=Integer(params.fetch("id"))
  category_to_be_deleted= Category.find(category_id)
  category_to_be_deleted.destroy()
  redirect("/")
end

get("/user") do
  @categories = Category.all()
  @events= Event.all()
  @venues= Venue.all()
  @artists=Artist.all()
  @offers=Offer.all()
  erb(:user)
end

get("/search") do
  searchTerm= params.fetch("search")
  @foundEvents = Event.where("name = ?",searchTerm)
  @foundArtists = Artist.where("name = ?",searchTerm)
  @foundOffers = []
  @foundArtists.each do |artist|
    @foundArtistEvents=ArtistsEvent.where("artist_id= ?",artist.id)
    @foundArtistEvents.each do |event|
      @foundOffers=Offer.where("event_id= ?",event.event_id)
    end
  end
  @foundEvents.each do |event|
    @foundOffers = []
    @foundOffers=Offer.where("event_id= ?",event.id)
  end
  @user = ""
  erb(:results)
end

#offers many-many table
get('/offer') do
  @offers = Offer.all()
  erb(:offer)
end

get ('/categorysearch') do
  categoryId = params.fetch('categorysearch')
  chosenCategory = Category.find(categoryId)
  @foundOffers = []
  @foundEvents = Event.where("category_id = ?",categoryId)
  @foundEvents.each do |event|
    @foundOffers=Offer.where("event_id= ?",event.id)
  end
  erb(:results)
end

post("/offer") do

    event_id = params.fetch("event_id").to_i()
    price = params.fetch("price").to_i()
    user=User.find_by username: session[:username]
    bs = params.fetch("offer")

    if bs == "true"
    @offer = Offer.new({:event_id => event_id, :user_id => user.id, :price => price, :buy_sell => true})
    else
    @offer = Offer.new({:event_id => event_id, :user_id => user.id, :price => price, :buy_sell => false})
    end

    @offer.save()
    @offers = Offer.all()
    erb(:offer)
  end

  get('/offer/:id') do
  @offer=Offer.find(Integer(params.fetch('id')))
  erb(:offer_info)
end

delete("/offer/:id") do
    @offer = Offer.find(params.fetch("id").to_i())
    @offer.delete()
    redirect ('/offer')
end
