require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'
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
        redirect('/wrongmatch')
    end
    result = userexist(email)
    if result.empty? == false
        redirect('/wrong')
    end
    createuser(email, password, name, avatar)
    redirect('/register')
end

get('/wrongmatch') do
    slim(:wrongmatch)
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
        redirect('/wrongpw')
    end
    val = login(email, password)
    if val
        redirect('/webshop')
    else
        redirect('/wrongpw')
    end 
end

get('/wrongpw') do
    slim(:wrongpw)
end


get('/uploadtest') do
    slim(:upload)
end

def fileupload(filename)
    unless filename &&
        (tempfile = filename[:tempfile]) &&
        (name = filename[:filename])
    @error = "No file selected"
    return slim(:upload)
    end
    p filename
    fileextension = filename["filename"]
    if File.extname("#{fileextension}") == ".png" or File.extname("#{fileextension}") == ".jpg" or File.extname("#{fileextension}") == ".jpeg" or File.extname("#{fileextension}") == ".gif"
        puts "Uploading file, original name #{name.inspect}"
        target = "public/img/#{name}"
        slimroute = "img/#{name}"
        files = {target: target, slimroute: slimroute, tempfile: tempfile}
        return files
    else
        redirect('/wrongext')
    end
end

post('/upload') do
    files = fileupload(params[:file])
    target = files[:target]
    tempfile = files[:tempfile]
    slimroute = files[:slimroute]
    File.open(target, 'wb') {|f| f.write tempfile.read }
    filesize = File.size(target)
    if File.size(target) > 2000000
        File.delete(target)
        redirect('/filebig')
    end
    changeavatar(slimroute)
    redirect('/webshop')
end

get('/filebig') do
    slim(:filebig)
end

get('/webshop') do
    info = getinfo()
    p info
    slim(:webshop, locals: {allinfo: info[0], listings: info[1], categories: info[2]}, reltable: info[3])
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
    listcreate()
    redirect('/webshop')
end