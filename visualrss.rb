require './index.rb'
require 'sinatra'
require 'sass'
require 'pp'
require 'open-uri'
require 'nokogiri'
require 'ruby-bitly'
require 'haml'
require './noko.rb'
require 'sinatra/flash'

settings.port = ENV['PORT'] || 4567
use Rack::Session::Pool, :expire_after => 2592000
set :session_secret, 'super secret'

configure :development do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

configure :production do
  DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_PINK_URL'])
end

DataMapper.auto_upgrade!


get '/' do
  haml :index
end


get '/sign_up' do
  haml :registro
end


get '/perfil' do
  haml :perfil
end


get '/new_rss' do
  haml :new_rss
end

get '/contacto' do
  haml :contacto
end


get '/remove_rss' do
  haml :remove_rss
end


get '/privacidad' do
  haml :privacidad
end

post '/new_rss' do
  rss2 = "#{params[:user][:rss]}" 
  rss2 = Bitly.shorten(rss2, "o_1qfb1am5b6", "R_770c5cbd981cadac42359a65fed206df").url
  rss2 = rss2.gsub(/http:\/\//,"")
  rss2 = " " << rss2
  rss_title2 = " #{params[:user][:rss_titulo]}"
  un_usuario = User.first(:username => session["user"])
  un_usuario.rss << rss2
  if (User.first(:username => "#{session[:user]}").titulo_rss).length == 0
    un_usuario.titulo_rss << rss_title2
  else
    un_usuario.titulo_rss << "####{rss_title2}"
  end
  User.first(:username => session["user"]).update(:rss => un_usuario.rss)
  User.first(:username => session["user"]).update(:titulo_rss => un_usuario.titulo_rss)
  redirect to ('/')
end


get '/cambiar/:rss_used' do
  if session[:user]
    @tituloss = User.first(:username => "#{session[:user]}").titulo_rss
    @rsss = User.first(:username => "#{session[:user]}").rss
    @tituloss = @tituloss.split("### ")
    @rsss = @rsss.split(" ")
    a = request.path_info
    a = a.gsub(/\/cambiar\//,"")
    User.first(:username => session["user"]).update(:rss_used => @rsss[a.to_i])
    User.first(:username => session["user"]).update(:titulo_used => @tituloss[a.to_i])
    redirect to ('/')
  else
    redirect to ('/')
  end
end


get '/delete/:rss_used' do
  if session[:user]
    
    @tituloss = User.first(:username => "#{session[:user]}").titulo_rss
    @rsss = User.first(:username => "#{session[:user]}").rss
    @tituloss = @tituloss.split("### ")
    @rsss = @rsss.split(" ")
    a = request.path_info
    a = a.gsub(/\/delete\//,"")
    a = a.to_i
    p a
    
    @tituloss.delete_at(a)
    @rsss.delete_at(a) 
    
    @res_a = String.new()
    @res_b = String.new()
    @res_a << @tituloss[0].to_s
    @res_b << @rsss[0].to_s
    
    for i in 1..@tituloss.length-1 do
      @res_a << "### " << @tituloss[i].to_s 
      @res_b << " " << @rsss[i].to_s 
    end
    
    User.first(:username => session["user"]).update(:rss_used => "")
    User.first(:username => session["user"]).update(:titulo_used => "")
    User.first(:username => session["user"]).update(:titulo_rss => @res_a)
    User.first(:username => session["user"]).update(:rss => @res_b)
    redirect to ('/')
  else
    redirect to ('/')
  end
end


get '/numero/:num' do
  if session[:user]
    a = request.path_info
    a = a.gsub(/\/numero\//,"")
    User.first(:username => session["user"]).update(:num => a.to_i)
    redirect to ('/')
  else
    redirect to ('/')
  end
end


get '/index' do
  haml :index
end


get '/user/:id' do |id|
  @user = User.get(id)
end


get '/user/:id/perfil' do
  @user = User.get(params[:id])
end


post '/' do
  if (params[:user][:username].empty?) || (params[:user][:password].empty?)
    flash[:error] = "Error: The user or the password field is empty"
    redirect to ("/")
  elsif User.first(:username => "#{params[:user][:username]}", :password => "#{params[:user][:password]}")
    flash[:login] = "Login successfully"
    session["user"] = "#{params[:user][:username]}"
    redirect to ('/')
  else
    flash[:error] = "The user doesn't exist or the password is invalid"
    redirect to ('/')
  end
end


post '/sign_up' do
  if (params[:user][:username].empty?) || (params[:user][:password].empty?)
    redirect to ('/sign_up')
  elsif User.first(:username => "#{params[:user][:username]}")
    redirect to ('/sign_up')
  else
    short_rss = params[:user][:rss]
    short_rss = Bitly.shorten(short_rss, "o_1qfb1am5b6", "R_770c5cbd981cadac42359a65fed206df").url
    short_rss = short_rss.gsub(/http:\/\//,"")
    params[:user][:rss] = short_rss
    user = User.create(params[:user])
    session["user"] = "#{params[:user][:username]}"
    redirect to("/")
  end
end


get '/logout' do
  user = User.get(params[:id])
  session["user"] = nil
  session.clear
  redirect to ("/")
end


put 'user/:id' do
  user = User.get(params[:id])
  user.update(params[:user])
  redirect to("/user/#{user.id}")
end


use Rack::Static, :urls => ["/public"]
