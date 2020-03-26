require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'byebug'
require 'capybara'
require_relative 'model.rb'

enable :sessions
db = SQLite3::Database.new("database.db")
db.results_as_hash = true

get('/') do
    slim(:index)
end

get('/register') do
    slim(:register)
end

post('/newaccount') do
    email = params[:email]
    password = params[:password]
    confirm = params[:passwordconf]
    name = params[:name]
    avatar = "img/default.png"
    if confirm != password
        session[:route] = "/register"
        session[:error] = "Passwords don't match."
        redirect('/error')
    end
    result = userexist(email)
    if result.empty? == false
        session[:error] = "Account does not exist."
        session[:route] = "/register"
        redirect('/error')
    end
    createuser(email, password, name, avatar)
    redirect('/login')
end

get('/error') do
    slim(:error)
end

get('/wrong') do
    slim(:wrong)
end

get('/login') do
    slim(:login)
end

post('/loginacc') do
    email = params[:email]
    password = params[:password]
    if userexist(email).empty?
        session[:error] = "That account does not exist."
        session[:route] = "/login"
        redirect('/error')
    end
    val = login(email, password)
    if val
        redirect('/webshop')
    else
        session[:error] = "The password/email is wrong."
        session[:route] = "/login"
        redirect('/error')
    end 
end

get('/uploadtest') do
    slim(:upload)
end

post('/upload') do
    files = fileupload(params[:file])
    if files == false
        session[:error] = "You used the wrong file extension. Only .png, .jpg and .gif are allowed."
        session[:route] = "/uploadtest"
        redirect("/error")
    end
    target = files[:target]
    tempfile = files[:tempfile]
    slimroute = files[:slimroute]
    File.open(target, 'wb') {|f| f.write tempfile.read }
    filesize = File.size(target)
    if File.size(target) > 2000000
        File.delete(target)
        session[:error] = "File is too big. Max 2MB."
        session[:route] = "/uploadtest"
        redirect('/error')
    end
    changeavatar(slimroute)
    redirect('/webshop')
end

get('/filebig') do
    slim(:filebig)
end

get('/webshop') do
    info = getinfo()
    slim(:webshop, locals: {allinfo: info[0], listings: info[1], categories: info[2], relationtable: info[3], catarr: info[4]})
end

get('/createlisting') do
    categories = showcat()
    slim(:createlisting, locals: {categories:categories})
end

post('/createdlisting') do
    title = params[:title]
    desc = params[:desc]
    category = params[:categoryselect]
    unless params[:file] &&
           (tempfile = params[:file][:tempfile]) &&
           (name = params[:file][:filename])
      @error = "No file selected"
      return redirect('/createlisting')
    end
    puts "Uploading file, original name #{name.inspect}"
    target = "public/img/#{name}"
    bild = "img/#{name}"
    File.open(target, 'wb') {|f| f.write tempfile.read }
    mes = listcreate(title, desc, bild, category)
    if mes == false
        session[:error] = "Wrong category, choose another."
        session[:route] = "/createlisting"
        redirect("/error")
    end
    redirect('/webshop')
end


