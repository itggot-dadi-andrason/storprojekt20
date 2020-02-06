require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

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
    result = db.execute("SELECT user_id FROM users WHERE email=?", email)
    if result.empty? == false
        redirect('/wrong')
    end
    password_digest = BCrypt::Password.create(password)
    p password_digest
    db.execute("INSERT INTO users(email, password, name, avatar) VALUES (?,?,?,?)", [email, password_digest, name, avatar])
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
    if db.execute("SELECT user_id FROM users WHERE email=?", email).empty?
        redirect('/wrongpw')
    end
    password_digest = db.execute("SELECT password FROM users WHERE email=?", email)
    if BCrypt::Password.new(password_digest[0][0]) == password
        session[:email] = email
        session[:user_id] = db.execute("SELECT user_id FROM users WHERE email=?", email).first["user_id"].to_i
        p session[:user_id]
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
    # unless params[:file] &&
    #        (tempfile = params[:file][:tempfile]) &&
    #        (name = params[:file][:filename])
    #   @error = "No file selected"
    #   return slim(:upload)
    # end
    # puts "Uploading file, original name #{name.inspect}"
    # target = "public/img/#{name}"
    # slimroute = "img/#{name}"
    files = fileupload(params[:file])
    p files
    target = files[:target]
    p target
    tempfile = files[:tempfile]
    p params[:file][:tempfile]
    slimroute = files[:slimroute]
    db.execute("UPDATE users SET avatar=? WHERE user_id=#{session[:user_id]}", slimroute)
    File.open(target, 'wb') {|f| f.write tempfile.read }
    filesize = File.size(target)
    if File.size(target) > 2000000
        File.delete(target)
        redirect('/filebig')
    end
    p filesize
    redirect('/webshop')
end

get('/filebig') do
    slim(:filebig)
end

get('/webshop') do
    allinfo = db.execute("SELECT * FROM users WHERE user_id=?", session[:user_id])[0]
    listings = db.execute("SELECT * FROM listings")
    categories = db.execute("SELECT DISTINCT categories FROM listings")
    slim(:webshop, locals: {allinfo: allinfo, listings: listings, categories:categories})
end

get('/createlisting') do
    categories = db.execute("SELECT DISTINCT categories FROM listings")
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
    db.execute("INSERT INTO listings(title, desc, bild, categories, user_id) VALUES (?,?,?,?,?)", [title, desc, bild, category, session[:user_id]])
    redirect('/webshop')
end